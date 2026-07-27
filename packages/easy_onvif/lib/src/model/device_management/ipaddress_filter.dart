import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

import 'prefixed_ipv4_ipaddress.dart';
import 'prefixed_ipv6_ipaddress.dart';

part 'ipaddress_filter.g.dart';

enum Type {
  @JsonValue('Allow')
  allow('Allow'),
  @JsonValue('Deny')
  deny('Deny');

  /// The ONVIF wire value (e.g. `Allow`).
  final String value;
  const Type(this.value);
}

@JsonSerializable()
class IpAddressFilter implements XmlSerializable {
  @JsonKey(name: 'Type', fromJson: _mappedToType)
  Type type;

  @JsonKey(name: 'IPv4Address', fromJson: _parseUnboundIpv4)
  List<PrefixedIpv4Address> prefixedIpv4Addresses;

  @JsonKey(name: 'IPv6Address', fromJson: _parseUnboundIpv6)
  List<PrefixedIpv6Address> prefixedIpv6Addresses;

  @JsonKey(name: 'Extension')
  Map<String, dynamic>? extension;

  IpAddressFilter({
    required this.type,
    required this.prefixedIpv4Addresses,
    required this.prefixedIpv6Addresses,
    this.extension,
  });

  factory IpAddressFilter.fromJson(Map<String, dynamic> json) =>
      _$IpAddressFilterFromJson(json);

  Map<String, dynamic> toJson() => _$IpAddressFilterToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'SetIPAddressFilter',
    String? namespace = Xmlns.tds,
  }) => builder.element(
    tag,
    nest: () {
      builder.namespaceUri(null, namespace!);

      type.value.buildXml(builder, tag: 'Type');

      if (prefixedIpv4Addresses.isNotEmpty) {
        for (var address in prefixedIpv4Addresses) {
          address.buildXml(builder, tag: 'IPv4Address');
        }
      }

      if (prefixedIpv6Addresses.isNotEmpty) {
        for (var address in prefixedIpv6Addresses) {
          address.buildXml(builder, tag: 'IPv6Address');
        }
      }
    },
  );

  static Type _mappedToType(Map<String, dynamic> value) =>
      Type.values.byName(OnvifUtil.stringMappedFromXml(value).toLowerCase());

  static List<PrefixedIpv4Address> _parseUnboundIpv4(dynamic json) {
    if (json == null) return [];

    if (json is List) {
      return json
          .map((e) => PrefixedIpv4Address.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [PrefixedIpv4Address.fromJson(json as Map<String, dynamic>)];
  }

  static List<PrefixedIpv6Address> _parseUnboundIpv6(dynamic json) {
    if (json == null) return [];

    if (json is List) {
      return json
          .map((e) => PrefixedIpv6Address.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [PrefixedIpv6Address.fromJson(json as Map<String, dynamic>)];
  }
}
