import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'alaw.dart';
import 'audio_source.dart';

/// Captures microphone PCM through platform channels (AVAudioEngine on
/// macOS/iOS, AudioRecord on Android) and converts it to G.711 A-law frames.
///
/// ## Platform-channel contract
///
/// **Method channel** `easy_onvif_server/audio_capture`:
/// - `start` `{deviceUid: String}` — begin capture; empty UID = default input
///   (the UID is honored on macOS only).
/// - `stop` — end capture.
///
/// **Event channel** `easy_onvif_server/audio_capture/events`:
/// - Emits PCM16 little-endian mono 8 kHz chunks as `Uint8List`.
class NativeAudioSource implements AudioStreamSource {
  static const _control = MethodChannel('easy_onvif_server/audio_capture');
  static const _events = EventChannel('easy_onvif_server/audio_capture/events');

  /// Raw platform identifier of the input device (macOS CoreAudio UID).
  final String deviceUid;

  final _controller = StreamController<AudioFrame>.broadcast();
  late final AlawFramer _framer = AlawFramer(_controller.add);

  StreamSubscription<Object?>? _subscription;

  NativeAudioSource({this.deviceUid = ''});

  @override
  Stream<AudioFrame> get frames => _controller.stream;

  /// Feeds PCM16LE bytes through A-law into 20 ms frames. Exposed for tests;
  /// the event channel calls this with each native chunk.
  void addPcmBytes(Uint8List bytes) {
    // The standard message codec hands us a view into the shared message
    // buffer, which can start at an odd offset; Int16List.view requires
    // 2-byte alignment, so copy misaligned chunks into a fresh buffer.
    final samples = bytes.offsetInBytes.isEven
        ? Int16List.view(bytes.buffer, bytes.offsetInBytes, bytes.length ~/ 2)
        : Uint8List.fromList(bytes).buffer.asInt16List(0, bytes.length ~/ 2);

    _framer.add(alawEncode(samples));
  }

  @override
  Future<void> start() async {
    if (_subscription != null) return;

    _subscription = _events.receiveBroadcastStream().listen((event) {
      if (event is Uint8List) addPcmBytes(event);
    });

    try {
      await _control.invokeMethod('start', {'deviceUid': deviceUid});
    } on MissingPluginException {
      // No native capture on this platform; the stream stays silent.
    }
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    try {
      await _control.invokeMethod('stop');
    } on MissingPluginException {
      // Nothing to tear down.
    }
  }
}
