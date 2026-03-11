// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ptz_speed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PtzSpeed _$PtzSpeedFromJson(Map<String, dynamic> json) => PtzSpeed(
  panTilt: json['Capabilities'] == null
      ? null
      : Vector2D.fromJson(json['Capabilities'] as Map<String, dynamic>),
  zoom: json['zoom'] == null
      ? null
      : Vector1D.fromJson(json['zoom'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PtzSpeedToJson(PtzSpeed instance) => <String, dynamic>{
  'Capabilities': instance.panTilt,
  'zoom': instance.zoom,
};
