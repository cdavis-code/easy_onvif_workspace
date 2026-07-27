import 'dart:io';

import 'package:easy_onvif/media1.dart' show StreamSetup, Transport;
import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/recordings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_audio_source.dart';
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

/// End-to-end: record live video+audio, then verify the replay RTSP stream
/// carries both h264 and pcm_alaw.
void main() {
  const httpPort = 8105;
  const rtspPort = 8567;
  const config = ServerConfig(httpPort: httpPort, rtspPort: rtspPort);

  late Directory recordingsDir;
  late OnvifDevice device;
  late Onvif onvif;

  setUpAll(() async {
    recordingsDir = await Directory.systemTemp.createTemp('onvif_replay_audio');

    device = OnvifDevice(
      config: config,
      hardware: StubHardwareAdapter(),
      streamBackend: FfmpegBackend(
        config: config,
        frameRate: 15,
        inputArgs: ['-f', 'lavfi', '-i', 'testsrc=size=640x480:rate=15'],
        audioSource: FfmpegAudioSource(),
      ),
      settings: ServerSettings(
        config: config,
        recordingDirectory: recordingsDir.path,
        segmentSeconds: 2,
        media: const MediaSettings(audioEnabled: true),
      ),
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

  test('replay serves recorded audio alongside video', () async {
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

    // Sidecars exist on disk with a plausible byte rate (~8000 B/s).
    final index = device.recordingStore!.byToken(recordingToken)!;

    expect(index.segments, isNotEmpty);

    for (final segment in index.segments) {
      final sidecar = index.audioFile(segment)!;
      final seconds =
          segment.endUtc.difference(segment.startUtc).inMilliseconds / 1000.0;

      expect(sidecar.existsSync(), isTrue);

      if (seconds > 0.5) {
        expect(
          sidecar.lengthSync(),
          greaterThan((seconds * 8000 * 0.3).round()),
        );
        expect(sidecar.lengthSync(), lessThan((seconds * 8000 * 2.0).round()));
      }
    }

    final replayUri = await onvif.replay.getReplayUri(
      recordingToken,
      streamSetup: StreamSetup(
        stream: 'RTP-Unicast',
        transport: Transport(protocol: 'RTSP'),
      ),
    );

    final probe = await Process.run('ffprobe', [
      '-v',
      'error',
      '-rtsp_transport',
      'tcp',
      '-show_entries',
      'stream=codec_name',
      '-of',
      'csv=p=0',
      replayUri,
    ]);

    expect(probe.stdout.toString(), contains('h264'));
    expect(probe.stdout.toString(), contains('pcm_alaw'));
  }, timeout: const Timeout(Duration(seconds: 120)));
}
