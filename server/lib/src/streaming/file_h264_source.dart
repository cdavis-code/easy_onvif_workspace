import 'dart:async';
import 'dart:typed_data';

import '../recording/recording_index.dart';
import 'audio_source.dart';
import 'h264_source.dart';

/// Plays a recorded segment sequence back as a live-like NAL stream, paced at
/// the recorded frame rate. One instance per replay session.
class FileH264Source implements NalStreamSource {
  final RecordingIndex index;

  /// Optional seek target: playback starts at the first segment whose end is
  /// after this instant (segments are keyframe-aligned).
  final DateTime? startUtc;

  final _controller = StreamController<H264NalUnit>.broadcast();
  late final AccessUnitFramer _framer = AccessUnitFramer(
    frameRate: index.frameRate,
  );

  Timer? _timer;
  final List<List<H264NalUnit>> _accessUnits = [];
  int _position = 0;
  bool _loaded = false;

  final _audioController = StreamController<AudioFrame>.broadcast();
  final List<Uint8List> _audioChunks = [];
  int _audioPosition = 0;
  Timer? _audioTimer;

  FileH264Source({required this.index, this.startUtc});

  @override
  Stream<H264NalUnit> get nals => _controller.stream;

  /// Whether the loaded segments carried audio sidecars.
  bool get hasAudio => _audioChunks.isNotEmpty;

  /// Paced 20 ms replay audio frames (empty for video-only recordings).
  Stream<AudioFrame> get audioFrames => _audioController.stream;

  @override
  Uint8List? get sps => _framer.sps;

  @override
  Uint8List? get pps => _framer.pps;

  @override
  Future<void> get parametersReady => _framer.parametersReady;

  /// Reads the segment files (honoring [startUtc]) and groups their NALs into
  /// timestamped access units. Completes [parametersReady], so `DESCRIBE` can
  /// build a valid SDP before [play] starts pacing.
  Future<void> load() async {
    if (_loaded) return;

    _loaded = true;

    final seek = startUtc;
    final segments = seek == null
        ? index.segments
        : index.segments.where((s) => s.endUtc.isAfter(seek)).toList();

    // Group the file NALs into timestamped access units by running them
    // through the shared framer and buffering its output.
    final buffered = <H264NalUnit>[];
    final sub = _framer.nals.listen(buffered.add);
    final splitter = AnnexBSplitter();

    for (final segment in segments) {
      final file = index.segmentFile(segment);

      if (!file.existsSync()) continue;

      for (final nal in splitter.feed(await file.readAsBytes())) {
        _framer.addNal(nal);
      }

      // The splitter only emits a NAL once the next start code arrives, so
      // push a dummy AUD (dropped by the framer) to flush the segment's tail.
      _framer.addNal(Uint8List.fromList([0x09, 0x10]));
    }

    _framer.flush();

    // The broadcast framer stream delivers in microtasks; let them drain
    // before detaching so no trailing access unit is lost.
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    // Regroup buffered NALs by timestamp into access units.
    for (final nal in buffered) {
      if (_accessUnits.isEmpty ||
          _accessUnits.last.first.timestamp != nal.timestamp) {
        _accessUnits.add([nal]);
      } else {
        _accessUnits.last.add(nal);
      }
    }

    // Load the audio sidecars. Playback is segment-aligned: video starts at
    // the beginning of the first included segment, so audio does too — no
    // intra-segment byte skip, or audio would lead video after a seek.
    for (final segment in segments) {
      final sidecar = index.audioFile(segment);

      if (sidecar == null || !sidecar.existsSync()) continue;

      final bytes = await sidecar.readAsBytes();

      for (var offset = 0; offset + 160 <= bytes.length; offset += 160) {
        _audioChunks.add(bytes.sublist(offset, offset + 160));
      }
    }
  }

  /// Begins paced emission of the loaded access units.
  void play() {
    if (_timer == null && _accessUnits.isNotEmpty) {
      final interval = Duration(microseconds: 1000000 ~/ index.frameRate);

      _timer = Timer.periodic(interval, (_) {
        if (_position >= _accessUnits.length) {
          _timer?.cancel();

          return; // End of recording: stop emitting, keep the session open.
        }

        for (final nal in _accessUnits[_position]) {
          _controller.add(nal);
        }

        _position++;
      });
    }

    if (_audioChunks.isNotEmpty && _audioTimer == null) {
      _audioTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
        if (_audioPosition >= _audioChunks.length) {
          _audioTimer?.cancel();

          return;
        }

        _audioController.add(
          AudioFrame(_audioChunks[_audioPosition], _audioPosition * 160),
        );

        _audioPosition++;
      });
    }
  }

  /// Loads and starts playback in one step.
  Future<void> start() async {
    await load();

    play();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;

    _audioTimer?.cancel();
    _audioTimer = null;

    await _controller.close();
    await _audioController.close();
  }
}
