import 'dart:io';

import 'package:easy_onvif/onvif.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_backend.dart';

/// End-to-end verification of Milestone 3: the server produces a live RTSP
/// H.264 stream. The `easy_onvif` client retrieves the stream URI, then
/// `ffmpeg`/`ffprobe` confirm the RTSP endpoint actually serves decodable
/// video.
void main() {
  const httpPort = 8093;
  const rtspPort = 8560;

  late OnvifDevice device;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('onvif_rtsp_test');

    device = OnvifDevice(
      config: const ServerConfig(httpPort: httpPort, rtspPort: rtspPort),
      hardware: StubHardwareAdapter(),
      streamBackend: FfmpegBackend(
        config: const ServerConfig(httpPort: httpPort, rtspPort: rtspPort),
        frameRate: 15,
        inputArgs: ['-f', 'lavfi', '-i', 'testsrc=size=640x480:rate=15'],
      ),
    );

    await device.start();
  });

  tearDown(() async {
    await device.stop();

    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test(
    'client gets a stream URI and the RTSP endpoint serves H.264',
    () async {
      final onvif = await Onvif.connect(
        host: 'localhost:$httpPort',
        username: 'admin',
        password: 'admin',
      );

      final profiles = await onvif.media.getProfiles();
      final streamUri = await onvif.media.getStreamUri(profiles.first.token);

      expect(streamUri, startsWith('rtsp://'));
      expect(streamUri, contains(':$rtspPort/'));

      // Re-encode a short clip from the live RTSP endpoint. Re-encoding (rather
      // than `-c copy`) is robust to joining the stream mid-GOP and proves the
      // RTP/H.264 payload actually decodes to real video.
      final capture = '${tempDir.path}/capture.mp4';

      final record = await Process.run('ffmpeg', [
        '-hide_banner',
        '-loglevel',
        'error',
        '-y',
        '-rtsp_transport',
        'tcp',
        '-i',
        streamUri,
        '-t',
        '2',
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-f',
        'mp4',
        capture,
      ]);

      expect(
        record.exitCode,
        0,
        reason: 'ffmpeg failed to record from $streamUri: ${record.stderr}',
      );

      final captured = File(capture);

      expect(captured.existsSync(), isTrue);
      expect(captured.lengthSync(), greaterThan(0));

      // Probe the recording to confirm it is H.264 video at the expected size.
      final probe = await Process.run('ffprobe', [
        '-hide_banner',
        '-loglevel',
        'error',
        '-i',
        capture,
        '-show_entries',
        'stream=codec_name,codec_type,width,height',
        '-of',
        'csv=p=0',
      ]);

      expect(probe.exitCode, 0, reason: 'ffprobe failed: ${probe.stderr}');

      final output = probe.stdout.toString();

      expect(output, contains('h264'));
      expect(output, contains('video'));
      expect(output, contains('640'));
      expect(output, contains('480'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'snapshot grabs a JPEG frame from the live stream',
    () async {
      // Give the stream a moment to produce its first keyframe.
      await Future<void>.delayed(const Duration(seconds: 2));

      final frame = await device.streamBackend.snapshot();

      expect(frame, isNotNull);
      expect(frame!.length, greaterThan(0));
      // JPEG magic bytes: FF D8.
      expect(frame[0], 0xff);
      expect(frame[1], 0xd8);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'snapshot endpoint requires HTTP Basic authentication',
    () async {
      // Give the stream a moment to produce its first keyframe.
      await Future<void>.delayed(const Duration(seconds: 2));

      final client = HttpClient();

      // No credentials → 401 with a Basic challenge.
      final unauthenticated = await client.getUrl(
        Uri.parse('http://localhost:$httpPort/onvif/snapshot/Profile_1'),
      );
      final unauthenticatedResponse = await unauthenticated.close();
      expect(unauthenticatedResponse.statusCode, HttpStatus.unauthorized);

      // Credentials embedded in the URL → 200 with a JPEG (the Dart HTTP
      // client sends URL userinfo as a Basic Authorization header).
      final authenticated = await client.getUrl(
        Uri.parse(
          'http://admin:admin@localhost:$httpPort/onvif/snapshot/Profile_1',
        ),
      );
      final authenticatedResponse = await authenticated.close();
      expect(authenticatedResponse.statusCode, HttpStatus.ok);

      client.close(force: true);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
