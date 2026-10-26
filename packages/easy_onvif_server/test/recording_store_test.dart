import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/recording/recording_index.dart';
import 'package:easy_onvif_server/src/recording/recording_store.dart';
import 'package:easy_onvif_server/src/recording/segment_recorder.dart';
import 'package:easy_onvif_server/src/streaming/audio_source.dart';
import 'package:easy_onvif_server/src/streaming/h264_source.dart';

/// A [NalStreamSource] that emits synthetic access units on demand.
class FakeNalSource implements NalStreamSource {
  final _controller = StreamController<H264NalUnit>.broadcast();

  @override
  Stream<H264NalUnit> get nals => _controller.stream;

  @override
  Uint8List? get sps => Uint8List.fromList([0x67, 0x42, 0xC0, 0x1E]);

  @override
  Uint8List? get pps => Uint8List.fromList([0x68, 0xCE, 0x38, 0x80]);

  @override
  Future<void> get parametersReady => Future.value();

  /// Emits [frames] access units at [interval]; every third frame is an IDR
  /// (type 5), the rest are non-IDR slices (type 1).
  Future<void> emitFrames(int frames, Duration interval) async {
    for (var i = 0; i < frames; i++) {
      final isIdr = i % 3 == 0;
      final header = isIdr ? 0x65 : 0x41;
      final nal = Uint8List.fromList([header, 0x88, ...List.filled(64, i)]);

      _controller.add(H264NalUnit(nal, i * 6000, true));

      await Future<void>.delayed(interval);
    }
  }

  Future<void> close() => _controller.close();
}

/// An [AudioStreamSource] that emits one silent A-law frame every 20 ms.
class FakeAudioSource implements AudioStreamSource {
  final _controller = StreamController<AudioFrame>.broadcast();
  Timer? _timer;
  int _timestamp = 0;

  @override
  Stream<AudioFrame> get frames => _controller.stream;

  @override
  Future<void> start() async {
    _timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      _controller.add(
        AudioFrame(Uint8List.fromList(List.filled(160, 0xD5)), _timestamp),
      );
      _timestamp += 160;
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    await _controller.close();
  }
}

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

  group('segment recorder', () {
    test('writes keyframe-aligned segments and updates the index', () async {
      final store = RecordingStore(root: tempDir);
      await store.open();

      final index = await store.create(
        recordingToken: 'R1',
        frameRate: 15,
        sourceToken: 'VideoSource_1',
        profileToken: 'Profile_1',
      );

      final source = FakeNalSource();
      final recorder = SegmentRecorder(
        index: index,
        source: source,
        store: store,
        segmentSeconds: 1,
      );

      await recorder.start();
      // ~30 frames over ~3s => at least 2 rotated segments (1s each).
      await source.emitFrames(30, const Duration(milliseconds: 100));
      await recorder.stop();
      await source.close();

      expect(index.segments.length, greaterThanOrEqualTo(2));

      for (final segment in index.segments) {
        final bytes = index.segmentFile(segment).readAsBytesSync();

        // Starts with an Annex-B start code followed by SPS (0x67).
        expect(bytes.sublist(0, 5), [0, 0, 0, 1, 0x67]);
        expect(segment.frameCount, greaterThan(0));
      }

      // The reloaded index sees the same segments (save() ran on stop).
      final reloaded = await RecordingIndex.load(index.directory);

      expect(reloaded!.segments.length, index.segments.length);
    });

    test('writes an .alaw sidecar per segment when audio is present', () async {
      final store = RecordingStore(root: tempDir);
      await store.open();

      final index = await store.create(
        recordingToken: 'RA1',
        frameRate: 15,
        sourceToken: 'VideoSource_1',
        profileToken: 'Profile_1',
      );

      final video = FakeNalSource();
      final audio = FakeAudioSource();
      final recorder = SegmentRecorder(
        index: index,
        source: video,
        store: store,
        segmentSeconds: 1,
        audioSource: audio,
      );

      await recorder.start();
      await audio.start();
      await video.emitFrames(30, const Duration(milliseconds: 100));
      await recorder.stop();
      await audio.stop();
      await video.close();

      expect(index.segments.length, greaterThanOrEqualTo(2));

      for (final segment in index.segments) {
        expect(segment.audioFile, isNotNull);

        final sidecar = index.audioFile(segment)!;
        expect(sidecar.existsSync(), isTrue);
        expect(sidecar.lengthSync(), greaterThan(0));
        expect(sidecar.lengthSync() % 160, 0);
      }

      // The sidecar reference survives an index reload.
      final store2 = RecordingStore(root: tempDir);
      await store2.open();
      expect(
        store2.byToken('RA1')!.segments.first.audioFile,
        index.segments.first.audioFile,
      );
    });
  });
}
