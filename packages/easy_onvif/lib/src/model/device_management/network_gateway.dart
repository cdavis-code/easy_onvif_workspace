import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'network_gateway.g.dart';

/// Default gateway addresses (tt:NetworkGateway).
@JsonSerializable()
class NetworkGateway {
  @JsonKey(name: 'IPv4Address', fromJson: _parseUnboundString)
  final List<String> ipv4Addresses;

  @JsonKey(name: 'IPv6Address', fromJson: _parseUnboundString)
  final List<String> ipv6Addresses;

  NetworkGateway({
    this.ipv4Addresses = const [],
    this.ipv6Addresses = const [],
  });

  factory NetworkGateway.fromJson(Map<String, dynamic> json) =>
      _$NetworkGatewayFromJson(json);

  Map<String, dynamic> toJson() => _$NetworkGatewayToJson(this);

  @override
  String toString() => json.encode(toJson());

  static List<String> _parseUnboundString(dynamic json) {
    if (json == null) return [];

    if (json is List) {
      return json
          .map((e) => OnvifUtil.stringMappedFromXml(e as Map<String, dynamic>))
          .toList();
    }

    return [OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>)];
  }
}

/// Response for the GetNetworkDefaultGateway operation.
@JsonSerializable()
class GetNetworkDefaultGatewayResponse {
  @JsonKey(name: 'NetworkGateway')
  final NetworkGateway networkGateway;

  GetNetworkDefaultGatewayResponse(this.networkGateway);

  factory GetNetworkDefaultGatewayResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$GetNetworkDefaultGatewayResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GetNetworkDefaultGatewayResponseToJson(this);

  @override
  String toString() => json.encode(toJson());
}
