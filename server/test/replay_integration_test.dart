import 'dart:io';

import 'package:easy_onvif/media1.dart' show StreamSetup, Transport;
import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/recordings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_backend.dart';

RecordingConfiguration buildTestRecordingConfiguration() =>
    RecordingConfiguration(
      source: RecordingSourceInformation(
        sourceId: 'VideoSource_1',
        name: 'VideoSource_1',
        location: 'Location',
        description: 'Live capture',
        address: 'http://localhost/onvif/Media',
      ),
      content: 'Test',
      maximumRetentionTime: 'PT0S',
    );

RecordingJobConfiguration buildTestJobConfiguration(String recordingToken) =>
    RecordingJobConfiguration(
      recordingToken: recordingToken,
      mode: RecordingJobConfigurationMode.active,
      priority: 1,
    );

/// End-to-end test of the Replay service: recorded footage is served back
/// over RTSP as decodable H.264.
void main() {
  const httpPort = 8098;
  const rtspPort = 8564;
  const config = ServerConfig(httpPort: httpPort, rtspPort: rtspPort);

  late Directory recordingsDir;
  late OnvifDevice device;
  late Onvif onvif;

  setUpAll(() async {
    recordingsDir = await Directory.systemTemp.createTemp('onvif_replay_test');

    device = OnvifDevice(
      config: config,
      hardware: StubHardwareAdapter(),
      streamBackend: FfmpegBackend(
        config: config,
        frameRate: 15,
        inputArgs: ['-f', 'lavfi', '-i', 'testsrc=size=640x480:rate=15'],
      ),
      settings: ServerSettings.parse('''
recording:
  directory: ${recordingsDir.path}
  segmentSeconds: 2
''', base: config),
    );

    await device.start();

    onvif = await Onvif.connect(
      host: 'localhost:$httpPort',
      username: 'admin',
      password: 'admin',
    );
  });

  tearDownAll(() async {
    await device.stop();

    if (recordingsDir.existsSync()) recordingsDir.deleteSync(recursive: true);
  });

  test('replay serves recorded footage as decodable H.264', () async {
    // Record ~5 seconds of the live test pattern.
    final recordingToken = await onvif.recordings.createRecording(
      buildTestRecordingConfiguration(),
    );
    final job = await onvif.recordings.createRecordingJob(
      buildTestJobConfiguration(recordingToken),
    );

    await Future<void>.delayed(const Duration(seconds: 5));

    await onvif.recordings.setRecordingJobMode(
      jobToken: job.token,
      mode: RecordingJobConfigurationMode.idle,
    );

    final replayUri = await onvif.replay.getReplayUri(
      recordingToken,
      streamSetup: StreamSetup(
        stream: 'RTP-Unicast',
        transport: Transport(protocol: 'RTSP'),
      ),
    );

    expect(replayUri, startsWith('rtsp://'));
    expect(replayUri, contains('/onvif/replay/$recordingToken'));

    // Re-encode 2s from the replay endpoint — proves it serves real video.
    final capture = '${recordingsDir.path}/replay_capture.mp4';
    final record = await Process.run('ffmpeg', [
      '-hide_banner', '-loglevel', 'error', '-y',
      '-rtsp_transport', 'tcp', '-i', replayUri,
      '-t', '2', '-c:v', 'libx264', '-preset', 'ultrafast', '-f', 'mp4',
      capture,
    ]);

    expect(record.exitCode, 0, reason: 'ffmpeg: ${record.stderr}');

    final probe = await Process.run('ffprobe', [
      '-hide_banner', '-loglevel', 'error', '-i', capture,
      '-show_entries', 'stream=codec_name,width,height', '-of', 'csv=p=0',
    ]);

    expect(probe.exitCode, 0, reason: 'ffprobe: ${probe.stderr}');
    expect(probe.stdout.toString(), contains('h264'));
    expect(probe.stdout.toString(), contains('640'));

    // Replay configuration round-trip.
    final replayConfig = await onvif.replay.getReplayConfiguration();

    expect(replayConfig.sessionTimeout, 'PT60S');
  }, timeout: const Timeout(Duration(seconds: 120)));
}
