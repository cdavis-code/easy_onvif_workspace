// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_zero_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkZeroConfiguration _$NetworkZeroConfigurationFromJson(
  Map<String, dynamic> json,
) => NetworkZeroConfiguration(
  interfaceToken: OnvifUtil.stringMappedFromXml(
    json['InterfaceToken'] as Map<String, dynamic>,
  ),
  enabled: OnvifUtil.boolMappedFromXml(json['Enabled'] as Map<String, dynamic>),
  addresses: json['Addresses'] == null
      ? const []
      : NetworkZeroConfiguration._parseUnboundString(json['Addresses']),
);

Map<String, dynamic> _$NetworkZeroConfigurationToJson(
  NetworkZeroConfiguration instance,
) => <String, dynamic>{
  'InterfaceToken': instance.interfaceToken,
  'Enabled': instance.enabled,
  'Addresses': instance.addresses,
};

GetZeroConfigurationResponse _$GetZeroConfigurationResponseFromJson(
  Map<String, dynamic> json,
) => GetZeroConfigurationResponse(
  NetworkZeroConfiguration.fromJson(
    json['ZeroConfiguration'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$GetZeroConfigurationResponseToJson(
  GetZeroConfigurationResponse instance,
) => <String, dynamic>{'ZeroConfiguration': instance.zeroConfiguration};
