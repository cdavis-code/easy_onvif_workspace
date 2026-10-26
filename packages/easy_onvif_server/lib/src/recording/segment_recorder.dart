import 'dart:async';
import 'dart:io';

import '../streaming/audio_source.dart';
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

  /// When set, each segment gets a byte-addressable `.alaw` sidecar carrying
  /// the G.711 frames captured while the segment was open.
  final AudioStreamSource? audioSource;

  StreamSubscription<H264NalUnit>? _subscription;
  StreamSubscription<AudioFrame>? _audioSubscription;
  IOSink? _sink;
  IOSink? _audioSink;
  RecordingSegment? _segment;
  int _segmentNumber = 0;
  DateTime? _segmentStartedAt;

  /// Serializes index saves (and pruning) so concurrent rotations and [stop]
  /// never interleave writes to the same `index.json`.
  Future<void> _pendingSave = Future.value();

  SegmentRecorder({
    required this.index,
    required this.source,
    required this.store,
    this.segmentSeconds = 10,
    this.audioSource,
  });

  bool get isRecording => _subscription != null;

  Future<void> start() async {
    if (_subscription != null) return;

    // Continue numbering past the highest existing segment (segment counts
    // can be lower than the highest number after retention pruning).
    _segmentNumber = index.segments.fold(0, (max, segment) {
      final number =
          int.tryParse(RegExp(r'\d+').firstMatch(segment.file)?[0] ?? '') ?? 0;

      return number > max ? number : max;
    });

    _subscription = source.nals.listen(_onNal);

    _audioSubscription = audioSource?.frames.listen(_onAudioFrame);
  }

  void _onAudioFrame(AudioFrame frame) => _audioSink?.add(frame.data);

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

    if (audioSource != null) {
      final audioName = name.replaceAll('.h264', '.alaw');

      _segment!.audioFile = audioName;
      _audioSink = File('${index.directory.path}/$audioName').openWrite();
    }

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
    final closingAudio = _audioSink;

    _sink = null;
    _audioSink = null;

    _openSegment(now);

    // Flush the closed segment, then persist the index and apply retention —
    // all serialized on one queue so saves never interleave. IO errors are
    // logged into the queue's catch rather than crashing the isolate.
    _enqueueSave(
      before: Future.wait([
        if (closing != null) closing.close(),
        if (closingAudio != null) closingAudio.close(),
      ]),
    );
  }

  /// Appends a save (and prune) to the serialized queue, optionally awaiting
  /// [before] (e.g. a sink flush) first.
  void _enqueueSave({Future<void>? before}) {
    _pendingSave = _pendingSave
        .then((_) async {
          if (before != null) await before;

          await index.save();
          await store.prune(index);
        })
        .catchError((Object _) {
          // The recording directory may already be deleted; the next save (or
          // stop) will surface persistent problems.
        });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    await _audioSubscription?.cancel();
    _audioSubscription = null;

    await _sink?.close();
    _sink = null;
    _segment = null;

    await _audioSink?.close();
    _audioSink = null;

    await _pendingSave;
    await index.save();
  }
}
