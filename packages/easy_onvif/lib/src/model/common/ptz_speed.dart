import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'ptz_speed.g.dart';

/// If the PTZ Node supports absolute or relative PTZ movements, it shall specify
/// corresponding default Pan/Tilt and Zoom speeds.
@JsonSerializable()
class PtzSpeed implements XmlSerializable {
  /// Capability information.
  @JsonKey(name: 'Capabilities')
  final Vector2D? panTilt;
  final Vector1D? zoom;

  PtzSpeed({this.panTilt, this.zoom});

  factory PtzSpeed.fromJson(Map<String, dynamic> json) =>
      _$PtzSpeedFromJson(json);

  Map<String, dynamic> toJson() => _$PtzSpeedToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'PtzSpeed',
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
