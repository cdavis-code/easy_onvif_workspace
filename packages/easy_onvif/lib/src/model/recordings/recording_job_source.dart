import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';
import 'source_token.dart';
import 'track.dart';

part 'recording_job_source.g.dart';

/// Source of the recording.
@JsonSerializable()
class RecordingJobSource implements XmlSerializable {
  /// This field shall be a reference to the source of the data. The type of the
  /// source is determined by the attribute Type in the SourceToken structure.
  /// If Type is http://www.onvif.org/ver10/schema/Receiver, the token is a
  /// ReceiverReference. In this case the device shall receive the data over the
  /// network. If Type is http://www.onvif.org/ver10/schema/Profile, the token
  /// identifies a media profile, instructing the device to obtain data from a
  /// profile that exists on the local device.
  @JsonKey(name: 'SourceToken')
  final SourceToken? sourceToken;

  /// If this field is TRUE, and if the SourceToken is omitted, the device shall
  /// create a receiver object (through the receiver service) and assign the
  /// ReceiverReference to the SourceToken field. When retrieving the
  /// RecordingJobConfiguration from the device, the AutoCreateReceiver field
  /// shall never be present.
  @JsonKey(
    name: 'AutoCreateReceiver',
    fromJson: OnvifUtil.nullableBoolMappedFromXml,
  )
  final bool? autoCreateReceiver;

  @JsonKey(name: 'Tracks', fromJson: _fromJson)
  final List<Track>? tracks;

  @JsonKey(name: 'Extension')
  final Map<String, dynamic>? extension;

  RecordingJobSource({
    this.sourceToken,
    this.autoCreateReceiver,
    this.tracks,
    this.extension,
  });

  factory RecordingJobSource.fromJson(Map<String, dynamic> json) =>
      _$RecordingJobSourceFromJson(json);

  Map<String, dynamic> toJson() => _$RecordingJobSourceToJson(this);

  @override
  String toString() => json.encode(toJson());

  static List<Track> _fromJson(dynamic json) => OnvifUtil.jsonList<Track>(
    json,
    (json) => Track.fromJson(json as Map<String, dynamic>),
  );

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Source',
    String? namespace = Xmlns.trc,
  }) => builder.element(
    tag,
    nest: () {
      builder.namespaceUri(null, namespace!);

      sourceToken?.buildXml(builder);

      if (autoCreateReceiver != null) {
        builder.element(
          'AutoCreateReceiver',
          nest: () {
            builder.namespaceUri(null, Xmlns.trc);
            builder.text(autoCreateReceiver! ? 'true' : 'false');
          },
        );
      }
    },
  );
}
