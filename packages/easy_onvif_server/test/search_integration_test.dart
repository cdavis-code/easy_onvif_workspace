import 'dart:io';

import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/recordings.dart';
import 'package:easy_onvif/search.dart' show SearchState;
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

/// End-to-end test of the Search service over real on-disk recording indexes.
void main() {
  const httpPort = 8099;
  const rtspPort = 8565;
  const config = ServerConfig(httpPort: httpPort, rtspPort: rtspPort);

  late Directory recordingsDir;
  late OnvifDevice device;
  late Onvif onvif;

  setUpAll(() async {
    recordingsDir = await Directory.systemTemp.createTemp('onvif_search_test');

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

  test(
    'search returns real recording time ranges',
    () async {
      // Produce one real recording (~4s).
      final recordingToken = await onvif.recordings.createRecording(
        buildTestRecordingConfiguration(),
      );
      final job = await onvif.recordings.createRecordingJob(
        buildTestJobConfiguration(recordingToken),
      );

      await Future<void>.delayed(const Duration(seconds: 4));

      await onvif.recordings.setRecordingJobMode(
        jobToken: job.token,
        mode: RecordingJobConfigurationMode.idle,
      );

      final before = DateTime.now().toUtc();

      // FindRecordings → search token; results reference the real recording.
      final searchToken = await onvif.search.findRecordings(keepAliveTime: 60);

      expect(searchToken, isNotEmpty);

      final results = await onvif.search.getRecordingSearchResults(searchToken);

      expect(results, hasLength(1));
      expect(results.single.searchState, SearchState.completed);
      expect(
        results.single.recordingInformation?.single.recordingToken,
        recordingToken,
      );

      final info = await onvif.search.getRecordingInformation(recordingToken);

      expect(info.recordingToken, recordingToken);
      expect(info.earliestRecording, isNotNull);
      expect(info.latestRecording, isNotNull);
      // The recorded range is real: it ends near "now".
      expect(
        before.difference(info.latestRecording!).inSeconds.abs(),
        lessThan(30),
      );

      final summary = await onvif.search.getRecordingSummary();

      expect(summary.numberRecordings, 1);
      expect(summary.dataFrom, isNotNull);
      expect(summary.dataUntil, isNotNull);
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
