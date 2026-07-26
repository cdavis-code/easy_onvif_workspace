// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelayOutput _$RelayOutputFromJson(Map<String, dynamic> json) => RelayOutput(
  token: json['@token'] as String,
  properties: RelayOutputSettings.fromJson(
    json['Properties'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$RelayOutputToJson(RelayOutput instance) =>
    <String, dynamic>{
      '@token': instance.token,
      'Properties': instance.properties,
    };

GetRelayOutputsResponse _$GetRelayOutputsResponseFromJson(
  Map<String, dynamic> json,
) => GetRelayOutputsResponse(
  GetRelayOutputsResponse._fromJson(json['RelayOutputs']),
);

Map<String, dynamic> _$GetRelayOutputsResponseToJson(
  GetRelayOutputsResponse instance,
) => <String, dynamic>{'RelayOutputs': instance.relayOutputs};
