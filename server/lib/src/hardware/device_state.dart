import 'dart:async';

/// A normalized PTZ position. Pan/tilt are in `[-1, 1]`; zoom is in `[0, 1]`.
class PtzVector {
  double pan;
  double tilt;
  double zoom;

  PtzVector({this.pan = 0, this.tilt = 0, this.zoom = 0});

  PtzVector copy() => PtzVector(pan: pan, tilt: tilt, zoom: zoom);

  void clamp() {
    pan = pan.clamp(-1, 1);
    tilt = tilt.clamp(-1, 1);
    zoom = zoom.clamp(0, 1);
  }
}

/// A stored PTZ preset.
class PtzPreset {
  final String token;
  String name;
  final PtzVector position;

  PtzPreset({required this.token, required this.name, required this.position});
}

/// A media profile advertised by the device.
class MediaProfile {
  final String token;
  final String name;

  const MediaProfile({required this.token, required this.name});
}

/// An ONVIF device user.
class OnvifUser {
  final String username;
  String password;

  /// One of `Administrator`, `Operator`, `User`, `Anonymous`.
  String level;

  OnvifUser({
    required this.username,
    required this.password,
    this.level = 'Administrator',
  });
}

/// In-memory state for the simulated ONVIF device: media profiles, PTZ
/// position/presets, and users.
///
/// PTZ movement is simulated. `ContinuousMove` applies a velocity on a timer;
/// `AbsoluteMove`/`GotoPreset`/`GotoHomePosition` set the position directly.
class DeviceState {
  static const profileToken = 'Profile_1';
  static const videoSourceToken = 'VideoSource_1';
  static const ptzConfigurationToken = 'PTZConfig_1';

  final List<MediaProfile> profiles = [
    const MediaProfile(token: profileToken, name: 'Main Profile'),
  ];

  final Map<String, PtzPreset> presets = {};

  final List<OnvifUser> users = [];

  final PtzVector position = PtzVector();

  PtzVector home = PtzVector();

  PtzVector _velocity = PtzVector();

  Timer? _moveTimer;

  int _presetCounter = 0;

  /// Begins continuous movement at the given normalized velocities.
  void continuousMove({double pan = 0, double tilt = 0, double zoom = 0}) {
    _velocity = PtzVector(pan: pan, tilt: tilt, zoom: zoom);

    _moveTimer?.cancel();

    _moveTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      position.pan += _velocity.pan * 0.1;
      position.tilt += _velocity.tilt * 0.1;
      position.zoom += _velocity.zoom * 0.1;
      position.clamp();
    });
  }

  /// Stops any ongoing movement.
  void stop() {
    _velocity = PtzVector();
    _moveTimer?.cancel();
    _moveTimer = null;
  }

  /// Moves directly to an absolute position.
  void absoluteMove(PtzVector target) {
    stop();
    position
      ..pan = target.pan
      ..tilt = target.tilt
      ..zoom = target.zoom
      ..clamp();
  }

  /// Moves by a relative translation.
  void relativeMove(PtzVector translation) {
    stop();
    position.pan += translation.pan;
    position.tilt += translation.tilt;
    position.zoom += translation.zoom;
    position.clamp();
  }

  /// Stores the current position as a preset, returning the preset token.
  String setPreset(String? presetName, [String? presetToken]) {
    final token = presetToken ?? 'Preset_${++_presetCounter}';

    presets[token] = PtzPreset(
      token: token,
      name: presetName ?? token,
      position: position.copy(),
    );

    return token;
  }

  void removePreset(String token) => presets.remove(token);

  void gotoPreset(String token) {
    final preset = presets[token];

    if (preset == null) return;

    absoluteMove(preset.position);
  }

  void setHomePosition() {
    home = position.copy();
  }

  void gotoHomePosition() {
    absoluteMove(home);
  }

  void dispose() => stop();
}
