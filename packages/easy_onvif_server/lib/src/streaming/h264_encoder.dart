import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:loggy/loggy.dart';

/// Encodes raw camera frames into an H.264 Annex-B elementary stream.
///
/// The Flutter `camera` plugin delivers **raw** frames (YUV420 on Android,
/// BGRA8888 on iOS) via `CameraController.startImageStream` — it does not
/// expose a compressed video stream. Producing H.264 therefore requires a
/// platform hardware encoder bridged through platform channels:
///
/// - **Android:** `MediaCodec` (e.g. `video/avc`, `c2.android.avc.encoder`).
/// - **iOS:** `VideoToolbox` (`VTCompressionSession`).
///
/// The encoder emits Annex-B (start-code delimited) bytes on [output]; the
/// `CameraH264Source` splits those into NAL units and frames them for RTP.
abstract interface class H264Encoder {
  /// Configures the encoder for frames of [width]x[height] at [frameRate] fps.
  Future<void> start({
    required int width,
    required int height,
    required int frameRate,
  });

  /// A stream of Annex-B H.264 byte chunks (SPS/PPS/IDR/non-IDR NAL units with
  /// `00 00 00 01` start codes) as the encoder produces them.
  Stream<Uint8List> get output;

  /// Feeds a single raw camera [frame] to the encoder.
  void encode(CameraImage frame);

  /// Releases the encoder.
  Future<void> stop();
}

/// A skeletal [H264Encoder] that wires up the platform channels but does not
/// yet ship the native encoder implementations.
///
/// ## Platform-channel contract (to be implemented natively)
///
/// **Method channel** `easy_onvif_server/h264_encoder`:
/// - `start` `{width: int, height: int, frameRate: int}` — create and start the
///   hardware encoder, configured for Annex-B output (on Android set
///   `KEY_BITRATE_MODE`/`KEY_I_FRAME_INTERVAL` and request `csd-0`/`csd-1`
///   SPS/PPS; emit them first).
/// - `encode` `{planes, strides, format, width, height}` — queue one raw
///   frame for encoding (`planes`/`strides` are per-plane byte lists).
/// - `stop` — flush and release the encoder.
///
/// **Event channel** `easy_onvif_server/h264_encoder/events`:
/// - Emits each encoded access unit as a `Uint8List` of Annex-B bytes
///   (including SPS/PPS before keyframes).
///
/// Until the native side exists, [encode] is a no-op that logs once, so the
/// surrounding pipeline (camera → encoder → RTSP server) can be exercised
/// end-to-end on the Dart side.
class PlatformChannelH264Encoder with UiLoggy implements H264Encoder {
  static const _control = MethodChannel('easy_onvif_server/h264_encoder');
  static const _events = EventChannel('easy_onvif_server/h264_encoder/events');

  bool _warned = false;

  /// The configured frame dimensions, captured at [start] so [encode] can tag
  /// each raw frame with the size the native encoder expects.
  int _width = 0;
  int _height = 0;

  @override
  Stream<Uint8List> get output => _events
      .receiveBroadcastStream()
      .where((event) => event is Uint8List)
      .cast<Uint8List>();

  @override
  Future<void> start({
    required int width,
    required int height,
    required int frameRate,
  }) async {
    _width = width;
    _height = height;

    try {
      await _control.invokeMethod('start', {
        'width': width,
        'height': height,
        'frameRate': frameRate,
      });
    } on MissingPluginException {
      _warnUnimplemented();
    }
  }

  @override
  void encode(CameraImage frame) {
    // Forward the raw pixel bytes to the native hardware encoder. On macOS
    // (camera_desktop) the image stream delivers a single-plane BGRA buffer,
    // which the VideoToolbox encoder consumes directly.
    if (frame.planes.isEmpty) return;

    final plane = frame.planes.first;
    final bytes = plane.bytes;
    final width = frame.width > 0 ? frame.width : _width;
    final height = frame.height > 0 ? frame.height : _height;

    if (width <= 0 || height <= 0 || bytes.isEmpty) return;

    // The row stride may include padding; pass it so the native encoder reads
    // each source row at the correct offset.
    final bytesPerRow = plane.bytesPerRow > 0 ? plane.bytesPerRow : width * 4;

    // Fire-and-forget: frames must not block the camera's image-stream callback
    // waiting for the encode round-trip.
    _control
        .invokeMethod<void>('encode', {
          'bytes': bytes,
          'width': width,
          'height': height,
          'bytesPerRow': bytesPerRow,
        })
        .catchError((Object error) {
          if (!_warned) {
            _warned = true;
            loggy.warning('Failed to forward camera frame to encoder: $error');
          }
        });
  }

  @override
  Future<void> stop() async {
    try {
      await _control.invokeMethod('stop');
    } on MissingPluginException {
      // Native side never registered; nothing to tear down.
    }
  }

  void _warnUnimplemented() {
    _warned = true;
    loggy.warning(
      'PlatformChannelH264Encoder has no native implementation yet; '
      'camera frames will not be encoded. Implement the MediaCodec '
      '(Android) / VideoToolbox (iOS/macOS) encoder behind the '
      '"easy_onvif_server/h264_encoder" channels to enable streaming.',
    );
  }
}
