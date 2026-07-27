import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

import 'body.dart';
import 'header.dart';

part 'envelope.g.dart';

@JsonSerializable(createToJson: false)
class Envelope implements XmlSerializable {
  @JsonKey(name: 'Header')
  final Header? header;

  @JsonKey(name: 'Body')
  final Body body;

  Envelope({this.header, required this.body});

  factory Envelope.fromJson(Map<String, dynamic> json) =>
      _$EnvelopeFromJson(json);

  factory Envelope.fromXmlString(String xml) =>
      Envelope.fromJson(OnvifUtil.xmlToMap(xml));

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Envelope',
    String? namespace = Xmlns.s,
  }) => builder.element(
    'Envelope',
    namespaceUri: namespace,
    namespaceUris: {'s': Xmlns.s, 'a': 'http://www.w3.org/2005/08/addressing'},
    nest: () {
      header?.buildXml(builder);

      body.buildXml(builder);
    },
  );

  XmlDocument toXml(XmlBuilder builder) {
    builder.declaration(encoding: 'UTF-8');

    buildXml(builder);

    return builder.buildDocument();
  }
}
