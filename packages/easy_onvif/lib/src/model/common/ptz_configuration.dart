import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ptz_configuration.g.dart';

/// A specific PtzConfiguration from the device.
///
/// The default Position/Translation/Velocity Spaces are introduced to allow NVCs
/// sending move requests without the need to specify a certain coordinate
/// system. The default Speeds are introduced to control the speed of move
/// requests (absolute, relative, preset), where no explicit speed has been set.
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
/// specified limits, the PTZ unit has to move along the specified limits.
@JsonSerializable()
class PtzConfiguration {
  ///Token that uniquely references this configuration. Length up to 64
  ///characters.
  @JsonKey(name: '@token')
  final String token;

  ///User readable name. Length up to 64 characters.
  @JsonKey(name: 'Name', fromJson: OnvifUtil.stringMappedFromXml)
  final String name;

  ///Number of internal references currently using this configuration.
  ///This informational parameter is read-only. Deprecated for Media2 Service.
  @JsonKey(name: 'UseCount', fromJson: OnvifUtil.intMappedFromXml)
  final int useCount;

  ///The optional acceleration ramp used by the device when moving.
  @JsonKey(name: 'MoveRamp', fromJson: OnvifUtil.nullableIntMappedFromXml)
  final int? moveRamp;

  ///The optional acceleration ramp used by the device when recalling presets.
  @JsonKey(name: 'PresetRamp', fromJson: OnvifUtil.nullableIntMappedFromXml)
  final int? presetRamp;

  ///The optional acceleration ramp used by the device when executing
  ///PresetTours.
  @JsonKey(name: 'PresetTourRamp', fromJson: OnvifUtil.nullableIntMappedFromXml)
  final int? presetTourRamp;

  ///A mandatory reference to the PTZ Node that the PTZ Configuration belongs
  ///to.
  @JsonKey(name: 'NodeToken', fromJson: OnvifUtil.stringMappedFromXml)
  final String nodeToken;

  ///If the PTZ Node supports absolute Pan/Tilt movements, it shall specify one
  ///Absolute Pan/Tilt Position Space as default.
  @JsonKey(
    name: 'DefaultAbsolutePantTiltPositionSpace',
    fromJson: _nullableMappedToSpace,
  )
  final Space? defaultAbsolutePantTiltPositionSpace;

  ///If the PTZ Node supports absolute zoom movements, it shall specify one
  ///Absolute Zoom Position Space as default.
  @JsonKey(
    name: 'DefaultAbsoluteZoomPositionSpace',
    fromJson: _nullableMappedToSpace,
  )
  final Space? defaultAbsoluteZoomPositionSpace;

  ///If the PTZ Node supports relative Pan/Tilt movements, it shall specify one
  ///RelativePan/Tilt Translation Space as default.
  @JsonKey(
    name: 'DefaultRelativePanTiltTranslationSpace',
    fromJson: _nullableMappedToSpace,
  )
  final Space? defaultRelativePanTiltTranslationSpace;

  ///If the PTZ Node supports relative zoom movements, it shall specify one
  ///Relative Zoom Translation Space as default.
  @JsonKey(
    name: 'DefaultRelativeZoomTranslationSpace',
    fromJson: _nullableMappedToSpace,
  )
  final Space? defaultRelativeZoomTranslationSpace;

  ///If the PTZ Node supports continuous Pan/Tilt movements, it shall specify
  ///one Continuous Pan/Tilt Velocity Space as default.
  @JsonKey(
    name: 'DefaultContinuousPanTiltVelocitySpace',
    fromJson: _nullableMappedToSpace,
  )
  final Space? defaultContinuousPanTiltVelocitySpace;

  ///If the PTZ Node supports continuous zoom movements, it shall specify one
  ///Continuous Zoom Velocity Space as default.
  @JsonKey(
    name: 'DefaultContinuousZoomVelocitySpace',
    fromJson: _nullableMappedToSpace,
  )
  final Space? defaultContinuousZoomVelocitySpace;

  ///If the PTZ Node supports absolute or relative PTZ movements, it shall
  ///specify corresponding default Pan/Tilt and Zoom speeds.
  @JsonKey(name: 'PtzSpeed')
  final PtzSpeed? defaultPtzSpeed;

  ///If the PTZ Node supports continuous movements, it shall specify a default
  ///timeout, after which the movement stops.
  @JsonKey(
    name: 'DefaultPTZTimeout',
    fromJson: OnvifUtil.nullableStringMappedFromXml,
  )
  final String? defaultPtzTimeout;

  ///The Pan/Tilt limits element should be present for a PTZ Node that supports
  ///an absolute Pan/Tilt. If the element is present it signals the support for
  ///configurable Pan/Tilt limits. If limits are enabled, the Pan/Tilt movements
  ///shall always stay within the specified range. The Pan/Tilt limits are
  ///disabled by setting the limits to –INF or +INF.
  @JsonKey(name: 'PanTiltLimits')
  final PanTiltLimits? panTiltLimits;

  ///The Zoom limits element should be present for a PTZ Node that supports
  ///absolute zoom. If the element is present it signals the supports for
  ///configurable Zoom limits. If limits are enabled the zoom movements shall
  ///always stay within the specified range. The Zoom limits are disabled by
  ///settings the limits to -INF and +INF.
  @JsonKey(name: 'ZoomLimits')
  final ZoomLimits? zoomLimits;

  PtzConfiguration({
    required this.token,
    required this.name,
    required this.useCount,
    this.moveRamp,
    this.presetRamp,
    this.presetTourRamp,
    required this.nodeToken,
    this.defaultAbsolutePantTiltPositionSpace,
    this.defaultAbsoluteZoomPositionSpace,
    this.defaultRelativePanTiltTranslationSpace,
    this.defaultRelativeZoomTranslationSpace,
    this.defaultContinuousPanTiltVelocitySpace,
    this.defaultContinuousZoomVelocitySpace,
    this.defaultPtzSpeed,
    this.defaultPtzTimeout,
    this.panTiltLimits,
    this.zoomLimits,
  });

  factory PtzConfiguration.fromJson(Map<String, dynamic> json) =>
      _$PtzConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$PtzConfigurationToJson(this);

  @override
  String toString() => json.encode(toJson());

  static Space? _nullableMappedToSpace(Map<String, dynamic>? value) =>
      value != null
      ? $enumDecodeNullable(
          _$SpaceEnumMap,
          OnvifUtil.stringMappedFromXml(value),
        )
      : null;
}

// enum SearchState {
//   @JsonValue('Queued')
//   queued('Queued'),
//   @JsonValue('Searching')
//   searching('Searching'),
//   @JsonValue('Completed')
//   completed('Completed'),
//   @JsonValue('Unknown')
//   unknown('Unknown');

//   const SearchState(this.value);

//   final String value;
// }
