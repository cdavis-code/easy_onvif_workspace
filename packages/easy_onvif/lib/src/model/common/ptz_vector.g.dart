// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ptz_vector.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PtzVector _$PtzVectorFromJson(Map<String, dynamic> json) => PtzVector(
  panTilt: json['PanTilt'] == null
      ? null
      : Vector2D.fromJson(json['PanTilt'] as Map<String, dynamic>),
  zoom: json['Zoom'] == null
      ? null
      : Vector1D.fromJson(json['Zoom'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PtzVectorToJson(PtzVector instance) => <String, dynamic>{
  'PanTilt': instance.panTilt?.toJson(),
  'Zoom': instance.zoom?.toJson(),
};
