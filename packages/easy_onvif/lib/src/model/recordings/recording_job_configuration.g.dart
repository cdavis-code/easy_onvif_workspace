// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_job_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordingJobConfiguration _$RecordingJobConfigurationFromJson(
  Map<String, dynamic> json,
) => RecordingJobConfiguration(
  scheduleToken: OnvifUtil.nullableStringMappedFromXml(
    json['ScheduleToken'] as Map<String, dynamic>?,
  ),
  recordingToken: OnvifUtil.stringMappedFromXml(
    json['RecordingToken'] as Map<String, dynamic>,
  ),
  mode: RecordingJobConfiguration._recordingJobConfiguration(json['Mode']),
  priority: OnvifUtil.intMappedFromXml(
    json['Priority'] as Map<String, dynamic>,
  ),
  source: json['Source'] == null
      ? null
      : RecordingJobSource.fromJson(json['Source'] as Map<String, dynamic>),
  extension: json['Extension'] as Map<String, dynamic>?,
  eventFilter: json['EventFilter'] == null
      ? null
      : RecordingEventFilter.fromJson(
          json['EventFilter'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$RecordingJobConfigurationToJson(
  RecordingJobConfiguration instance,
) => <String, dynamic>{
  'ScheduleToken': instance.scheduleToken,
  'RecordingToken': instance.recordingToken,
  'Mode': _$RecordingJobConfigurationModeEnumMap[instance.mode]!,
  'Priority': instance.priority,
  'Source': instance.source,
  'Extension': instance.extension,
  'EventFilter': instance.eventFilter,
};

const _$RecordingJobConfigurationModeEnumMap = {
  RecordingJobConfigurationMode.idle: 'Idle',
  RecordingJobConfigurationMode.active: 'Active',
};
