import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

import 'recording_event_filter.dart';
import 'recording_job_source.dart';

part 'recording_job_configuration.g.dart';

@JsonSerializable()
class RecordingJobConfiguration implements XmlSerializable {
  /// This attribute adds an additional requirement for activating the recording
  /// job. If this optional field is provided the job shall only record if the
  /// schedule exists and is active.
  @JsonKey(
    name: 'ScheduleToken',
    fromJson: OnvifUtil.nullableStringMappedFromXml,
  )
  final String? scheduleToken;

  /// Identifies the recording to which this job shall store the received data.
  @JsonKey(name: 'RecordingToken', fromJson: OnvifUtil.stringMappedFromXml)
  final String recordingToken;

  /// Identifies the recording to which this job shall store the received data.
  @JsonKey(name: 'Mode', fromJson: _recordingJobConfiguration)
  final RecordingJobConfigurationMode mode;

  /// List of recording jobs.
  @JsonKey(name: 'Priority', fromJson: OnvifUtil.intMappedFromXml)
  final int priority;

  /// Source of the recording.
  @JsonKey(name: 'Source')
  final RecordingJobSource? source;

  @JsonKey(name: 'Extension')
  final Map<String, dynamic>? extension;

  /// Optional filter defining on which event condition a recording job gets active.
  @JsonKey(name: 'EventFilter')
  final RecordingEventFilter? eventFilter;

  RecordingJobConfiguration({
    this.scheduleToken,
    required this.recordingToken,
    required this.mode,
    required this.priority,
    this.source,
    this.extension,
    this.eventFilter,
  });

  factory RecordingJobConfiguration.fromJson(Map<String, dynamic> json) =>
      _$RecordingJobConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$RecordingJobConfigurationToJson(this);

  @override
  String toString() => json.encode(toJson());

  static RecordingJobConfigurationMode _recordingJobConfiguration(
    dynamic json,
  ) => $enumDecode(
    _$RecordingJobConfigurationModeEnumMap,
    OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>),
  );

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'JobConfiguration',
    String? namespace = Xmlns.trc,
  }) => builder.element(
    tag,
    nest: () {
      builder.namespaceUri(null, namespace!);

      if (scheduleToken != null) {
        ReferenceToken(
          scheduleToken!,
        ).buildXml(builder, tag: 'ScheduleToken', namespace: Xmlns.trc);
      }

      ReferenceToken(
        recordingToken,
      ).buildXml(builder, tag: 'RecordingToken', namespace: Xmlns.trc);

      _$RecordingJobConfigurationModeEnumMap[mode]!.buildXml(
        builder,
        tag: 'Mode',
        namespace: Xmlns.trc,
      );

      priority.toString().buildXml(
        builder,
        tag: 'Priority',
        namespace: Xmlns.trc,
      );

      source?.buildXml(builder);

      eventFilter?.buildXml(builder);
    },
  );
}

enum RecordingJobConfigurationMode {
  @JsonValue('Idle')
  idle('Idle'),
  @JsonValue('Active')
  active('Active');

  const RecordingJobConfigurationMode(this.value);
  final String value;
}
