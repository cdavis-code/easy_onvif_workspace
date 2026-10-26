import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loggy/loggy.dart';

import 'hardware_adapter.dart';

/// A [HardwareAdapter] backed by the device's real camera and location
/// hardware via the `camera` and `geolocator` plugins.
///
/// Every capability degrades gracefully: if no camera is available (or it
/// fails to initialize) snapshots return `null`, and if location permission is
/// not granted [currentLocation] returns `null`.
class FlutterAdapter with UiLoggy implements HardwareAdapter {
  final ResolutionPreset resolution;

  /// When false, the camera is not opened by this adapter. On desktop the
  /// `FfmpegBackend` owns the camera for the RTSP stream, so the adapter must
  /// leave it alone to avoid two consumers contending for the same device.
  final bool enableCamera;

  CameraController? _controller;

  FlutterAdapter({
    this.resolution = ResolutionPreset.medium,
    this.enableCamera = true,
  });

  @override
  bool get hasCamera =>
      enableCamera && (_controller?.value.isInitialized ?? false);

  /// The active camera controller, exposed so the UI can show a preview.
  CameraController? get controller => _controller;

  @override
  Future<void> startCamera() async {
    if (!enableCamera) return;

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        loggy.info('No cameras available; snapshot/stream hardware disabled.');
        return;
      }

      final controller = CameraController(
        cameras.first,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      _controller = controller;

      loggy.info('Camera initialized: ${cameras.first.name}');
    } catch (error) {
      loggy.error('Failed to initialize camera: $error');
    }
  }

  @override
  Future<void> stopCamera() async {
    await _controller?.dispose();
    _controller = null;
  }

  @override
  Future<Uint8List?> captureSnapshot() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) return null;

    try {
      final file = await controller.takePicture();

      return await file.readAsBytes();
    } catch (error) {
      loggy.error('Failed to capture snapshot: $error');

      return null;
    }
  }

  @override
  Future<GeoLocation?> currentLocation() async {
    try {
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        loggy.info('Location permission not granted.');

        return null;
      }

      final position = await Geolocator.getCurrentPosition();

      return GeoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        elevation: position.altitude,
      );
    } catch (error) {
      loggy.error('Failed to read location: $error');

      return null;
    }
  }
}
