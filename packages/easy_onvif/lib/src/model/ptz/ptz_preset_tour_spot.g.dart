// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ptz_preset_tour_spot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PtzPresetTourSpot _$PtzPresetTourSpotFromJson(Map<String, dynamic> json) =>
    PtzPresetTourSpot(
      presetDetail: json['PresetDetail'] as String,
      speed: json['Speed'] == null
          ? null
          : PtzSpeed.fromJson(json['Speed'] as Map<String, dynamic>),
      stayTime: json['StayTime'] as String?,
      extension: json['Extension'],
    );

Map<String, dynamic> _$PtzPresetTourSpotToJson(PtzPresetTourSpot instance) =>
    <String, dynamic>{
      'PresetDetail': instance.presetDetail,
      'Speed': instance.speed,
      'StayTime': instance.stayTime,
      'Extension': instance.extension,
    };
