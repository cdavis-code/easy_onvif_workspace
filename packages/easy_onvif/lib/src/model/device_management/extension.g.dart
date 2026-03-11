// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extension.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Extension _$ExtensionFromJson(Map<String, dynamic> json) => Extension(
  dot11Configuration: OnvifUtil.nullableBoolMappedFromXml(
    json['Dot11Configuration'] as Map<String, dynamic>?,
  ),
  extension: json['Extension'] == null
      ? null
      : Extension.fromJson(json['Extension'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ExtensionToJson(Extension instance) => <String, dynamic>{
  'Dot11Configuration': instance.dot11Configuration,
  'Extension': instance.extension,
};
