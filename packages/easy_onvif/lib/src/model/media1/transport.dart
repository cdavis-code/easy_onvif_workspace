import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'transport.g.dart';

@JsonSerializable()
class Transport implements XmlSerializable {
  /// Defines the network protocol for streaming, either UDP=RTP/UDP,
  /// RTSP=RTP/RTSP/TCP or HTTP=RTP/RTSP/HTTP/TCP
  /// - enum { 'UDP', 'TCP', 'RTSP', 'HTTP' }
  @JsonKey(name: 'Protocol')
  final String protocol;

  Transport({required this.protocol});

  factory Transport.fromJson(Map<String, dynamic> json) =>
      _$TransportFromJson(json);

  Map<String, dynamic> toJson() => _$TransportToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Transport',
    String? namespace = Xmlns.tt,
  }) => builder.element(
    'Transport',
    nest: () {
      builder.namespaceUri(null, namespace!);

      builder.element(
        'Protocol',
        nest: () {
          builder.namespaceUri(null, namespace);

          builder.text(protocol);
        },
      );
    },
  );
}
