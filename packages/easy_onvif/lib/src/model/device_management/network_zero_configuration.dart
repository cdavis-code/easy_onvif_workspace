import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'network_zero_configuration.g.dart';

/// Zero-configuration settings (tt:NetworkZeroConfiguration).
@JsonSerializable()
class NetworkZeroConfiguration {
  @JsonKey(name: 'InterfaceToken', fromJson: OnvifUtil.stringMappedFromXml)
  final String interfaceToken;

  @JsonKey(name: 'Enabled', fromJson: OnvifUtil.boolMappedFromXml)
  final bool enabled;

  @JsonKey(name: 'Addresses', fromJson: _parseUnboundString)
  final List<String> addresses;

  NetworkZeroConfiguration({
    required this.interfaceToken,
    required this.enabled,
    this.addresses = const [],
  });

  factory NetworkZeroConfiguration.fromJson(Map<String, dynamic> json) =>
      _$NetworkZeroConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$NetworkZeroConfigurationToJson(this);

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

/// Response for the GetZeroConfiguration operation.
@JsonSerializable()
class GetZeroConfigurationResponse {
  @JsonKey(name: 'ZeroConfiguration')
  final NetworkZeroConfiguration zeroConfiguration;

  GetZeroConfigurationResponse(this.zeroConfiguration);

  factory GetZeroConfigurationResponse.fromJson(Map<String, dynamic> json) =>
      _$GetZeroConfigurationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetZeroConfigurationResponseToJson(this);

  @override
  String toString() => json.encode(toJson());
}
