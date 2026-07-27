import 'dart:io';

import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/recordings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_backend.dart';

/// Builds a minimal recording configuration the way a real client would.
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

/// End-to-end test of the Recording service: a recording job captures the
/// live ffmpeg test-pattern stream into real `.h264` segments on disk.
void main() {
  const httpPort = 8097;
  const rtspPort = 8563;
  const config = ServerConfig(httpPort: httpPort, rtspPort: rtspPort);

  late Directory recordingsDir;
  late OnvifDevice device;
  late Onvif onvif;

  setUpAll(() async {
    recordingsDir = await Directory.systemTemp.createTemp('onvif_rec_test');

    device = OnvifDevice(
      config: config,
      hardware: StubHardwareAdapter(),
      streamBackend: FfmpegBackend(
        config: config,
        frameRate: 15,
        inputArgs: ['-f', 'lavfi', '-i', 'testsrc=size=640x480:rate=15'],
      ),
      settings: ServerSettings(
        config: config,
        recordingDirectory: recordingsDir.path,
        segmentSeconds: 2,
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

  test('recording lifecycle produces real segments on disk', () async {
    final capabilities = await onvif.recordings.getServiceCapabilities();

    expect(capabilities.dynamicRecordings, isTrue);

    final recordings = await onvif.recordings.getRecordings();

    expect(recordings, isEmpty);

    final recordingToken = await onvif.recordings.createRecording(
      buildTestRecordingConfiguration(),
    );

    expect(recordingToken, isNotEmpty);

    final job = await onvif.recordings.createRecordingJob(
      buildTestJobConfiguration(recordingToken),
    );

    // Let it capture ~5s of live stream (segmentSeconds: 2 → >=2 segments).
    await Future<void>.delayed(const Duration(seconds: 5));

    final state = await onvif.recordings.getRecordingJobState(job.token);

    expect(state.state, 'Active');

    await onvif.recordings.setRecordingJobMode(
      jobToken: job.token,
      mode: RecordingJobConfigurationMode.idle,
    );

    final segDir = Directory('${recordingsDir.path}/$recordingToken');
    final segments = segDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.h264'))
        .toList();

    expect(segments.length, greaterThanOrEqualTo(2));
    expect(segments.first.lengthSync(), greaterThan(1000));

    final listed = await onvif.recordings.getRecordings();

    expect(listed.single.recordingToken, recordingToken);

    await onvif.recordings.deleteRecording(recordingToken);

    expect(segDir.existsSync(), isFalse);
  }, timeout: const Timeout(Duration(seconds: 90)));
}
