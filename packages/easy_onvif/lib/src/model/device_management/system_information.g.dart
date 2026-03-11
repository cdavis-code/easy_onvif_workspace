// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_information.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemInformation _$SystemInformationFromJson(Map<String, dynamic> json) =>
    SystemInformation(
      binary: json['Binary'] == null
          ? null
          : AttachmentData.fromJson(json['Binary'] as Map<String, dynamic>),
      string: OnvifUtil.nullableStringMappedFromXml(
        json['String'] as Map<String, dynamic>?,
      ),
    );

Map<String, dynamic> _$SystemInformationToJson(SystemInformation instance) =>
    <String, dynamic>{'Binary': instance.binary, 'String': instance.string};
