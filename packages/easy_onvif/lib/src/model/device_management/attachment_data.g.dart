// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentData _$AttachmentDataFromJson(Map<String, dynamic> json) =>
    AttachmentData(
      contentType: OnvifUtil.nullableStringMappedFromXml(
        json['contentType'] as Map<String, dynamic>?,
      ),
      include: json['Include'] == null
          ? null
          : Include.fromJson(json['Include'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttachmentDataToJson(AttachmentData instance) =>
    <String, dynamic>{
      'contentType': instance.contentType,
      'Include': instance.include,
    };
