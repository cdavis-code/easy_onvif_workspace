import 'dart:convert';

import 'package:easy_onvif/soap.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'track.g.dart';

/// Track associated with the recording.
@JsonSerializable()
class Track {
  /// If the received RTSP stream contains multiple tracks of the same type, the
  /// SourceTag differentiates between those Tracks. This field can be ignored
  /// in case of recording a local source.
  @JsonKey(name: 'SourceTag', fromJson: OnvifUtil.stringMappedFromXml)
  final String sourceTag;

  /// Indicates the destination track.
  @JsonKey(name: 'Destination', fromJson: OnvifUtil.stringMappedFromXml)
  final String destination;

  /// Optionally holds an implementation defined string value that describes the
  /// error. The string should be in the English language.
  @JsonKey(name: 'Error', fromJson: OnvifUtil.nullableStringMappedFromXml)
  final String? error;

  /// Provides the job state of the track. The valid values of state shall be
  /// “Idle”, “Active” and “Error”. If state equals “Error”, the Error field may
  /// be filled in with an implementation defined value.
  @JsonKey(name: 'State', fromJson: _nullableRecordingJobState)
  final RecordingJobState? state;

  Track({
    required this.sourceTag,
    required this.destination,
    this.error,
    this.state,
  });

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);

  Map<String, dynamic> toJson() => _$TrackToJson(this);

  @override
  String toString() => json.encode(toJson());

  static RecordingJobState? _nullableRecordingJobState(dynamic json) =>
      json != null
      ? $enumDecode(
          _$RecordingJobStateEnumMap,
          OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>),
        )
      : null;

  void toXml() {
    Transport.builder.element(
      'Track',
      nest: () {
        Transport.builder.namespaceUri(null, Xmlns.tt);

        Transport.builder.element(
          'SourceTag',
          nest: () {
            Transport.builder.namespaceUri(null, Xmlns.tt);
            Transport.builder.text(sourceTag);
          },
        );

        Transport.builder.element(
          'Destination',
          nest: () {
            Transport.builder.namespaceUri(null, Xmlns.tt);
            Transport.builder.text(destination);
          },
        );
      },
    );
  }
}

enum RecordingJobState {
  @JsonValue('Idle')
  idle('Idle'),
  @JsonValue('Active')
  active('Active'),
  @JsonValue('Error')
  error('Error');

  const RecordingJobState(this.value);
  final String value;
}
