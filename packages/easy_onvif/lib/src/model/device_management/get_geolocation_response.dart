import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'get_geolocation_response.g.dart';

@JsonSerializable()
class GetGeoLocationResponse {
  /// Contains the system log information.
  @JsonKey(name: 'SystemLog')
  final List<dynamic> locations;

  dynamic get location => locations.isNotEmpty ? locations.first : null;

  GetGeoLocationResponse({required this.locations});

  factory GetGeoLocationResponse.fromJson(Map<String, dynamic> json) =>
      _$GetGeoLocationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetGeoLocationResponseToJson(this);

  @override
  String toString() => json.encode(toJson());
}
