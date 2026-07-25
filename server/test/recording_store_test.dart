import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/recording/recording_index.dart';
import 'package:easy_onvif_server/src/recording/recording_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('onvif_store_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('create, persist and reload a recording index', () async {
    final store = RecordingStore(root: tempDir);
    await store.open();

    expect(store.recordings, isEmpty);

    final index = await store.create(
      recordingToken: 'OnvifRecordingToken_1',
      frameRate: 15,
      sourceToken: 'VideoSource_1',
      profileToken: 'Profile_1',
    );

    index.segments.add(
      RecordingSegment(
        file: 'seg_00001.h264',
        startUtc: DateTime.utc(2026, 7, 23, 12, 0, 0),
        endUtc: DateTime.utc(2026, 7, 23, 12, 0, 10),
        frameCount: 150,
      ),
    );
    await index.save();

    // Fresh store re-reads from disk.
    final store2 = RecordingStore(root: tempDir);
    await store2.open();

    expect(store2.recordings, hasLength(1));

    final loaded = store2.byToken('OnvifRecordingToken_1')!;

    expect(loaded.frameRate, 15);
    expect(loaded.segments.single.frameCount, 150);
    expect(loaded.earliestUtc, DateTime.utc(2026, 7, 23, 12, 0, 0));
    expect(loaded.latestUtc, DateTime.utc(2026, 7, 23, 12, 0, 10));
  });

  test('delete removes the directory', () async {
    final store = RecordingStore(root: tempDir);
    await store.open();

    await store.create(
      recordingToken: 'R1',
      frameRate: 15,
      sourceToken: 'VideoSource_1',
      profileToken: 'Profile_1',
    );

    await store.delete('R1');

    expect(store.recordings, isEmpty);
    expect(Directory('${tempDir.path}/R1').existsSync(), isFalse);
  });
}
