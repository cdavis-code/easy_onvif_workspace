// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fault.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Fault _$FaultFromJson(Map<String, dynamic> json) => Fault(
  code: json['Code'] == null
      ? null
      : Code.fromJson(json['Code'] as Map<String, dynamic>),
  reason: json['Reason'] == null
      ? null
      : Reason.fromJson(json['Reason'] as Map<String, dynamic>),
  mappedNode: json['Node'] as Map<String, dynamic>?,
  mappedRole: json['Role'] as Map<String, dynamic>?,
  detail: json['Detail'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$FaultToJson(Fault instance) => <String, dynamic>{
  'Code': instance.code,
  'Reason': instance.reason,
  'Node': instance.mappedNode,
  'Role': instance.mappedRole,
  'Detail': instance.detail,
};
