// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Envelope _$EnvelopeFromJson(Map<String, dynamic> json) => Envelope(
  header: json['Header'] == null
      ? null
      : Header.fromJson(json['Header'] as Map<String, dynamic>),
  body: Body.fromJson(json['Body'] as Map<String, dynamic>),
);
