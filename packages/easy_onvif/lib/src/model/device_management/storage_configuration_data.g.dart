// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_configuration_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StorageConfigurationData _$StorageConfigurationDataFromJson(
  Map<String, dynamic> json,
) => StorageConfigurationData(
  type: json['@type'] as String,
  localPath: OnvifUtil.nullableStringMappedFromXml(
    json['LocalPath'] as Map<String, dynamic>?,
  ),
  storageUri: OnvifUtil.nullableStringMappedFromXml(
    json['StorageUri'] as Map<String, dynamic>?,
  ),
  user: json['User'] == null
      ? null
      : User.fromJson(json['User'] as Map<String, dynamic>),
  extension: json['Extension'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$StorageConfigurationDataToJson(
  StorageConfigurationData instance,
) => <String, dynamic>{
  '@type': instance.type,
  'LocalPath': instance.localPath,
  'StorageUri': instance.storageUri,
  'User': instance.user,
  'Extension': instance.extension,
};
