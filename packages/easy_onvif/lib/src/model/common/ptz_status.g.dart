// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ptz_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PtzStatus _$PtzStatusFromJson(Map<String, dynamic> json) => PtzStatus(
  position: PtzVector.fromJson(json['Position'] as Map<String, dynamic>),
  moveStatus: json['MoveStatus'] == null
      ? null
      : MoveStatus.fromJson(json['MoveStatus'] as Map<String, dynamic>),
  error: OnvifUtil.nullableStringMappedFromXml(
    json['Error'] as Map<String, dynamic>?,
  ),
  utcTime: OnvifUtil.nullableMappedToDateTime(
    json['UtcTime'] as Map<String, dynamic>?,
  ),
);

Map<String, dynamic> _$PtzStatusToJson(PtzStatus instance) => <String, dynamic>{
  'Position': instance.position,
  'MoveStatus': instance.moveStatus,
  'Error': instance.error,
  'UtcTime': instance.utcTime?.toIso8601String(),
};
