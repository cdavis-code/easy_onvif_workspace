// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ptz_configuration_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PtzConfigurationOptions _$PtzConfigurationOptionsFromJson(
  Map<String, dynamic> json,
) => PtzConfigurationOptions(
  ptzRamps: OnvifUtil.nullableIntMappedFromXmlList(json['PTZRamps'] as String?),
  spaces: PtzSpaces.fromJson(json['Spaces'] as Map<String, dynamic>),
  ptzTimeout: DurationRange.fromJson(
    json['PTZTimeout'] as Map<String, dynamic>,
  ),
  ptControlDirection: json['PTControlDirection'] == null
      ? null
      : PtControlDirectionOptions.fromJson(
          json['PTControlDirection'] as Map<String, dynamic>,
        ),
  extension: json['Extension'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PtzConfigurationOptionsToJson(
  PtzConfigurationOptions instance,
) => <String, dynamic>{
  'PTZRamps': instance.ptzRamps,
  'Spaces': instance.spaces,
  'PTZTimeout': instance.ptzTimeout,
  'PTControlDirection': instance.ptControlDirection,
  'Extension': instance.extension,
};
