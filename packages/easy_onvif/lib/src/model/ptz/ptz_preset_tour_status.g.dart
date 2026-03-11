// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ptz_preset_tour_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PtzPresetTourStatus _$PtzPresetTourStatusFromJson(Map<String, dynamic> json) =>
    PtzPresetTourStatus(
      state: PtzPresetTourStatus._fix(json['State'] as Map<String, dynamic>),
      currentTourSpot: json['CurrentTourSpot'] == null
          ? null
          : PtzPresetTourSpot.fromJson(
              json['CurrentTourSpot'] as Map<String, dynamic>,
            ),
      extension: json['Extension'],
    );

Map<String, dynamic> _$PtzPresetTourStatusToJson(
  PtzPresetTourStatus instance,
) => <String, dynamic>{
  'State': _$PtzPresetTourStateEnumMap[instance.state]!,
  'CurrentTourSpot': instance.currentTourSpot,
  'Extension': instance.extension,
};

const _$PtzPresetTourStateEnumMap = {
  PtzPresetTourState.idle: 'Idle',
  PtzPresetTourState.touring: 'Touring',
  PtzPresetTourState.paused: 'Paused',
  PtzPresetTourState.extended: 'Extended',
};
