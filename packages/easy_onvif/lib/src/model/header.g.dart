// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'header.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Header _$HeaderFromJson(Map<String, dynamic> json) => Header(
  appSequence: json['AppSequence'] == null
      ? null
      : AppSequence.fromJson(json['AppSequence'] as Map<String, dynamic>),
  mappedMessageID: json['MessageID'] as Map<String, dynamic>?,
  mappedRelatesTo: json['RelatesTo'] as Map<String, dynamic>?,
  mappedTo: json['To'] as Map<String, dynamic>?,
  mappedAction: json['Action'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$HeaderToJson(Header instance) => <String, dynamic>{
  'AppSequence': instance.appSequence,
  'MessageID': instance.mappedMessageID,
  'RelatesTo': instance.mappedRelatesTo,
  'To': instance.mappedTo,
  'Action': instance.mappedAction,
};
