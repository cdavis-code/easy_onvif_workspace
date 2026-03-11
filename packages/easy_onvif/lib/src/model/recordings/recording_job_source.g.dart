// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_job_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordingJobSource _$RecordingJobSourceFromJson(Map<String, dynamic> json) =>
    RecordingJobSource(
      sourceToken: json['SourceToken'] == null
          ? null
          : SourceToken.fromJson(json['SourceToken'] as Map<String, dynamic>),
      autoCreateReceiver: OnvifUtil.nullableBoolMappedFromXml(
        json['AutoCreateReceiver'] as Map<String, dynamic>?,
      ),
      tracks: RecordingJobSource._fromJson(json['Tracks']),
      extension: json['Extension'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RecordingJobSourceToJson(RecordingJobSource instance) =>
    <String, dynamic>{
      'SourceToken': instance.sourceToken,
      'AutoCreateReceiver': instance.autoCreateReceiver,
      'Tracks': instance.tracks,
      'Extension': instance.extension,
    };
