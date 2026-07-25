import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import 'audio_source.dart';
import 'camera_h264_source.dart';
import 'file_h264_source.dart';
import 'h264_encoder.dart';
import 'h264_source.dart';
import 'rtsp_server.dart';
import 'stream_backend.dart';

/// A [StreamBackend] that serves the device camera as a live RTSP stream
/// **without ffmpeg**.
///
/// `CameraH264Source` encodes camera frames to H.264 (via a platform encoder)
/// and the embedded [RtspServer] serves them — the same server used by
/// `FfmpegBackend`. Use this on mobile (iOS/Android) where spawning an
/// `ffmpeg` process is not possible; use `FfmpegBackend` on desktop.
///
/// ```dart
/// OnvifDevice(
///   config: config,
///   hardware: FlutterAdapter(),
///   streamBackend: CameraStreamBackend(config: config),
///   enableDiscovery: true,
/// )
/// ```
class CameraStreamBackend implements StreamBackend {
  final ServerConfig config;
  final H264Encoder? encoder;
  final int frameRate;

  @override
  final AudioStreamSource? audioSource;

  CameraH264Source? _source;
  RtspServer? _rtspServer;

  @override
  NalStreamSource? get nalSource => _source;

  @override
  Future<FileH264Source?> Function(String, DateTime?)? replaySourceFor;

  /// Channel to the native encoder, used to grab a JPEG still of the latest
  /// camera frame for the snapshot endpoint.
  static const MethodChannel _encoderControl = MethodChannel(
    'easy_onvif_server/h264_encoder',
  );

  CameraStreamBackend({
    required this.config,
    this.encoder,
    this.frameRate = 15,
    this.audioSource,
  });

  @override
  bool get isRunning => _rtspServer?.isRunning ?? false;

  /// The camera controller driving the stream, exposed so the UI can show a
  /// live preview from the same camera the encoder consumes (the OS allows a
  /// single consumer per device, so the preview reuses this controller).
  CameraController? get controller => _source?.controller;

  @override
  Future<String> start(String profileToken, {required String host}) async {
    _source ??= CameraH264Source(encoder: encoder, frameRate: frameRate);

    await _source!.start();

    await audioSource?.start();

    _rtspServer ??= RtspServer(
      source: _source!,
      port: config.rtspPort,
      replaySourceFor: replaySourceFor,
      audioSource: audioSource,
    );

    await _rtspServer!.start();

    return config.rtspUrl(host, profileToken);
  }

  @override
  Future<Uint8List?> snapshot() async {
    // Ask the native encoder for a JPEG of the most recent camera frame.
    try {
      final result = await _encoderControl.invokeMethod<Object?>('snapshot');

      if (result is Uint8List && result.isNotEmpty) return result;
    } on MissingPluginException {
      // No native encoder registered (e.g. unsupported platform).
    } catch (_) {
      // Snapshots are best-effort.
    }

    return null;
  }

  @override
  Future<void> stop() async {
    await _rtspServer?.stop();
    _rtspServer = null;

    await _source?.stop();
    _source = null;

    await audioSource?.stop();
  }
}
