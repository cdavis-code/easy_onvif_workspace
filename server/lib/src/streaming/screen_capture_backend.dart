import 'package:flutter/services.dart';

import '../config.dart';
import 'audio_source.dart';
import 'file_h264_source.dart';
import 'h264_source.dart';
import 'rtsp_server.dart';
import 'screen_h264_source.dart';
import 'stream_backend.dart';

/// A [StreamBackend] that serves a macOS display as the live RTSP stream via
/// ScreenCaptureKit + VideoToolbox (no ffmpeg).
class ScreenCaptureStreamBackend implements StreamBackend {
  final ServerConfig config;
  final int frameRate;

  /// Raw CGDirectDisplayID from settings; empty selects the main display.
  final String displayId;

  @override
  final AudioStreamSource? audioSource;

  ScreenH264Source? _source;
  RtspServer? _rtspServer;

  /// The shared encoder's snapshot channel (same one the camera backend uses).
  static const MethodChannel _encoderControl = MethodChannel(
    'easy_onvif_server/h264_encoder',
  );

  ScreenCaptureStreamBackend({
    required this.config,
    this.frameRate = 15,
    this.displayId = '',
    this.audioSource,
  });

  @override
  NalStreamSource? get nalSource => _source;

  @override
  Future<FileH264Source?> Function(String, DateTime?)? replaySourceFor;

  @override
  bool get isRunning => _rtspServer?.isRunning ?? false;

  @override
  Future<String> start(String profileToken, {required String host}) async {
    _source ??= ScreenH264Source(displayId: displayId, frameRate: frameRate);

    await _source!.start();

    // Audio is best-effort: a missing device or denied permission must not
    // take down the video stream.
    try {
      await audioSource?.start();
    } catch (_) {
      // The RTSP server still serves video; the audio track stays silent.
    }

    _rtspServer ??= RtspServer(
      source: _source!,
      port: config.rtspPort,
      replaySourceFor: replaySourceFor,
      audioSource: audioSource,
      username: config.username,
      password: config.password,
    );

    await _rtspServer!.start();

    return config.rtspUrl(host, profileToken);
  }

  @override
  Future<Uint8List?> snapshot() async {
    // The shared encoder keeps the latest frame; ask it for a JPEG still.
    try {
      final result = await _encoderControl.invokeMethod<Object?>('snapshot');

      if (result is Uint8List && result.isNotEmpty) return result;
    } catch (_) {
      // Snapshots are best-effort.
    }

    return null;
  }

  @override
  Future<void> stop() async {
    await _rtspServer?.stop();
    _rtspServer = null;

    await audioSource?.stop();

    await _source?.stop();
    _source = null;
  }
}
