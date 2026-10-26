import 'dart:typed_data';

/// A geographic location reported by the device, mapped to the ONVIF
/// `LocationEntity` shape used by `GetGeoLocation`.
class GeoLocation {
  final double latitude;
  final double longitude;
  final double? elevation;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.elevation,
  });
}

/// Abstraction over the host device's hardware so the SOAP core stays
/// platform-independent and testable.
///
/// The Flutter implementation (`FlutterAdapter`) backs this with the `camera`
/// and `geolocator` plugins; tests use [StubHardwareAdapter].
abstract interface class HardwareAdapter {
  /// Initializes the camera (if any). Safe to call when no camera exists.
  Future<void> startCamera();

  /// Releases the camera.
  Future<void> stopCamera();

  /// Whether a camera is available for snapshots / streaming.
  bool get hasCamera;

  /// Captures a single JPEG frame, or `null` if no camera is available.
  Future<Uint8List?> captureSnapshot();

  /// Returns the current geographic location, or `null` if unavailable.
  Future<GeoLocation?> currentLocation();
}

/// A no-op [HardwareAdapter] used for headless testing and as a fallback when
/// no device hardware is accessible.
class StubHardwareAdapter implements HardwareAdapter {
  @override
  bool get hasCamera => false;

  @override
  Future<void> startCamera() async {}

  @override
  Future<void> stopCamera() async {}

  @override
  Future<Uint8List?> captureSnapshot() async => null;

  @override
  Future<GeoLocation?> currentLocation() async => null;
}
