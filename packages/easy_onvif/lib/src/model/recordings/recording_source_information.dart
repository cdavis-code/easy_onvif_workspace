import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'recording_source_information.g.dart';

/// Information about the source of the recording.
@JsonSerializable()
class RecordingSourceInformation implements XmlSerializable {
  /// Identifier for the source chosen by the client that creates the structure.
  /// This identifier is opaque to the device. Clients may use any type of URI
  /// for this field. A device shall support at least 128 characters.
  @JsonKey(name: 'SourceId', fromJson: OnvifUtil.stringMappedFromXml)
  final String sourceId;

  /// Informative user readable name of the source, e.g. "Camera23". A device
  /// shall support at least 20 characters.
  @JsonKey(name: 'Name', fromJson: OnvifUtil.stringMappedFromXml)
  final String name;

  /// Informative description of the physical location of the source, e.g. the
  /// coordinates on a map.
  @JsonKey(name: 'Location', fromJson: OnvifUtil.stringMappedFromXml)
  final String location;

  /// URI provided by the service supplying data to be recorded. A device shall
  /// support at least 128 characters.
  @JsonKey(name: 'Description', fromJson: OnvifUtil.stringMappedFromXml)
  final String description;

  /// Informative description of the physical location of the source, e.g. the
  /// coordinates on a map.
  @JsonKey(name: 'Address', fromJson: OnvifUtil.stringMappedFromXml)
  final String address;

  RecordingSourceInformation({
    required this.sourceId,
    required this.name,
    required this.location,
    required this.description,
    required this.address,
  });

  factory RecordingSourceInformation.fromJson(Map<String, dynamic> json) =>
      _$RecordingSourceInformationFromJson(json);

  Map<String, dynamic> toJson() => _$RecordingSourceInformationToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Source',
    String? namespace = Xmlns.tt,
  }) => Transport.builder.element(
    tag,
    nest: () {
      Transport.builder.namespaceUri(null, namespace!);

      sourceId.buildXml(Transport.builder, tag: 'SourceId');

      name.buildXml(Transport.builder, tag: 'Name');

      location.buildXml(Transport.builder, tag: 'Location');

      description.buildXml(Transport.builder, tag: 'Description');

      address.buildXml(Transport.builder, tag: 'Address');
    },
  );
}
