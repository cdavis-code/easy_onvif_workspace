import 'dart:math' as math;

import 'package:easy_onvif/ptz.dart';
import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' as soap;

import 'operation.dart';

typedef PtzRequest = soap.PtzRequest;

enum BackupMove { absolute, continuous }

/// The PTZ model groups the possible movements of the PTZ unit into a pan/tilt
/// component and into a Zoom component.  To steer the PTZ unit, the service
/// provides absolute move, relative move and continuous move operations.
/// Different coordinate systems and units are used to feed these operations.
///
/// Default Access Policy Definition
/// | | Administrator | Operator | User | Anonymous |
/// | PRE_AUTH | X | X | X | X |
/// | READ_SYSTEM | X | X | X | |
/// | READ_SYSTEM_SENSITIVE | X | X | | |
/// | READ_SYSTEM_SECRET | X | | | |
/// | WRITE_SYSTEM | X | | | |
/// | UNRECOVERABLE | X | | | |
/// | READ_MEDIA | X | X | X | |
/// | ACTUATE | X | X | | |
class Ptz extends Operation {
  final configurationCache = <String, PtzConfiguration>{};

  PanTiltLimits? defaultPanTiltLimits;
  PtzSpeed? defaultSpeed;
  ZoomLimits? defaultZoomLimits;

  Ptz({required super.transport, required super.uri});

  /// Operation to move pan,tilt or zoom to a absolute destination.
  ///
  /// The speed argument is optional. If an x/y speed value is given it is up to
  /// the device to either use the x value as absolute resulting speed vector or
  /// to map x and y to the component speed. If the speed argument is omitted,
  /// the default speed set by the [PtzConfiguration] will be used.
  ///
  /// ACCESS CLASS: ACTUATE
  Future<bool> absoluteMove(
    String profileToken, {
    required PtzVector position,
    PtzSpeed? speed,
  }) async {
    loggy.debug('absoluteMove');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: PtzRequest.absoluteMove(
          profileToken,
          position: position,
          speed: speed,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// Operation for continuous Pan/Tilt and Zoom movements. The operation is
  /// supported if the PTZNode supports at least one continuous Pan/Tilt or Zoom
  /// space. If the space argument is omitted, the default space set by the
  /// [PtzConfiguration] will be used.
  ///
  /// ACCESS CLASS: ACTUATE
  Future<bool> continuousMove(
    String profileToken, {
    required PtzSpeed velocity,
    int? timeout,
  }) async {
    loggy.debug('continuousMove');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: PtzRequest.continuousMove(
          profileToken,
          velocity: velocity,
          timeout: timeout,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// Operation to get all available PTZConfigurations that can be added to the
  /// referenced media profile.
  /// A device providing more than one PTZConfiguration or more than one
  /// [VideoSourceConfiguration] or which has any other resource interdependency
  /// between [PtzConfiguration] entities and other resources listable in a
  /// media profile should implement this operation. PTZConfiguration entities
  /// returned by this operation shall not fail on adding them to the referenced
  /// media profile.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<List<PtzConfiguration>> getCompatibleConfigurations(
    String profileToken,
  ) async {
    loggy.debug('getCompatibleConfigurations');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: PtzRequest.getCompatibleConfigurations(profileToken)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetCompatibleConfigurationsResponse.fromJson(
      responseEnvelope.body.response!,
    ).ptzConfigurations;
  }

  /// Get a specific PTZconfiguration from the device, identified by its reference token or name.
  ///
  /// The default Position/Translation/Velocity Spaces are introduced to allow
  /// NVCs sending move requests without the need to specify a certain
  /// coordinate system. The default Speeds are introduced to control the speed
  /// of move requests (absolute, relative, preset), where no explicit speed has
  /// been set.
  ///
  /// The allowed pan and tilt range for Pan/Tilt Limits is defined by a
  /// two-dimensional space range that is mapped to a specific Absolute Pan/Tilt
  /// Position Space. At least one Pan/Tilt Position Space is required by the
  /// PTZNode to support Pan/Tilt limits. The limits apply to all supported
  /// absolute, relative and continuous Pan/Tilt movements. The limits shall be
  /// checked within the coordinate system for which the limits have been
  /// specified. That means that even if movements are specified in a different
  /// coordinate system, the requested movements shall be transformed to the
  /// coordinate system of the limits where the limits can be checked. When a
  /// relative or continuous movements is specified, which would leave the
  /// specified limits, the PTZ unit has to move along the specified limits. The
  /// Zoom Limits have to be interpreted accordingly.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<PtzConfiguration> getConfiguration(String referenceToken) async {
    loggy.debug('getConfiguration');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: PtzRequest.getConfiguration(referenceToken)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetConfigurationResponse.fromJson(
      responseEnvelope.body.response!,
    ).ptzConfiguration;
  }

  /// List supported coordinate systems including their range limitations.
  /// Therefore, the options MAY differ depending on whether the PTZ
  /// Configuration is assigned to a Profile containing a Video Source
  /// Configuration. In that case, the options may additionally contain
  /// coordinate systems referring to the image coordinate system described by
  /// the Video Source Configuration. If the PTZ Node supports continuous
  /// movements, it shall return a Timeout Range within which Timeouts are
  /// accepted by the PTZ Node.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<PtzConfigurationOptions> getConfigurationOptions(
    String configurationToken,
  ) async {
    loggy.debug('getConfigurationOptions');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: PtzRequest.getConfigurationOptions(configurationToken),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetConfigurationOptionsResponse.fromJson(
      responseEnvelope.body.response!,
    ).ptzConfigurationOptions;
  }

  /// Get all the existing PTZConfigurations from the device.
  ///
  /// The default Position/Translation/Velocity Spaces are introduced to allow
  /// NVCs sending move requests without the need to specify a certain
  /// coordinate system. The default Speeds are introduced to control the speed
  /// of move requests (absolute, relative, preset), where no explicit speed has
  /// been set.
  ///
  /// The allowed pan and tilt range for Pan/Tilt Limits is defined by a
  /// two-dimensional space range that is mapped to a specific Absolute Pan/Tilt
  /// Position Space. At least one Pan/Tilt Position Space is required by the
  /// PTZNode to support Pan/Tilt limits. The limits apply to all supported
  /// absolute, relative and continuous Pan/Tilt movements. The limits shall be
  /// checked within the coordinate system for which the limits have been
  /// specified. That means that even if movements are specified in a different
  /// coordinate system, the requested movements shall be transformed to the
  /// coordinate system of the limits where the limits can be checked. When a
  /// relative or continuous movements is specified, which would leave the
  /// specified limits, the PTZ unit has to move along the specified limits. The
  /// Zoom Limits have to be interpreted accordingly.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<List<PtzConfiguration>> getConfigurations() async {
    loggy.debug('getConfigurations');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: PtzRequest.getConfigurations()),
    );

    if (responseEnvelope.body.response == null) throw Exception();

    final ptzConfigurations = GetConfigurationsResponse.fromJson(
      responseEnvelope.body.response!,
    ).ptzConfigurations;

    _clearDefaults();

    for (var ptzConfiguration in ptzConfigurations) {
      defaultSpeed ??= ptzConfiguration.defaultPtzSpeed;

      defaultPanTiltLimits ??= ptzConfiguration.panTiltLimits;

      defaultZoomLimits ??= ptzConfiguration.zoomLimits;

      configurationCache[ptzConfiguration.token] = ptzConfiguration;
    }

    return ptzConfigurations;
  }

  /// Operation to request all PTZ presets for the [Preset] in the selected
  /// profile. The operation is supported if there is support for at least one
  /// PTZ preset by the [Preset].
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<List<Preset>> getPresets(
    String profileToken, {
    int? limit = 100,
  }) async {
    loggy.debug('getPresets');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: PtzRequest.getPresets(profileToken)),
    );

    if (responseEnvelope.body.response == null) throw Exception();

    final presets = GetPresetsResponse.fromJson(
      responseEnvelope.body.response!,
    ).presets;

    limit = (limit! > presets.length) ? presets.length : limit;

    return presets.sublist(0, limit);
  }

  /// Operation to request a specific PTZ preset tour in the selected media
  /// profile.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<PresetTour> getPresetTour(
    String profileToken, {
    required String presetTourToken,
  }) async {
    loggy.debug('getPresetTour');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: PtzRequest.getPresetTour(
          profileToken,
          presetTourToken: presetTourToken,
        ),
      ),
    );

    if (responseEnvelope.body.response == null) throw Exception();

    return GetPresetTourResponse.fromJson(
      responseEnvelope.body.response!,
    ).presetTour;
  }

  /// Operation to request PTZ preset tours in the selected media profiles.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<List<PresetTour>> getPresetTours(String profileToken) async {
    loggy.debug('getPresetTours');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: PtzRequest.getPresetTours(profileToken)),
    );

    if (responseEnvelope.body.response == null) throw Exception();

    return GetPresetToursResponse.fromJson(
      responseEnvelope.body.response!,
    ).presetTours;
  }

  /// Helper method
  Future<Map<String, Preset>> getPresetsMap(String profileToken) async {
    loggy.debug('getPresetsMap');

    return {
      for (var preset in await getPresets(profileToken)) preset.token: preset,
    };
  }

  /// Returns the capabilities of the PTZ service. The result is returned in a
  /// typed answer.
  ///
  /// ACCESS CLASS: PRE_AUTH
  Future<Capabilities?> getServiceCapabilities() async {
    loggy.debug('getServiceCapabilities');

    final responseEnvelope = await transport.request(
      uri,
      soap.Body(request: PtzRequest.getServiceCapabilities()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetServiceCapabilitiesResponse.fromJson(
      responseEnvelope.body.response!,
    ).capabilities;
  }

  /// Operation to request PTZ status for the Node in the selected profile.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<PtzStatus> getStatus(String profileToken) async {
    loggy.debug('getStatus');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: PtzRequest.getStatus(profileToken)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetStatusResponse.fromJson(
      responseEnvelope.body.response!,
    ).ptzStatus;
  }

  /// Operation to move the PTZ device to it's "home" position. The operation is
  /// supported if the HomeSupported element in the PTZNode is true.
  ///
  /// ACCESS CLASS: ACTUATE
  Future<bool> gotoHomePosition(String profileToken, {PtzSpeed? speed}) async {
    loggy.debug('gotoHomePosition');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: PtzRequest.gotoHomePosition(profileToken, speed: speed),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// Operation to go to a saved preset position for the [Preset] in the
  /// selected profile. The operation is supported if there is support for at
  /// least one PTZ preset by the [Preset].
  ///
  /// ACCESS CLASS: ACTUATE
  Future<bool> gotoPreset(
    String profileToken, {
    required String presetToken,
    PtzSpeed? speed,
  }) async {
    loggy.debug('gotoPreset');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: PtzRequest.gotoPreset(
          profileToken,
          presetToken: presetToken,
          speed: speed,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// Helper method
  Future<void> move(
    String profileToken, {
    required Vector2D direction,
    Vector1D? zoom,
    BackupMove backupMove = BackupMove.continuous,
  }) async {
    loggy.debug('move');

    var zoomAdjust = zoom ?? Vector1D(x: 0);

    try {
      await relativeMove(
        profileToken,
        PtzVector(panTilt: direction, zoom: zoomAdjust),
        configurationCache[configurationCache.keys.first]?.defaultPtzSpeed,
      );
    } catch (err) {
      loggy.error('Relative move failed');

      loggy.error(err);

      loggy.error('Attempting workaround with $backupMove move');

      switch (backupMove) {
        case BackupMove.absolute:
          _simulateMoveWithAbsolute(profileToken, direction, zoom);

        case BackupMove.continuous:
          _simulateMoveWithContinuous(profileToken, direction, zoom);
      }
    }
  }

  Future<void> _simulateMoveWithContinuous(
    String profileToken,
    Vector2D direction,
    Vector1D? zoom,
  ) async {
    await continuousMove(
      profileToken,
      velocity: PtzSpeed(panTilt: direction, zoom: zoom ?? Vector1D(x: 0)),
    );

    Future.delayed(const Duration(milliseconds: 100), () async {
      await stop(profileToken);
    });
  }

  Future<void> _simulateMoveWithAbsolute(
    String profileToken,
    Vector2D direction,
    Vector1D? zoom,
  ) async {
    loggy.debug('Simulate Move - Absolute');

    Vector1D zoomAdjust = zoom ?? Vector1D(x: 0);

    Vector2D? panTilt;

    final ptzStatus = await getStatus(profileToken);

    if (ptzStatus.position.panTilt != null) {
      panTilt = Vector2D(
        x: _limitValue(
          ptzStatus.position.panTilt!.x,
          direction.x,
          defaultPanTiltLimits?.range.xRange.min ?? -1,
          defaultPanTiltLimits?.range.xRange.max ?? 1,
        ),
        y: _limitValue(
          ptzStatus.position.panTilt!.y,
          direction.y,
          defaultPanTiltLimits?.range.yRange.min ?? -1,
          defaultPanTiltLimits?.range.yRange.max ?? 1,
        ),
      );
    } else {
      panTilt = Vector2D(
        x: ptzStatus.position.panTilt!.x,
        y: ptzStatus.position.panTilt!.y,
      );
    }

    if (ptzStatus.position.zoom != null) {
      zoomAdjust = Vector1D(
        x: _limitValue(
          ptzStatus.position.zoom!.x,
          zoomAdjust.x,
          defaultZoomLimits?.range.xRange.min ?? 0,
          defaultZoomLimits?.range.xRange.max ?? 1,
        ),
      );
    }

    await absoluteMove(
      profileToken,
      position: PtzVector(panTilt: panTilt, zoom: zoomAdjust),
      speed: defaultSpeed,
    );
  }

  double _limitValue(double start, double value, double min, double max) =>
      value > 0 ? math.min(start + value, max) : math.max(start + value, min);

  /// A helper method to perform a single [step] of a [relativeMove] on the
  /// negative y axis (down)
  Future<void> moveDown(String profileToken, [double step = -0.025]) async {
    loggy.debug('moveDown');

    await move(profileToken, direction: Vector2D(y: step, x: 0));
  }

  /// A helper method to perform a single [step] of a [relativeMove] on the
  /// negative x axis (left)
  Future<void> moveLeft(String profileToken, [double step = -0.025]) async {
    loggy.debug('moveLeft');

    await move(profileToken, direction: Vector2D(x: step, y: 0));
  }

  /// A helper method to perform a single [step] of a [relativeMove] on the
  /// positive x axis (right)
  Future<void> moveRight(String profileToken, [double step = 0.025]) async {
    loggy.debug('moveRight');

    await move(profileToken, direction: Vector2D(x: step, y: 0));
  }

  /// A helper method to perform a single [step] of a [relativeMove] on the
  /// positive y axis (up)
  Future<void> moveUp(String profileToken, [double step = 0.025]) async {
    loggy.debug('moveUp');

    await move(profileToken, direction: Vector2D(y: step, x: 0));
  }

  /// Operation for Relative Pan/Tilt and Zoom Move. The operation is supported
  /// if the PTZNode supports at least one relative Pan/Tilt or Zoom space.
  ///
  /// The speed argument is optional. If an x/y speed value is given it is up to
  /// the device to either use the x value as absolute resulting speed vector or
  /// to map x and y to the component speed. If the speed argument is omitted,
  /// the default speed set by the [PtzConfiguration] will be used.
  ///
  /// ACCESS CLASS: ACTUATE
  Future<bool> relativeMove(
    String profileToken,
    PtzVector translation,
    PtzSpeed? speed,
  ) async {
    loggy.debug('relativeMove');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: PtzRequest.relativeMove(
          profileToken,
          translation: translation,
          speed: speed,
        ),
      ),
    );

    return responseEnvelope.body.response?.containsKey(
          'RelativeMoveResponse',
        ) ??
        false;
  }

  /// Operation to remove a PTZ preset for the Node in the selected profile. The
  /// operation is supported if the PresetPosition capability exists for the Node
  /// in the selected profile.
  ///
  /// ACCESS CLASS: ACTUATE
  Future<bool> removePreset(
    String profileToken, {
    required Preset preset,
  }) async {
    loggy.debug('removePreset');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: PtzRequest.removePreset(profileToken, preset: preset)),
    );

    return responseEnvelope.body.response?.containsKey(
          'RemovePresetResponse',
        ) ??
        false;
  }

  /// Operation to save current position as the home position. The
  /// SetHomePosition command returns with a failure if the “home” position is
  /// fixed and cannot be overwritten. If the SetHomePosition is successful, it
  /// is possible to recall the Home Position with the GotoHomePosition command.
  ///
  /// ACCESS CLASS: ACTUATE
  Future<bool> setHomePosition(String profileToken) async {
    loggy.debug('setHomePosition');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: PtzRequest.setHomePosition(profileToken)),
    );

    return responseEnvelope.body.response?.containsKey(
          'SetHomePositionResponse',
        ) ??
        false;
  }

  /// The [setPreset] command saves the current device position parameters so
  /// that the device can move to the saved preset position through the
  /// [gotoPreset] operation. In order to create a new [Preset], the
  /// SetPresetRequest contains no PresetToken. If creation is successful, the
  /// Response contains the PresetToken which uniquely identifies the Preset. An
  /// existing [Preset] can be overwritten by specifying the PresetToken of the
  /// corresponding [Preset]. In both cases (overwriting or creation) an
  /// optional PresetName can be specified. The operation fails if the PTZ
  /// device is moving during the [setPreset] operation. The device may
  /// internally save additional states such as imaging properties in the PTZ
  /// Preset which then should be recalled in the [gotoPreset] operation.
  ///
  /// ACCESS CLASS: ACTUATE
  Future<String> setPreset(
    String profileToken, {
    String? presetName,
    String? presetToken,
  }) async {
    loggy.debug('setPreset');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: PtzRequest.setPreset(
          profileToken,
          presetName: presetName,
          presetToken: presetToken,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return SetPresetResponse.fromJson(
      responseEnvelope.body.response!,
    ).presetToken;
  }

  /// Operation to stop ongoing pan, tilt and zoom movements of absolute
  /// relative and continuous type. If no stop argument for pan, tilt or zoom is
  /// set, the device will stop all ongoing pan, tilt and zoom movements.
  ///
  /// ACCESS CLASS: ACTUATE
  Future<bool> stop(
    String profileToken, {
    bool panTilt = true,
    bool zoom = true,
  }) async {
    loggy.debug('stop');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: PtzRequest.stop(profileToken, panTilt: panTilt, zoom: zoom),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return responseEnvelope.body.response?.containsKey('StopResponse') ?? false;
  }

  /// Helper method
  Future<void> zoom(String profileToken, Vector1D zoom) async {
    loggy.debug('zoom');

    await move(profileToken, direction: Vector2D(y: 0, x: 0), zoom: zoom);
  }

  /// A helper method to perform a single [step] of a [relativeMove] on the
  /// positive z axis (closer)
  Future<void> zoomIn(String profileToken, [double step = 0.025]) async {
    loggy.debug('zoomIn');

    await zoom(profileToken, Vector1D(x: step));
  }

  /// A helper method to perform a single [step] of a [relativeMove] on the
  /// negative y axis (farther)
  Future<void> zoomOut(String profileToken, [double step = 0.025]) async {
    loggy.debug('zoomOut');

    await zoom(profileToken, Vector1D(x: -step));
  }

  void _clearDefaults() {
    defaultSpeed = null;

    defaultPanTiltLimits = null;

    defaultZoomLimits = null;
  }

  Future<Preset?> getCurrentPreset(String profileToken) async {
    loggy.debug('getCurrentPreset');

    Preset? matchedPreset;

    final presets = await getPresets(profileToken);

    if (presets.first.position == null) {
      throw Exception(
        'Preset position is not available, the getCurrentPreset method can not be used on this device.',
      );
    }

    final ptzStatus = await getStatus(profileToken);

    for (var preset in presets) {
      if (_matchPositionSettings(preset, ptzStatus)) {
        matchedPreset = preset;

        break;
      }
    }

    return matchedPreset;
  }

  bool _matchValue(num right, num left) {
    return (right - left).abs() < 0.005 ||
        (right - (left > 0 ? left - 1 : left)).abs() < 0.0005;
  }

  bool _matchPositionSettings(Preset preset, PtzStatus ptzStatus) {
    bool matchX = _matchValue(
      preset.position!.panTilt!.x,
      ptzStatus.position.panTilt!.x,
    );

    bool matchY = _matchValue(
      preset.position!.panTilt!.y,
      ptzStatus.position.panTilt!.y,
    );

    bool matchZ = _matchValue(
      preset.position!.zoom!.x,
      ptzStatus.position.zoom!.x,
    );

    return matchX && matchY && matchZ;
  }

  static List<PtzConfiguration> ptzConfigurationConverter(dynamic json) {
    if (json == null) {
      return <PtzConfiguration>[];
    } else if (json is List) {
      return json
          .map((e) => PtzConfiguration.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [PtzConfiguration.fromJson(json as Map<String, dynamic>)];
  }
}
