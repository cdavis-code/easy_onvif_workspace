// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imaging.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Imaging _$ImagingFromJson(Map<String, dynamic> json) => Imaging(
  backlightCompensation: json['BacklightCompensation'] == null
      ? null
      : BacklightCompensation.fromJson(
          json['BacklightCompensation'] as Map<String, dynamic>,
        ),
  brightness: OnvifUtil.nullableDoubleMappedFromXml(
    json['Brightness'] as Map<String, dynamic>?,
  ),
  colorSaturation: OnvifUtil.nullableDoubleMappedFromXml(
    json['ColorSaturation'] as Map<String, dynamic>?,
  ),
  contrast: OnvifUtil.nullableDoubleMappedFromXml(
    json['Contrast'] as Map<String, dynamic>?,
  ),
  exposure: json['Exposure'] == null
      ? null
      : Exposure.fromJson(json['Exposure'] as Map<String, dynamic>),
  focus: json['Focus'] == null
      ? null
      : Focus.fromJson(json['Focus'] as Map<String, dynamic>),
  irCutFilter: OnvifUtil.nullableStringMappedFromXml(
    json['IrCutFilter'] as Map<String, dynamic>?,
  ),
  sharpness: OnvifUtil.nullableDoubleMappedFromXml(
    json['Sharpness'] as Map<String, dynamic>?,
  ),
  wideDynamicRange: json['WideDynamicRange'] == null
      ? null
      : WideDynamicRange.fromJson(
          json['WideDynamicRange'] as Map<String, dynamic>,
        ),
  whiteBalance: json['WhiteBalance'] == null
      ? null
      : WhiteBalance.fromJson(json['WhiteBalance'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ImagingToJson(Imaging instance) => <String, dynamic>{
  'BacklightCompensation': instance.backlightCompensation,
  'Brightness': instance.brightness,
  'ColorSaturation': instance.colorSaturation,
  'Contrast': instance.contrast,
  'Exposure': instance.exposure,
  'Focus': instance.focus,
  'IrCutFilter': instance.irCutFilter,
  'Sharpness': instance.sharpness,
  'WideDynamicRange': instance.wideDynamicRange,
  'WhiteBalance': instance.whiteBalance,
};
