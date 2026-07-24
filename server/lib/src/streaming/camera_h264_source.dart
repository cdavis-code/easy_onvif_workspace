import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:loggy/loggy.dart';

import 'h264_encoder.dart';
import 'h264_source.dart';

/// A [NalStreamSource] that streams the device camera **without ffmpeg**.
///
/// Pipeline:
///
/// ```
/// camera plugin (raw frames)
///        │  startImageStream
///        ▼
///   H264Encoder (platform MediaCodec / VideoToolbox via platform channels)
///        │  Annex-B byte chunks
///        ▼
///   AnnexBSplitter → AccessUnitFramer (shared with the ffmpeg source)
///        │  H264NalUnit stream
///        ▼
///   RtspServer (unchanged — it only needs a NalStreamSource)
/// ```
///
/// Because the heavy lifting (NAL splitting, access-unit framing, RTP
/// timestamps, SPS/PPS capture) is reused from [AccessUnitFramer], the RTSP
/// server and packetizer work identically whether the video comes from ffmpeg
/// (desktop) or the camera (mobile).
class CameraH264Source with UiLoggy implements NalStreamSource {
  /// The platform H.264 encoder. Defaults to [PlatformChannelH264Encoder].
  final H264Encoder encoder;

  final int frameRate;
  final ResolutionPreset resolution;

  /// The pixel format requested from the camera image stream. YUV420 suits
  /// Android's `MediaCodec`; iOS typically delivers BGRA8888 — pass
  /// [ImageFormatGroup.bgra8888] there and make the encoder handle it.
  final ImageFormatGroup imageFormatGroup;

  final CameraDescription? _camera;

  final _splitter = AnnexBSplitter();
  late final AccessUnitFramer _framer = AccessUnitFramer(frameRate: frameRate);

  CameraController? _controller;
  StreamSubscription<Uint8List>? _encoderSubscription;

  CameraH264Source({
    H264Encoder? encoder,
    this.frameRate = 15,
    this.resolution = ResolutionPreset.medium,
    this.imageFormatGroup = ImageFormatGroup.yuv420,
    CameraDescription? camera,
  }) : encoder = encoder ?? PlatformChannelH264Encoder(),
       _camera = camera;

  @override
  Stream<H264NalUnit> get nals => _framer.nals;

  @override
  Uint8List? get sps => _framer.sps;

  @override
  Uint8List? get pps => _framer.pps;

  @override
  Future<void> get parametersReady => _framer.parametersReady;

  /// The active camera controller, exposed so the UI can show a preview.
  CameraController? get controller => _controller;

  bool get isRunning => _controller != null;

  Future<void> start() async {
    if (_controller != null) return;

    final description = _camera ?? await _firstCamera();

    final controller = CameraController(
      description,
      resolution,
      enableAudio: false,
      imageFormatGroup: imageFormatGroup,
    );

    await controller.initialize();

    // `previewSize` is reported in the sensor's native orientation, so on a
    // portrait device width/height may need swapping. The native encoder
    // should honor the actual frame dimensions it receives.
    final previewSize = controller.value.previewSize;
    final width = previewSize?.width.toInt() ?? 1280;
    final height = previewSize?.height.toInt() ?? 720;

    await encoder.start(width: width, height: height, frameRate: frameRate);

    _encoderSubscription = encoder.output.listen(_onEncodedChunk);

    await controller.startImageStream(encoder.encode);

    _controller = controller;

    loggy.info(
      'Camera H.264 source started ($width x $height @ $frameRate fps)',
    );
  }

  void _onEncodedChunk(Uint8List chunk) {
    for (final nal in _splitter.feed(chunk)) {
      _framer.addNal(nal);
    }
  }

  Future<CameraDescription> _firstCamera() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw StateError('No cameras available to stream from.');
    }

    return cameras.first;
  }

  Future<void> stop() async {
    final controller = _controller;

    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    }
    _controller = null;

    await _encoderSubscription?.cancel();
    _encoderSubscription = null;

    await encoder.stop();

    _framer.flush();
    _framer.reset();
  }
}
