import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'ptz_vector.g.dart';

/// A list of preset position.
@JsonSerializable(explicitToJson: true)
class PtzVector implements XmlSerializable {
  @JsonKey(name: 'PanTilt')
  final Vector2D? panTilt;

  @JsonKey(name: 'Zoom')
  final Vector1D? zoom;

  PtzVector({this.panTilt, this.zoom});

  factory PtzVector.fromJson(Map<String, dynamic> json) =>
      _$PtzVectorFromJson(json);

  Map<String, dynamic> toJson() => _$PtzVectorToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'PtzVector',
    String? namespace = Xmlns.tt,
  }) => builder.element(
    tag,
    nest: () {
      builder.namespaceUri(null, namespace!);

      panTilt?.buildXml(builder, tag: 'PanTilt');

      zoom?.buildXml(builder, tag: 'Zoom');
    },
  );
}
