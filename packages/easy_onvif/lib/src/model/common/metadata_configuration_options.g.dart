// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_configuration_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetadataConfigurationOptions _$MetadataConfigurationOptionsFromJson(
  Map<String, dynamic> json,
) => MetadataConfigurationOptions(
  geoLocation: OnvifUtil.nullableStringToBool(json['@GeoLocation'] as String?),
  maxContentFilterSize: OnvifUtil.optionalInt(
    json['@MaxContentFilterSize'] as String?,
  ),
  ptzStatusFilterOptions: json['PTZStatusFilterOptions'] == null
      ? null
      : PtzStatusFilterOptions.fromJson(
          json['PTZStatusFilterOptions'] as Map<String, dynamic>,
        ),
  extension: json['Extension'] == null
      ? null
      : MetadataConfigurationOptionsExtension.fromJson(
          json['Extension'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$MetadataConfigurationOptionsToJson(
  MetadataConfigurationOptions instance,
) => <String, dynamic>{
  '@GeoLocation': instance.geoLocation,
  '@MaxContentFilterSize': instance.maxContentFilterSize,
  'PTZStatusFilterOptions': instance.ptzStatusFilterOptions,
  'Extension': instance.extension,
};
