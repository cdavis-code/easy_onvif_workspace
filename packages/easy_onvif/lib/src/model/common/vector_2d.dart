import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'vector_2d.g.dart';

@JsonSerializable()
class Vector2D implements XmlSerializable {
  @JsonKey(name: '@x', fromJson: double.parse, toJson: OnvifUtil.asString)
  final double x;

  @JsonKey(name: '@y', fromJson: double.parse, toJson: OnvifUtil.asString)
  final double y;

  /// coordinate space selector
  @JsonKey(name: '@space')
  final Space? space;

  Vector2D({required this.x, required this.y, this.space});

  factory Vector2D.fromString({required String x, required String y}) =>
      Vector2D(x: double.parse(x), y: double.parse(y));

  factory Vector2D.fromDouble({required double x, required double y}) =>
      Vector2D(x: x, y: y);

  factory Vector2D.fromJson(Map<String, dynamic> json) =>
      _$Vector2DFromJson(json);

  Map<String, dynamic> toJson() => _$Vector2DToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Vector2D',
    String? namespace = Xmlns.tt,
  }) => builder.element(
    tag,
    nest: () {
      builder.namespaceUri(null, namespace!);

      builder.attribute('x', x);
      builder.attribute('y', y);

      if (space != null) {
        builder.attribute('space', space!.value);
      }
    },
  );
}

@JsonEnum(valueField: 'value')
enum Space {
  zoomPositionGenericSpace(
    'http://www.onvif.org/ver10/tptz/ZoomSpaces/PositionGenericSpace',
  ),
  zoomTranslationGenericSpace(
    'http://www.onvif.org/ver10/tptz/ZoomSpaces/TranslationGenericSpace',
  ),
  zoomVelocityGenericSpace(
    'http://www.onvif.org/ver10/tptz/ZoomSpaces/VelocityGenericSpace',
  ),
  zoomGenericSpeedSpace(
    'http://www.onvif.org/ver10/tptz/ZoomSpaces/GenericSpeedSpace',
  ),
  panTiltPositionGenericSpace(
    'http://www.onvif.org/ver10/tptz/PanTiltSpaces/PositionGenericSpace',
  ),
  panTiltTranslationGenericSpace(
    'http://www.onvif.org/ver10/tptz/PanTiltSpaces/TranslationGenericSpace',
  ),
  panTiltVelocityGenericSpace(
    'http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace',
  ),
  panTiltGenericSpeedSpace(
    'http://www.onvif.org/ver10/tptz/PanTiltSpaces/GenericSpeedSpace',
  ),
  panTiltDigitalPositionSpace(
    'http://www.onvif.org/ver10/tptz/PanTiltSpaces/DigitalPositionSpace',
  ),
  panTiltDigitalTranslationSpace(
    'http://www.onvif.org/ver10/tptz/PanTiltSpaces/DigitalTranslationSpace',
  );

  const Space(this.value);

  final String value;
}
