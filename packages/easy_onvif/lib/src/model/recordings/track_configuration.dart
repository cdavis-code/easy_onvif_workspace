import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'track_configuration.g.dart';

/// Configuration of the track.
@JsonSerializable()
class TrackConfiguration {
  /// Type of the track. It shall be equal to the strings “Video”, “Audio” or
  /// “Metadata”. The track shall only be able to hold data of that type.
  /// - enum { 'Video', 'Audio', 'Metadata', 'Extended' }
  @JsonKey(name: 'TrackType', fromJson: _trackType)
  final TrackType trackType;

  /// Informative description of the track.
  @JsonKey(name: 'Description', fromJson: OnvifUtil.stringMappedFromXml)
  final String description;

  TrackConfiguration({required this.trackType, required this.description});

  factory TrackConfiguration.fromJson(Map<String, dynamic> json) =>
      _$TrackConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$TrackConfigurationToJson(this);

  @override
  String toString() => json.encode(toJson());

  static TrackType _trackType(dynamic json) => $enumDecode(
    _$TrackTypeEnumMap,
    OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>),
  );
}

enum TrackType {
  @JsonValue("Video")
  video,
  @JsonValue("Audio")
  audio,
  @JsonValue("Metadata")
  metadata,
  @JsonValue("Extended")
  extended,
}
