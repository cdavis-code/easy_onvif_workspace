import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'endpoint_reference.g.dart';

@JsonSerializable()
class EndpointReference {
  @JsonKey(name: 'Address', fromJson: _address)
  final String address;

  EndpointReference({required this.address});

  factory EndpointReference.fromJson(Map<String, dynamic> json) =>
      _$EndpointReferenceFromJson(json);

  Map<String, dynamic> toJson() => _$EndpointReferenceToJson(this);

  @override
  String toString() => json.encode(toJson());

  static String _address(dynamic json) {
    if (json is Map) {
      // json from XML
      return OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>);
    } else {
      // json from serialized object
      return json as String;
    }
  }
}
