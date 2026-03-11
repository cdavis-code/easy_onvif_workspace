// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaProfile _$MediaProfileFromJson(Map<String, dynamic> json) => MediaProfile(
  token: json['@token'] as String,
  fixed: OnvifUtil.nullableStringToBool(json['@fixed'] as String?),
  name: OnvifUtil.stringMappedFromXml(json['Name'] as Map<String, dynamic>),
  configurations: json['Configurations'] == null
      ? null
      : ConfigurationSet.fromJson(
          json['Configurations'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$MediaProfileToJson(MediaProfile instance) =>
    <String, dynamic>{
      '@token': instance.token,
      '@fixed': instance.fixed,
      'Name': instance.name,
      'Configurations': instance.configurations,
    };
