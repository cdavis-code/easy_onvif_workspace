// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ptz_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PtzConfiguration _$PtzConfigurationFromJson(
  Map<String, dynamic> json,
) => PtzConfiguration(
  token: json['@token'] as String,
  name: OnvifUtil.stringMappedFromXml(json['Name'] as Map<String, dynamic>),
  useCount: OnvifUtil.intMappedFromXml(
    json['UseCount'] as Map<String, dynamic>,
  ),
  moveRamp: OnvifUtil.nullableIntMappedFromXml(
    json['MoveRamp'] as Map<String, dynamic>?,
  ),
  presetRamp: OnvifUtil.nullableIntMappedFromXml(
    json['PresetRamp'] as Map<String, dynamic>?,
  ),
  presetTourRamp: OnvifUtil.nullableIntMappedFromXml(
    json['PresetTourRamp'] as Map<String, dynamic>?,
  ),
  nodeToken: OnvifUtil.stringMappedFromXml(
    json['NodeToken'] as Map<String, dynamic>,
  ),
  defaultAbsolutePantTiltPositionSpace: PtzConfiguration._nullableMappedToSpace(
    json['DefaultAbsolutePantTiltPositionSpace'] as Map<String, dynamic>?,
  ),
  defaultAbsoluteZoomPositionSpace: PtzConfiguration._nullableMappedToSpace(
    json['DefaultAbsoluteZoomPositionSpace'] as Map<String, dynamic>?,
  ),
  defaultRelativePanTiltTranslationSpace:
      PtzConfiguration._nullableMappedToSpace(
        json['DefaultRelativePanTiltTranslationSpace'] as Map<String, dynamic>?,
      ),
  defaultRelativeZoomTranslationSpace: PtzConfiguration._nullableMappedToSpace(
    json['DefaultRelativeZoomTranslationSpace'] as Map<String, dynamic>?,
  ),
  defaultContinuousPanTiltVelocitySpace:
      PtzConfiguration._nullableMappedToSpace(
        json['DefaultContinuousPanTiltVelocitySpace'] as Map<String, dynamic>?,
      ),
  defaultContinuousZoomVelocitySpace: PtzConfiguration._nullableMappedToSpace(
    json['DefaultContinuousZoomVelocitySpace'] as Map<String, dynamic>?,
  ),
  defaultPtzSpeed: json['PtzSpeed'] == null
      ? null
      : PtzSpeed.fromJson(json['PtzSpeed'] as Map<String, dynamic>),
  defaultPtzTimeout: OnvifUtil.nullableStringMappedFromXml(
    json['DefaultPTZTimeout'] as Map<String, dynamic>?,
  ),
  panTiltLimits: json['PanTiltLimits'] == null
      ? null
      : PanTiltLimits.fromJson(json['PanTiltLimits'] as Map<String, dynamic>),
  zoomLimits: json['ZoomLimits'] == null
      ? null
      : ZoomLimits.fromJson(json['ZoomLimits'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PtzConfigurationToJson(PtzConfiguration instance) =>
    <String, dynamic>{
      '@token': instance.token,
      'Name': instance.name,
      'UseCount': instance.useCount,
      'MoveRamp': instance.moveRamp,
      'PresetRamp': instance.presetRamp,
      'PresetTourRamp': instance.presetTourRamp,
      'NodeToken': instance.nodeToken,
      'DefaultAbsolutePantTiltPositionSpace':
          _$SpaceEnumMap[instance.defaultAbsolutePantTiltPositionSpace],
      'DefaultAbsoluteZoomPositionSpace':
          _$SpaceEnumMap[instance.defaultAbsoluteZoomPositionSpace],
      'DefaultRelativePanTiltTranslationSpace':
          _$SpaceEnumMap[instance.defaultRelativePanTiltTranslationSpace],
      'DefaultRelativeZoomTranslationSpace':
          _$SpaceEnumMap[instance.defaultRelativeZoomTranslationSpace],
      'DefaultContinuousPanTiltVelocitySpace':
          _$SpaceEnumMap[instance.defaultContinuousPanTiltVelocitySpace],
      'DefaultContinuousZoomVelocitySpace':
          _$SpaceEnumMap[instance.defaultContinuousZoomVelocitySpace],
      'PtzSpeed': instance.defaultPtzSpeed,
      'DefaultPTZTimeout': instance.defaultPtzTimeout,
      'PanTiltLimits': instance.panTiltLimits,
      'ZoomLimits': instance.zoomLimits,
    };

const _$SpaceEnumMap = {
  Space.zoomPositionGenericSpace:
      'http://www.onvif.org/ver10/tptz/ZoomSpaces/PositionGenericSpace',
  Space.zoomTranslationGenericSpace:
      'http://www.onvif.org/ver10/tptz/ZoomSpaces/TranslationGenericSpace',
  Space.zoomVelocityGenericSpace:
      'http://www.onvif.org/ver10/tptz/ZoomSpaces/VelocityGenericSpace',
  Space.zoomGenericSpeedSpace:
      'http://www.onvif.org/ver10/tptz/ZoomSpaces/GenericSpeedSpace',
  Space.panTiltPositionGenericSpace:
      'http://www.onvif.org/ver10/tptz/PanTiltSpaces/PositionGenericSpace',
  Space.panTiltTranslationGenericSpace:
      'http://www.onvif.org/ver10/tptz/PanTiltSpaces/TranslationGenericSpace',
  Space.panTiltVelocityGenericSpace:
      'http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace',
  Space.panTiltGenericSpeedSpace:
      'http://www.onvif.org/ver10/tptz/PanTiltSpaces/GenericSpeedSpace',
  Space.panTiltDigitalPositionSpace:
      'http://www.onvif.org/ver10/tptz/PanTiltSpaces/DigitalPositionSpace',
  Space.panTiltDigitalTranslationSpace:
      'http://www.onvif.org/ver10/tptz/PanTiltSpaces/DigitalTranslationSpace',
};
