// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_job_state_information.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordingJobStateInformation _$RecordingJobStateInformationFromJson(
  Map<String, dynamic> json,
) => RecordingJobStateInformation(
  recordingToken: OnvifUtil.stringMappedFromXml(
    json['RecordingToken'] as Map<String, dynamic>,
  ),
  state: OnvifUtil.stringMappedFromXml(json['State'] as Map<String, dynamic>),
  sources: RecordingJobStateInformation._fromJson(json['Sources']),
  tracks: json['Tracks'] == null
      ? null
      : Tracks.fromJson(json['Tracks'] as Map<String, dynamic>),
  extension: json['Extension'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$RecordingJobStateInformationToJson(
  RecordingJobStateInformation instance,
) => <String, dynamic>{
  'RecordingToken': instance.recordingToken,
  'State': instance.state,
  'Sources': instance.sources,
  'Tracks': instance.tracks,
  'Extension': instance.extension,
};
