// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_system_uris_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetSystemUrisResponse _$GetSystemUrisResponseFromJson(
  Map<String, dynamic> json,
) => GetSystemUrisResponse(
  systemLogUris: json['SystemLogUris'] == null
      ? null
      : SystemLogUriList.fromJson(
          json['SystemLogUris'] as Map<String, dynamic>,
        ),
  supportInfoUri: OnvifUtil.nullableStringMappedFromXml(
    json['SupportInfoUri'] as Map<String, dynamic>?,
  ),
  systemBackupUri: OnvifUtil.nullableStringMappedFromXml(
    json['SystemBackupUri'] as Map<String, dynamic>?,
  ),
);

Map<String, dynamic> _$GetSystemUrisResponseToJson(
  GetSystemUrisResponse instance,
) => <String, dynamic>{
  'SystemLogUris': instance.systemLogUris,
  'SupportInfoUri': instance.supportInfoUri,
  'SystemBackupUri': instance.systemBackupUri,
};
