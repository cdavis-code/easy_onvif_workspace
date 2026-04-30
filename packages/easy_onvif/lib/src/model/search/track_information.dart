import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'track_information.g.dart';

/// Basic information about the track. Note that a track may represent a single
/// contiguous time span or consist of multiple slices.
@JsonSerializable()
class TrackInformation {
  @JsonKey(name: 'TrackToken', fromJson: OnvifUtil.stringMappedFromXml)
  final String trackToken;

  /// Type of the track: "Video", "Audio" or "Metadata". The track shall only be
  /// able to hold data of that type.
  /// - enum { 'Video', 'Audio', 'Metadata', 'Extended' }
  @JsonKey(name: 'TrackType', fromJson: _trackType)
  final TrackType trackType;

  /// Informative description of the contents of the track.
  @JsonKey(name: 'Description', fromJson: OnvifUtil.stringMappedFromXml)
  final String description;

  /// The start date and time of the oldest recorded data in the track.
  @JsonKey(name: 'DataFrom', fromJson: OnvifUtil.mappedToStdDateTime)
  final DateTime dataFrom;

  /// The stop date and time of the newest recorded data in the track.
  @JsonKey(name: 'DataTo', fromJson: OnvifUtil.mappedToStdDateTime)
  final DateTime dataTo;

  TrackInformation({
    required this.trackToken,
    required this.trackType,
    required this.description,
    required this.dataFrom,
    required this.dataTo,
  });

  factory TrackInformation.fromJson(Map<String, dynamic> json) =>
      _$TrackInformationFromJson(json);

  Map<String, dynamic> toJson() => _$TrackInformationToJson(this);

  @override
  String toString() => json.encode(toJson());

  static TrackType _trackType(dynamic json) => $enumDecode(
    _$TrackTypeEnumMap,
    OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>),
  );
}

enum TrackType {
  @JsonValue('Video')
  video('Video'),
  @JsonValue('Audio')
  audio('Audio'),
  @JsonValue('Metadata')
  metadata('Metadata'),
  @JsonValue('Extended')
  extended('Extended');

  const TrackType(this.value);
  final String value;
}
