import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:loggy/loggy.dart';

import 'audio_source.dart';

/// Captures an audio device (or a lavfi test tone) with a small dedicated
/// `ffmpeg` process emitting raw G.711 A-law at 8 kHz mono on stdout.
///
/// Runs separately from the video ffmpeg process so audio can fail (missing
/// device, permission) without disturbing the video stream.
class FfmpegAudioSource implements AudioStreamSource {
  final String ffmpegPath;
  final List<String> inputArgs;

  Process? _process;
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<String>? _stderrSubscription;

  final _controller = StreamController<AudioFrame>.broadcast();
  late final AlawFramer _framer = AlawFramer(_controller.add);

  final _log = Loggy('FfmpegAudioSource');

  FfmpegAudioSource({this.ffmpegPath = 'ffmpeg', List<String>? inputArgs})
    : inputArgs =
          inputArgs ??
          ['-f', 'lavfi', '-i', 'sine=frequency=440:sample_rate=8000'];

  @override
  Stream<AudioFrame> get frames => _controller.stream;

  @override
  Future<void> start() async {
    if (_process != null) return;

    _process = await Process.start(ffmpegPath, [
      '-hide_banner',
      '-loglevel',
      'error',
      '-re',
      ...inputArgs,
      '-ar',
      '8000',
      '-ac',
      '1',
      '-f',
      'alaw',
      'pipe:1',
    ]);

    _subscription = _process!.stdout.listen(_framer.add);

    _stderrSubscription = _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _log.warning('ffmpeg(audio): $line'));
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    await _stderrSubscription?.cancel();
    _stderrSubscription = null;

    _process?.kill(ProcessSignal.sigkill);
    _process = null;
  }
}
