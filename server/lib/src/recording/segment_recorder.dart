import 'dart:async';
import 'dart:io';

import '../streaming/h264_source.dart';
import 'recording_index.dart';
import 'recording_store.dart';

/// Records a live [NalStreamSource] into rotating Annex-B segment files.
///
/// Waits for a keyframe before starting each segment (so every segment decodes
/// standalone), prefixes SPS/PPS, and rotates on the first keyframe after
/// [segmentSeconds]. The index is saved on every rotation so a crash loses at
/// most the currently-open segment's tail.
class SegmentRecorder {
  static const _startCode = [0, 0, 0, 1];

  final RecordingIndex index;
  final NalStreamSource source;
  final RecordingStore store;
  final int segmentSeconds;

  StreamSubscription<H264NalUnit>? _subscription;
  IOSink? _sink;
  RecordingSegment? _segment;
  int _segmentNumber = 0;
  DateTime? _segmentStartedAt;

  SegmentRecorder({
    required this.index,
    required this.source,
    required this.store,
    this.segmentSeconds = 10,
  });

  bool get isRecording => _subscription != null;

  Future<void> start() async {
    if (_subscription != null) return;

    _segmentNumber = index.segments.length;

    _subscription = source.nals.listen(_onNal);
  }

  void _onNal(H264NalUnit nal) {
    final now = DateTime.now().toUtc();
    final isKeyframe = nal.type == 5;

    // Not yet in a segment: wait for a keyframe to open the first one.
    if (_sink == null) {
      if (!isKeyframe) return;

      _openSegment(now);
    } else if (isKeyframe &&
        now.difference(_segmentStartedAt!).inSeconds >= segmentSeconds) {
      _rotate(now);
    }

    // Skip parameter sets in the body; they were written at segment open.
    if (nal.isSps || nal.isPps) return;

    _sink!.add(_startCode);
    _sink!.add(nal.data);

    final segment = _segment!;

    segment.endUtc = now;

    if (nal.lastOfFrame) segment.frameCount++;
  }

  void _openSegment(DateTime now) {
    _segmentNumber++;

    final name = 'seg_${_segmentNumber.toString().padLeft(5, '0')}.h264';
    final file = File('${index.directory.path}/$name');

    _sink = file.openWrite();
    _segmentStartedAt = now;
    _segment = RecordingSegment(file: name, startUtc: now, endUtc: now);

    index.segments.add(_segment!);

    // Every segment starts with SPS/PPS so it decodes standalone.
    final sps = source.sps;
    final pps = source.pps;

    if (sps != null) {
      _sink!
        ..add(_startCode)
        ..add(sps);
    }

    if (pps != null) {
      _sink!
        ..add(_startCode)
        ..add(pps);
    }
  }

  void _rotate(DateTime now) {
    final closing = _sink;

    _sink = null;

    closing?.close();

    _openSegment(now);

    // Persist the index and apply retention after each rotation.
    unawaited(index.save().then((_) => store.prune(index)));
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    await _sink?.close();
    _sink = null;
    _segment = null;

    await index.save();
  }
}
