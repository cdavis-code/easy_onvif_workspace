import 'dart:io';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_backend.dart';

/// Standalone helper: starts the ffmpeg-backed RTSP server and keeps it running
/// so the stream can be inspected manually, e.g.:
///
///   dart run tool/rtsp_serve.dart
///   ffprobe -rtsp_transport tcp -show_packets -i rtsp://127.0.0.1:8560/onvif/Profile_1
Future<void> main() async {
  const config = ServerConfig(httpPort: 8093, rtspPort: 8560);

  final backend = FfmpegBackend(
    config: config,
    frameRate: 15,
    inputArgs: ['-f', 'lavfi', '-i', 'testsrc=size=640x480:rate=15'],
  );

  final url = await backend.start('Profile_1', host: '127.0.0.1');

  stdout.writeln('STREAMING at $url (ctrl-c to stop)');

  await Future<void>.delayed(const Duration(seconds: 60));

  await backend.stop();
}
