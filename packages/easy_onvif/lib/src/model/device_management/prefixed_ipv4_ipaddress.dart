import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

import 'prefixed_ipaddress.dart';

part 'prefixed_ipv4_ipaddress.g.dart';

@JsonSerializable()
class PrefixedIpv4Address extends PrefixedIpAddress implements XmlSerializable {
  @JsonKey(name: 'Address')
  final String address;

  PrefixedIpv4Address({required this.address, required super.prefixLength});

  factory PrefixedIpv4Address.fromJson(Map<String, dynamic> json) =>
      _$PrefixedIpv4AddressFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PrefixedIpv4AddressToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'IPv4Address',
    String? namespace = Xmlns.tds,
  }) => builder.element(
    tag,
    nest: () {
      builder.namespaceUri(null, namespace!);

      address.buildXml(builder, tag: 'Address');

      prefixLength.toString().buildXml(builder, tag: 'PrefixLength');
    },
  );
}
