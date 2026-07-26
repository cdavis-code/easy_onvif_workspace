import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

import 'relay_output_settings.dart';

part 'relay_output.g.dart';

/// A relay output (tt:RelayOutput): a DeviceEntity (token) with settings.
@JsonSerializable()
class RelayOutput {
  @JsonKey(name: '@token')
  final String token;

  @JsonKey(name: 'Properties')
  final RelayOutputSettings properties;

  RelayOutput({required this.token, required this.properties});

  factory RelayOutput.fromJson(Map<String, dynamic> json) =>
      _$RelayOutputFromJson(json);

  Map<String, dynamic> toJson() => _$RelayOutputToJson(this);

  @override
  String toString() => json.encode(toJson());
}

/// Response for the GetRelayOutputs operation.
@JsonSerializable()
class GetRelayOutputsResponse {
  @JsonKey(name: 'RelayOutputs', fromJson: _fromJson)
  final List<RelayOutput> relayOutputs;

  GetRelayOutputsResponse(this.relayOutputs);

  factory GetRelayOutputsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetRelayOutputsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetRelayOutputsResponseToJson(this);

  @override
  String toString() => json.encode(toJson());

  static List<RelayOutput> _fromJson(dynamic json) =>
      OnvifUtil.jsonList<RelayOutput>(
        json,
        (json) => RelayOutput.fromJson(json as Map<String, dynamic>),
      );
}
