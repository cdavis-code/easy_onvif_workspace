import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location_entity.g.dart';

/// Represents a geographic location with latitude, longitude, and optional elevation.
/// This is used by ONVIF GetGeoLocation response.
@JsonSerializable()
class LocationEntity {
  /// Location on earth.
  @JsonKey(name: 'GeoLocation')
  final GeoLocation? geoLocation;

  /// Orientation relative to earth.
  @JsonKey(name: 'GeoOrientation')
  final GeoOrientation? geoOrientation;

  /// Indoor location offset.
  @JsonKey(name: 'LocalLocation')
  final LocalLocation? localLocation;

  /// Indoor orientation offset.
  @JsonKey(name: 'LocalOrientation')
  final LocalOrientation? localOrientation;

  /// Entity type the entry refers to, use a value from the tt:Entity enumeration.
  @JsonKey(name: 'Entity', fromJson: OnvifUtil.nullableStringMappedFromXml)
  final String? entity;

  /// Optional entity token.
  @JsonKey(name: 'Token')
  final String? token;

  /// If this value is true the entity cannot be deleted.
  @JsonKey(name: '@Fixed', fromJson: OnvifUtil.nullableStringToBool)
  final bool? fixed;

  /// Optional reference to the XAddr of another devices DeviceManagement service.
  @JsonKey(name: 'GeoSource', fromJson: OnvifUtil.nullableStringMappedFromXml)
  final String? geoSource;

  /// If set the geo location is obtained internally.
  @JsonKey(name: '@AutoGeo', fromJson: OnvifUtil.nullableStringToBool)
  final bool? autoGeo;

  LocationEntity({
    this.geoLocation,
    this.geoOrientation,
    this.localLocation,
    this.localOrientation,
    this.entity,
    this.token,
    this.fixed,
    this.geoSource,
    this.autoGeo,
  });

  factory LocationEntity.fromJson(Map<String, dynamic> json) =>
      _$LocationEntityFromJson(json);

  Map<String, dynamic> toJson() => _$LocationEntityToJson(this);

  @override
  String toString() => json.encode(toJson());
}

@JsonSerializable()
class GeoLocation {
  /// East west location as angle.
  @JsonKey(name: 'lat', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? lat;

  /// North south location as angle.
  @JsonKey(name: 'lon', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? lon;

  /// Height in meters above sea level.
  @JsonKey(name: 'elevation', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? elevation;

  GeoLocation({this.lat, this.lon, this.elevation});

  factory GeoLocation.fromJson(Map<String, dynamic> json) =>
      _$GeoLocationFromJson(json);

  Map<String, dynamic> toJson() => _$GeoLocationToJson(this);

  @override
  String toString() => json.encode(toJson());
}

@JsonSerializable()
class GeoOrientation {
  /// Rotation around the X axis in degrees.
  @JsonKey(name: 'roll', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? roll;

  /// Rotation around the Y axis in degrees.
  @JsonKey(name: 'pitch', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? pitch;

  /// Rotation around the Z axis in degrees.
  @JsonKey(name: 'yaw', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? yaw;

  GeoOrientation({this.roll, this.pitch, this.yaw});

  factory GeoOrientation.fromJson(Map<String, dynamic> json) =>
      _$GeoOrientationFromJson(json);

  Map<String, dynamic> toJson() => _$GeoOrientationToJson(this);

  @override
  String toString() => json.encode(toJson());
}

@JsonSerializable()
class LocalLocation {
  /// East west location as angle.
  @JsonKey(name: 'x', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? x;

  /// North south location as angle.
  @JsonKey(name: 'y', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? y;

  /// Height in meters above sea level.
  @JsonKey(name: 'z', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? z;

  LocalLocation({this.x, this.y, this.z});

  factory LocalLocation.fromJson(Map<String, dynamic> json) =>
      _$LocalLocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocalLocationToJson(this);

  @override
  String toString() => json.encode(toJson());
}

@JsonSerializable()
class LocalOrientation {
  /// Rotation around the X axis in degrees.
  @JsonKey(name: 'pan', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? pan;

  /// Rotation around the Y axis in degrees.
  @JsonKey(name: 'tilt', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? tilt;

  /// Rotation around the Z axis in degrees.
  @JsonKey(name: 'roll', fromJson: OnvifUtil.nullableDoubleMappedFromXml)
  final double? roll;

  LocalOrientation({this.roll, this.tilt, this.pan});

  factory LocalOrientation.fromJson(Map<String, dynamic> json) =>
      _$LocalOrientationFromJson(json);

  Map<String, dynamic> toJson() => _$LocalOrientationToJson(this);

  @override
  String toString() => json.encode(toJson());
}
