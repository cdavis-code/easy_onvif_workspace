// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset_tour.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresetTour _$PresetTourFromJson(Map<String, dynamic> json) => PresetTour(
  token: json['@token'] as String,
  name: json['Name'] as String?,
  status: PtzPresetTourStatus.fromJson(json['Status'] as Map<String, dynamic>),
  autoStart: OnvifUtil.boolMappedFromXml(
    json['AutoStart'] as Map<String, dynamic>,
  ),
  startingCondition: PtzPresetTourStartingCondition.fromJson(
    json['StartingCondition'] as Map<String, dynamic>,
  ),
  tourSpot: json['TourSpot'] == null
      ? null
      : PtzPresetTourSpot.fromJson(json['TourSpot'] as Map<String, dynamic>),
  extension: json['Extension'],
);

Map<String, dynamic> _$PresetTourToJson(PresetTour instance) =>
    <String, dynamic>{
      '@token': instance.token,
      'Name': instance.name,
      'Status': instance.status,
      'AutoStart': instance.autoStart,
      'StartingCondition': instance.startingCondition,
      'TourSpot': instance.tourSpot,
      'Extension': instance.extension,
    };
