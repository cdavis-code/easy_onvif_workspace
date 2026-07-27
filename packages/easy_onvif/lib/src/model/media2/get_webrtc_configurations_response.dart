import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

import 'webrtc_configuration.dart';

part 'get_webrtc_configurations_response.g.dart';

/// Response for the GetWebRTCConfigurations operation.
@JsonSerializable()
class GetWebrtcConfigurationsResponse {
  /// The list of configured WebRTC configurations.
  @JsonKey(name: 'WebRTCConfiguration', fromJson: _fromJson)
  final List<WebrtcConfiguration> configurations;

  GetWebrtcConfigurationsResponse({required this.configurations});

  factory GetWebrtcConfigurationsResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$GetWebrtcConfigurationsResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GetWebrtcConfigurationsResponseToJson(this);

  @override
  String toString() => json.encode(toJson());

  static List<WebrtcConfiguration> _fromJson(dynamic json) =>
      OnvifUtil.jsonList<WebrtcConfiguration>(
        json,
        (json) => WebrtcConfiguration.fromJson(json as Map<String, dynamic>),
      );
}
