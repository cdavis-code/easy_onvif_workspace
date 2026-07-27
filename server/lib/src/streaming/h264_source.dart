import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:loggy/loggy.dart';

/// A single H.264 NAL unit (Annex-B start code stripped) tagged with the RTP
/// timestamp of the access unit it belongs to and whether it is the last NAL
/// of that access unit (used to set the RTP marker bit).
class H264NalUnit {
  /// The raw NAL unit bytes, including the one-byte NAL header.
  final Uint8List data;

  /// The 90 kHz RTP timestamp for this access unit.
  final int timestamp;

  /// True if this is the final NAL of its access unit (a VCL NAL).
  final bool lastOfFrame;

  H264NalUnit(this.data, this.timestamp, this.lastOfFrame);

  /// The NAL unit type (the low 5 bits of the header byte).
  int get type => data.isEmpty ? 0 : data[0] & 0x1f;

  bool get isSps => type == 7;
  bool get isPps => type == 8;
  bool get isVcl => type >= 1 && type <= 5;
}

/// Splits a byte stream carrying H.264 Annex-B data into individual NAL units.
///
/// Handles both 3-byte (`00 00 01`) and 4-byte (`00 00 00 01`) start codes.
class AnnexBSplitter {
  final List<int> _buffer = [];

  /// Feeds [data] into the splitter and returns any complete NAL units whose
  /// trailing start code has been received.
  List<Uint8List> feed(List<int> data) {
    _buffer.addAll(data);

    final nals = <Uint8List>[];

    while (true) {
      final firstEnd = _findStartCodeEnd(0);

      if (firstEnd < 0) break;

      final nextStart = _findStartCodeStart(firstEnd);

      if (nextStart < 0) break;

      if (nextStart > firstEnd) {
        nals.add(Uint8List.fromList(_buffer.sublist(firstEnd, nextStart)));
      }

      _buffer.removeRange(0, nextStart);
    }

    return nals;
  }

  /// Returns the index just past the first `00 00 01` at or after [from], or
  /// `-1` if none is present.
  int _findStartCodeEnd(int from) {
    final p = _indexOfStartCode(from);

    return p < 0 ? -1 : p + 3;
  }

  /// Returns the start index of the first start code at or after [from],
  /// accounting for an optional leading zero (4-byte start code), or `-1`.
  int _findStartCodeStart(int from) {
    final p = _indexOfStartCode(from);

    if (p < 0) return -1;

    return (p > 0 && _buffer[p - 1] == 0x00) ? p - 1 : p;
  }

  int _indexOfStartCode(int from) {
    for (var i = from; i + 2 < _buffer.length; i++) {
      if (_buffer[i] == 0x00 &&
          _buffer[i + 1] == 0x00 &&
          _buffer[i + 2] == 0x01) {
        return i;
      }
    }

    return -1;
  }
}

/// A source of H.264 NAL units that an [RtspServer] can packetize and serve.
///
/// Implemented by [H264Source] (ffmpeg-backed, desktop) and
/// `CameraH264Source` (camera-plugin-backed, mobile), so the RTSP server is
/// agnostic to where the video comes from.
abstract interface class NalStreamSource {
  /// The live stream of NAL units, tagged with RTP timestamps.
  Stream<H264NalUnit> get nals;

  /// The most recently seen SPS parameter set, if any.
  Uint8List? get sps;

  /// The most recently seen PPS parameter set, if any.
  Uint8List? get pps;

  /// Completes once both SPS and PPS have been captured (required to build a
  /// valid SDP).
  Future<void> get parametersReady;
}

/// Groups a flat sequence of H.264 NAL units into access units, assigns RTP
/// timestamps, captures SPS/PPS, and re-emits them as [H264NalUnit]s ready for
/// RTP packetization.
///
/// Shared by every [NalStreamSource] so the ffmpeg- and camera-backed sources
/// produce identically framed output.
///
/// With [liveTimestamps] enabled, each access unit is stamped with its actual
/// wall-clock arrival time instead of a fixed `90000 / frameRate` increment.
/// Live capture sources must use this: cameras deliver at their native rate
/// (often 30 fps) regardless of the configured [frameRate], and fixed
/// increments would make the RTP media clock run faster than real time —
/// players pace by RTP timestamps, so playback turns into slow motion with an
/// ever-growing delay. Offline consumers (replay's [frameRate]-paced file
/// loading) keep the fixed increments.
class AccessUnitFramer {
  final int frameRate;

  /// Stamp access units with wall-clock arrival time (live capture) instead
  /// of fixed [frameRate] increments (offline/replay).
  final bool liveTimestamps;

  /// Injectable monotonic clock (microseconds) for tests; defaults to a
  /// [Stopwatch] started on the first frame.
  final int Function()? _clockMicros;

  Stopwatch? _liveClock;

  final _controller = StreamController<H264NalUnit>.broadcast();

  /// NAL units accumulated for the access unit currently being built.
  final List<Uint8List> _currentAu = [];

  /// Wall-clock arrival time of the first NAL of the current access unit,
  /// captured eagerly so the (later) flush stamps the unit with the time its
  /// frame actually arrived.
  int _currentAuArrivalMicros = 0;

  Completer<void>? _paramsCompleter;

  int _timestamp = 0;
  late final int _frameInterval = 90000 ~/ frameRate;

  Uint8List? sps;
  Uint8List? pps;

  AccessUnitFramer({
    this.frameRate = 15,
    this.liveTimestamps = false,
    int Function()? clockMicros,
  }) : _clockMicros = clockMicros;

  int _elapsedMicros() {
    final clock = _clockMicros;

    if (clock != null) return clock();

    _liveClock ??= Stopwatch()..start();

    return _liveClock!.elapsedMicroseconds;
  }

  Stream<H264NalUnit> get nals => _controller.stream;

  /// Completes once both SPS and PPS parameter sets have been captured.
  Future<void> get parametersReady {
    if (sps != null && pps != null) return Future.value();

    return (_paramsCompleter ??= Completer<void>()).future;
  }

  /// Feeds a single NAL unit into the framer.
  void addNal(Uint8List nal) {
    if (nal.isEmpty) return;

    final type = nal[0] & 0x1f;

    if (type == 7) sps = nal;
    if (type == 8) pps = nal;

    if (sps != null &&
        pps != null &&
        (_paramsCompleter?.isCompleted ?? false) == false) {
      _paramsCompleter?.complete();
    }

    // A new access unit begins on an AUD/SPS/PPS/SEI or on the first slice of
    // a picture (first_mb_in_slice == 0). Multi-slice frames produce several
    // VCL NAL units that must share one RTP timestamp, so they are grouped
    // into a single access unit.
    if (_startsNewAccessUnit(nal) && _currentAu.isNotEmpty) {
      _flush();
    }

    if (type != 9) {
      // Drop access unit delimiters; they carry no payload we need.
      if (_currentAu.isEmpty && liveTimestamps) {
        // First NAL of a new access unit: record when its frame arrived, so
        // the flush (which may run after further NALs) stamps arrival time.
        _currentAuArrivalMicros = _elapsedMicros();
      }

      _currentAu.add(nal);
    }
  }

  /// Emits any partially-accumulated access unit (e.g. when stopping).
  void flush() {
    if (_currentAu.isNotEmpty) _flush();
  }

  /// Discards any buffered state without emitting it.
  void reset() => _currentAu.clear();

  /// Emits the accumulated access unit, marking its final NAL so the RTP
  /// packetizer can set the marker bit, then advances the timestamp.
  void _flush() {
    if (_currentAu.isEmpty) return;

    // Live mode converts the frame's arrival time to 90 kHz ticks; offline
    // mode advances a fixed interval per access unit.
    final timestamp = liveTimestamps
        ? (_currentAuArrivalMicros * 9 ~/ 100) & 0xffffffff
        : _timestamp;

    for (var i = 0; i < _currentAu.length; i++) {
      final isLast = i == _currentAu.length - 1;

      _controller.add(H264NalUnit(_currentAu[i], timestamp, isLast));
    }

    _currentAu.clear();

    _timestamp = (_timestamp + _frameInterval) & 0xffffffff;
  }

  bool _startsNewAccessUnit(Uint8List nal) {
    final type = nal[0] & 0x1f;

    // AUD, SPS, PPS and SEI always precede the first slice of an access unit.
    if (type == 9 || type == 7 || type == 8 || type == 6) return true;

    // VCL NAL: a new access unit starts when this is the first slice of a
    // picture, i.e. first_mb_in_slice == 0. The exp-Golomb code for 0 is a
    // single `1` bit, so the first bit after the NAL header byte is set.
    if (type >= 1 && type <= 5) {
      return nal.length > 1 && (nal[1] & 0x80) != 0;
    }

    return false;
  }
}

/// Thins a frame stream down to a target rate by dropping frames that arrive
/// early.
///
/// Cameras capture at their native rate (often 30 fps) with no way to slow
/// them down through the `camera` plugin, so sources gate the raw frames
/// before encoding to keep the encoded stream, its bandwidth, and recordings
/// at the advertised [frameRate].
class FrameRateGate {
  final int frameRate;

  /// Injectable monotonic clock (microseconds) for tests.
  final int Function()? _clockMicros;

  Stopwatch? _clock;

  late final int _intervalMicros = 1000000 ~/ frameRate;
  int _nextDueMicros = 0;

  FrameRateGate({required this.frameRate, int Function()? clockMicros})
    : _clockMicros = clockMicros;

  /// Returns true when a frame arriving now should be kept.
  bool accept() {
    final int now;

    if (_clockMicros != null) {
      now = _clockMicros();
    } else {
      _clock ??= Stopwatch()..start();
      now = _clock!.elapsedMicroseconds;
    }

    if (now < _nextDueMicros) return false;

    _nextDueMicros = now + _intervalMicros;

    return true;
  }
}

/// Produces a live stream of H.264 NAL units by running `ffmpeg` and reading
/// the encoded Annex-B bitstream from its stdout.
///
/// The default [inputArgs] generate a test pattern; pass device-specific input
/// arguments (e.g. a webcam or the Flutter camera feed) to stream real video.
class H264Source implements NalStreamSource {
  final String ffmpegPath;
  final List<String> inputArgs;
  final int frameRate;

  Process? _process;
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<String>? _stderrSubscription;

  final _log = Loggy('H264Source');

  final _splitter = AnnexBSplitter();
  late final AccessUnitFramer _framer = AccessUnitFramer(
    frameRate: frameRate,
    liveTimestamps: true,
  );

  H264Source({
    this.ffmpegPath = 'ffmpeg',
    this.frameRate = 15,
    List<String>? inputArgs,
  }) : inputArgs =
           inputArgs ??
           ['-f', 'lavfi', '-i', 'testsrc=size=1280x720:rate=$frameRate'];

  @override
  Stream<H264NalUnit> get nals => _framer.nals;

  @override
  Uint8List? get sps => _framer.sps;

  @override
  Uint8List? get pps => _framer.pps;

  bool get isRunning => _process != null;

  /// Completes once both SPS and PPS parameter sets have been captured, so the
  /// RTSP server can build a valid SDP.
  @override
  Future<void> get parametersReady => _framer.parametersReady;

  Future<void> start() async {
    if (_process != null) return;

    _process = await Process.start(ffmpegPath, [
      '-hide_banner',
      '-loglevel',
      'error',
      '-re',
      ...inputArgs,
      '-pix_fmt',
      'yuv420p',
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-tune',
      'zerolatency',
      '-g',
      '$frameRate',
      '-bsf:v',
      'dump_extra',
      '-f',
      'h264',
      'pipe:1',
    ]);

    _subscription = _process!.stdout.listen(_onData);

    // Surface ffmpeg diagnostics (e.g. a denied camera device) instead of
    // silently discarding them, and drain the pipe so ffmpeg does not block.
    _stderrSubscription = _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _log.warning('ffmpeg: $line'));
  }

  void _onData(List<int> chunk) {
    for (final nal in _splitter.feed(chunk)) {
      _framer.addNal(nal);
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    await _stderrSubscription?.cancel();
    _stderrSubscription = null;

    _process?.kill(ProcessSignal.sigkill);
    _process = null;

    _framer.flush();
    _framer.reset();
  }
}
