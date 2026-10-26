import 'dart:async';

import 'package:flutter/services.dart';
import 'package:loggy/loggy.dart';

import 'h264_source.dart';

/// A [NalStreamSource] fed by native ScreenCaptureKit display capture
/// (macOS 12.3+). The native side pushes captured frames through the shared
/// VideoToolbox encoder, so encoded H.264 arrives on the existing
/// `easy_onvif_server/h264_encoder/events` channel.
class ScreenH264Source with UiLoggy implements NalStreamSource {
  static const _control = MethodChannel('easy_onvif_server/screen_capture');
  static const _events = EventChannel('easy_onvif_server/h264_encoder/events');

  /// Raw CGDirectDisplayID from settings; empty selects the main display.
  final String displayId;

  final int frameRate;

  final _splitter = AnnexBSplitter();
  late final AccessUnitFramer _framer = AccessUnitFramer(
    frameRate: frameRate,
    liveTimestamps: true,
  );

  StreamSubscription<Object?>? _subscription;
  bool _running = false;

  ScreenH264Source({this.displayId = '', this.frameRate = 15});

  @override
  Stream<H264NalUnit> get nals => _framer.nals;

  @override
  Uint8List? get sps => _framer.sps;

  @override
  Uint8List? get pps => _framer.pps;

  @override
  Future<void> get parametersReady => _framer.parametersReady;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;

    _subscription = _events.receiveBroadcastStream().listen((event) {
      if (event is Uint8List) {
        for (final nal in _splitter.feed(event)) {
          _framer.addNal(nal);
        }
      }
    });

    await _control.invokeMethod('start', {
      'displayId': int.tryParse(displayId) ?? 0,
      'width': 1280,
      'height': 720,
      'frameRate': frameRate,
    });

    _running = true;

    loggy.info(
      'Screen capture source started '
      '(display ${displayId.isEmpty ? 'main' : displayId})',
    );
  }

  Future<void> stop() async {
    if (!_running) return;

    _running = false;

    try {
      await _control.invokeMethod('stop');
    } on MissingPluginException {
      // Native side absent (non-macOS): nothing to stop.
    }

    await _subscription?.cancel();
    _subscription = null;

    _framer.flush();
    _framer.reset();
  }
}
