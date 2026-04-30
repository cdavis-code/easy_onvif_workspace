import 'dart:convert';

import 'package:easy_onvif/recordings.dart' show RecordingSourceInformation;
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

import 'track_information.dart';

part 'recording_information.g.dart';

/// A RecordingInformation structure for each found recording matching the
/// search.
@JsonSerializable()
class RecordingInformation {
  @JsonKey(name: 'RecordingToken', fromJson: OnvifUtil.stringMappedFromXml)
  final String recordingToken;

  /// Information about the source of the recording. This gives a description of
  /// where the data in the recording comes from. Since a single recording is
  /// intended to record related material, there is just one source. It is
  /// indicates the physical location or the major data source for the
  /// recording. Currently the RecordingConfiguration cannot describe each
  /// individual data source.
  @JsonKey(name: 'Source')
  final RecordingSourceInformation source;

  @JsonKey(name: 'EarliestRecording', fromJson: OnvifUtil.mappedToStdDateTime)
  final DateTime? earliestRecording;

  @JsonKey(name: 'LatestRecording', fromJson: OnvifUtil.mappedToStdDateTime)
  final DateTime? latestRecording;

  @JsonKey(name: 'Content', fromJson: OnvifUtil.stringMappedFromXml)
  final String content;

  /// Basic information about the track. Note that a track may represent a
  /// single contiguous time span or consist of multiple slices.
  @JsonKey(name: 'Track', fromJson: _fromJson)
  final List<TrackInformation>? tracks;

  @JsonKey(name: 'RecordingStatus', fromJson: _recordingStatus)
  final RecordingStatus recordingStatus;

  RecordingInformation({
    required this.recordingToken,
    required this.source,
    this.earliestRecording,
    this.latestRecording,
    required this.content,
    this.tracks,
    required this.recordingStatus,
  });

  factory RecordingInformation.fromJson(Map<String, dynamic> json) =>
      _$RecordingInformationFromJson(json);

  Map<String, dynamic> toJson() => _$RecordingInformationToJson(this);

  @override
  String toString() => json.encode(toJson());

  static List<TrackInformation> _fromJson(dynamic json) =>
      OnvifUtil.jsonList<TrackInformation>(
        json,
        (json) => TrackInformation.fromJson(json as Map<String, dynamic>),
      );

  static RecordingStatus _recordingStatus(dynamic json) => $enumDecode(
    _$RecordingStatusEnumMap,
    OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>),
  );
}

enum RecordingStatus {
  @JsonValue('Initiated')
  initiated('Initiated'),
  @JsonValue('Recording')
  recording('Recording'),
  @JsonValue('Stopped')
  stopped('Stopped'),
  @JsonValue('Removing')
  removing('Removing'),
  @JsonValue('Removed')
  removed('Removed'),
  @JsonValue('Unknown')
  unknown('Unknown');

  const RecordingStatus(this.value);

  final String value;
}
