// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_gateway.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkGateway _$NetworkGatewayFromJson(Map<String, dynamic> json) =>
    NetworkGateway(
      ipv4Addresses: json['IPv4Address'] == null
          ? const []
          : NetworkGateway._parseUnboundString(json['IPv4Address']),
      ipv6Addresses: json['IPv6Address'] == null
          ? const []
          : NetworkGateway._parseUnboundString(json['IPv6Address']),
    );

Map<String, dynamic> _$NetworkGatewayToJson(NetworkGateway instance) =>
    <String, dynamic>{
      'IPv4Address': instance.ipv4Addresses,
      'IPv6Address': instance.ipv6Addresses,
    };

GetNetworkDefaultGatewayResponse _$GetNetworkDefaultGatewayResponseFromJson(
  Map<String, dynamic> json,
) => GetNetworkDefaultGatewayResponse(
  NetworkGateway.fromJson(json['NetworkGateway'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetNetworkDefaultGatewayResponseToJson(
  GetNetworkDefaultGatewayResponse instance,
) => <String, dynamic>{'NetworkGateway': instance.networkGateway};
