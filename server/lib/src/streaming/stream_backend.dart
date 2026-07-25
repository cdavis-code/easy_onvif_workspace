import 'dart:typed_data';

import 'audio_source.dart';
import 'file_h264_source.dart';
import 'h264_source.dart';

/// Abstraction over the component that produces the RTSP video stream.
///
/// `GetStreamUri` returns the URL produced by [start]. The first working
/// implementation is `FfmpegBackend` (M3); tests and the initial milestones
/// use [StubStreamBackend], which advertises a URL without serving media.
abstract interface class StreamBackend {
  /// Starts serving the stream for [profileToken] and returns the RTSP URL a
  /// client should connect to. [host] is the advertised device address.
  Future<String> start(String profileToken, {required String host});

  /// Stops the stream and releases resources.
  Future<void> stop();

  /// Whether the stream is currently running.
  bool get isRunning;

  /// Grabs a single JPEG frame from the running stream, or `null` if no frame
  /// is available. Used for the HTTP snapshot endpoint and the in-app preview.
  Future<Uint8List?> snapshot();

  /// The live H.264 NAL source feeding the RTSP server, or `null` when the
  /// backend is not running or does not expose one. Used by the recording
  /// engine to tap the stream without opening the camera twice.
  NalStreamSource? get nalSource;

  /// The live G.711 audio source served as the RTSP audio track, or `null`
  /// when audio streaming is disabled.
  AudioStreamSource? get audioSource;

  /// Resolver for RTSP replay sessions (`/onvif/replay/<token>` URLs),
  /// injected by the device when the recording service is enabled. Backends
  /// that serve RTSP pass it through to their [RtspServer].
  abstract Future<FileH264Source?> Function(
    String recordingToken,
    DateTime? startUtc,
  )?
  replaySourceFor;
}

/// A [StreamBackend] that advertises an RTSP URL derived from [urlFor] without
/// actually serving media. Used until a real backend (ffmpeg) is wired in.
class StubStreamBackend implements StreamBackend {
  final String Function(String host, String profileToken) urlFor;

  bool _running = false;

  StubStreamBackend({required this.urlFor});

  @override
  bool get isRunning => _running;

  @override
  Future<String> start(String profileToken, {required String host}) async {
    _running = true;

    return urlFor(host, profileToken);
  }

  @override
  Future<void> stop() async {
    _running = false;
  }

  @override
  Future<Uint8List?> snapshot() async => null;

  @override
  NalStreamSource? get nalSource => null;

  @override
  final AudioStreamSource? audioSource = null;

  @override
  Future<FileH264Source?> Function(String, DateTime?)? replaySourceFor;
}
