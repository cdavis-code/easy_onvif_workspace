import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'vector_1d.g.dart';

@JsonSerializable()
class Vector1D implements XmlSerializable {
  @JsonKey(name: '@x', fromJson: double.parse, toJson: OnvifUtil.asString)
  final double x;

  @JsonKey(name: '@space')
  final Space? space;

  Vector1D({required this.x, this.space});

  factory Vector1D.fromString({required String x}) =>
      Vector1D(x: double.parse(x));

  factory Vector1D.fromDouble(double x) => Vector1D(x: x);

  factory Vector1D.fromJson(Map<String, dynamic> json) =>
      _$Vector1DFromJson(json);

  Map<String, dynamic> toJson() => _$Vector1DToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Vector1D',
    String? namespace = Xmlns.tt,
  }) => builder.element(
    tag,
    nest: () {
      builder.namespaceUri(null, namespace!);

      builder.attribute('x', x);

      if (space != null) {
        builder.attribute('space', space!.value);
      }
    },
  );
}
