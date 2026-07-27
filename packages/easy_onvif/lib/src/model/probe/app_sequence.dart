import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/src/soap/xmlns.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'app_sequence.g.dart';

@JsonSerializable()
class AppSequence implements XmlSerializable {
  @JsonKey(name: '@MessageNumber', fromJson: int.parse)
  final int messageNumber;

  @JsonKey(name: '@InstanceId', fromJson: int.parse)
  final int instanceId;

  AppSequence({required this.messageNumber, required this.instanceId});

  factory AppSequence.fromJson(Map<String, dynamic> json) =>
      _$AppSequenceFromJson(json);

  Map<String, dynamic> toJson() => _$AppSequenceToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'AppSequence',
    String? namespace,
  }) => builder.element(
    tag,
    namespaceUris: {'ws': Xmlns.ws},
    nest: () {
      builder.attribute('MessageNumber', messageNumber);

      builder.attribute('InstanceId', instanceId);
    },
  );
}
