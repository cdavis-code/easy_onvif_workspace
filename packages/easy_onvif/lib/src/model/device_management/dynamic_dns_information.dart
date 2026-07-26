import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'dynamic_dns_information.g.dart';

/// Analytics capabilities
@JsonSerializable()
class DynamicDnsInformation {
  /// Analytics service URI.
  @JsonKey(name: 'Type')
  final DynamicDnsType type;

  /// DNS name.
  @JsonKey(name: 'Name')
  final String? name;

  /// Time to live.
  @JsonKey(name: 'TTL')
  final String? ttl;

  final dynamic extension;

  DynamicDnsInformation({
    required this.type,
    this.name,
    this.ttl,
    this.extension,
  });

  factory DynamicDnsInformation.fromJson(Map<String, dynamic> json) =>
      _$DynamicDnsInformationFromJson(json);

  Map<String, dynamic> toJson() => _$DynamicDnsInformationToJson(this);

  @override
  String toString() => json.encode(toJson());
}

enum DynamicDnsType {
  @JsonValue('NoUpdate')
  noUpdate('NoUpdate'),
  @JsonValue('ClientUpdates')
  clientUpdates('ClientUpdates'),
  @JsonValue('ServerUpdates')
  serverUpdates('ServerUpdates');

  /// The ONVIF wire value (e.g. `NoUpdate`).
  final String value;
  const DynamicDnsType(this.value);
}
