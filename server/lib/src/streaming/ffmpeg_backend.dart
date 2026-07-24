import 'dart:io';
import 'dart:typed_data';

import '../config.dart';
import 'h264_source.dart';
import 'rtsp_server.dart';
import 'stream_backend.dart';

/// A [StreamBackend] that produces a live RTSP stream by encoding video with
/// `ffmpeg` (H.264) and serving it through an embedded [RtspServer].
///
/// By default the source is a generated test pattern. Pass [inputArgs] to
/// stream from a real device, e.g. a macOS webcam:
///
/// ```dart
/// FfmpegBackend(
///   config: config,
///   inputArgs: ['-f', 'avfoundation', '-i', '0', '-r', '15'],
/// )
/// ```
class FfmpegBackend implements StreamBackend {
  final ServerConfig config;
  final String ffmpegPath;
  final List<String>? inputArgs;
  final int frameRate;

  H264Source? _source;
  RtspServer? _rtspServer;
  String? _profileToken;

  FfmpegBackend({
    required this.config,
    this.ffmpegPath = 'ffmpeg',
    this.inputArgs,
    this.frameRate = 15,
  });

  @override
  bool get isRunning => _rtspServer?.isRunning ?? false;

  @override
  Future<String> start(String profileToken, {required String host}) async {
    _profileToken = profileToken;

    _source ??= H264Source(
      ffmpegPath: ffmpegPath,
      frameRate: frameRate,
      inputArgs: inputArgs,
    );

    await _source!.start();

    _rtspServer ??= RtspServer(source: _source!, port: config.rtspPort);

    await _rtspServer!.start();

    return config.rtspUrl(host, profileToken);
  }

  /// Grabs a single JPEG frame by reading the running RTSP stream as a client.
  ///
  /// Reading from the stream (rather than opening the camera device again)
  /// avoids contending with the ffmpeg process that already owns the camera.
  @override
  Future<Uint8List?> snapshot() async {
    final profileToken = _profileToken;

    if (profileToken == null || _rtspServer == null) return null;

    final url = 'rtsp://127.0.0.1:${config.rtspPort}/onvif/$profileToken';

    try {
      final result = await Process.run(
        ffmpegPath,
        [
          '-hide_banner',
          '-loglevel',
          'error',
          '-rtsp_transport',
          'tcp',
          '-i',
          url,
          '-frames:v',
          '1',
          '-c:v',
          'mjpeg',
          '-q:v',
          '3',
          '-f',
          'image2',
          'pipe:1',
        ],
        // Raw bytes (not a decoded String) so the JPEG survives intact.
        stdoutEncoding: null,
      );

      if (result.exitCode == 0 && result.stdout is List<int>) {
        final bytes = result.stdout as List<int>;

        if (bytes.isNotEmpty) return Uint8List.fromList(bytes);
      }
    } catch (_) {
      // Snapshots are best-effort; fall through to null.
    }

    return null;
  }

  @override
  Future<void> stop() async {
    await _rtspServer?.stop();
    _rtspServer = null;

    await _source?.stop();
    _source = null;
  }
}
