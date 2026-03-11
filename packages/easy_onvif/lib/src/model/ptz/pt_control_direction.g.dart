// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pt_control_direction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PtControlDirectionOptions _$PtControlDirectionOptionsFromJson(
  Map<String, dynamic> json,
) => PtControlDirectionOptions(
  eFlip: json['EFlip'] == null
      ? null
      : ModalOptions.fromJson(json['EFlip'] as Map<String, dynamic>),
  reverse: json['Reverse'] == null
      ? null
      : ModalOptions.fromJson(json['Reverse'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PtControlDirectionOptionsToJson(
  PtControlDirectionOptions instance,
) => <String, dynamic>{'EFlip': instance.eFlip, 'Reverse': instance.reverse};
