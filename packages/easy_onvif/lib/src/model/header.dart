import 'dart:convert';

import 'package:easy_onvif/util.dart';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:easy_onvif/src/model/probe/app_sequence.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

import 'security.dart';

part 'header.g.dart';

@JsonSerializable()
class Header implements XmlSerializable {
  @JsonKey(includeFromJson: false)
  final Security? security;

  @JsonKey(name: 'AppSequence')
  final AppSequence? appSequence;

  @JsonKey(name: 'MessageID')
  final Map<String, dynamic>? mappedMessageID;

  @JsonKey(name: 'RelatesTo')
  final Map<String, dynamic>? mappedRelatesTo;

  @JsonKey(name: 'To')
  final Map<String, dynamic>? mappedTo;

  @JsonKey(name: 'Action')
  final Map<String, dynamic>? mappedAction;

  String? get messageID =>
      OnvifUtil.nullableStringMappedFromXml(mappedMessageID);

  String? get relatesTo =>
      OnvifUtil.nullableStringMappedFromXml(mappedRelatesTo);

  String? get to => OnvifUtil.nullableStringMappedFromXml(mappedTo);

  String? get action => OnvifUtil.nullableStringMappedFromXml(mappedAction);

  Header({
    this.security,
    this.appSequence,
    this.mappedMessageID,
    this.mappedRelatesTo,
    this.mappedTo,
    this.mappedAction,
  });

  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);

  Map<String, dynamic> toJson() => _$HeaderToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Header',
    String? namespace = Xmlns.s,
  }) {
    builder.element(
      tag,
      namespaceUri: namespace,
      nest: () {
        security?.buildXml(builder);

        appSequence?.buildXml(builder);

        messageID?.buildXml(builder, tag: 'MessageID');

        relatesTo?.buildXml(builder, tag: 'RelatesTo');

        to?.buildXml(builder, tag: 'To');

        action?.buildXml(builder, tag: 'Action');
      },
    );
  }
}
