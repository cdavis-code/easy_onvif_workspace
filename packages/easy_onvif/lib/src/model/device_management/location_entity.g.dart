// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationEntity _$LocationEntityFromJson(
  Map<String, dynamic> json,
) => LocationEntity(
  geoLocation: json['GeoLocation'] == null
      ? null
      : GeoLocation.fromJson(json['GeoLocation'] as Map<String, dynamic>),
  geoOrientation: json['GeoOrientation'] == null
      ? null
      : GeoOrientation.fromJson(json['GeoOrientation'] as Map<String, dynamic>),
  localLocation: json['LocalLocation'] == null
      ? null
      : LocalLocation.fromJson(json['LocalLocation'] as Map<String, dynamic>),
  localOrientation: json['LocalOrientation'] == null
      ? null
      : LocalOrientation.fromJson(
          json['LocalOrientation'] as Map<String, dynamic>,
        ),
  entity: OnvifUtil.nullableStringMappedFromXml(
    json['Entity'] as Map<String, dynamic>?,
  ),
  token: json['Token'] as String?,
  fixed: OnvifUtil.nullableStringToBool(json['@Fixed'] as String?),
  geoSource: OnvifUtil.nullableStringMappedFromXml(
    json['GeoSource'] as Map<String, dynamic>?,
  ),
  autoGeo: OnvifUtil.nullableStringToBool(json['@AutoGeo'] as String?),
);

Map<String, dynamic> _$LocationEntityToJson(LocationEntity instance) =>
    <String, dynamic>{
      'GeoLocation': instance.geoLocation,
      'GeoOrientation': instance.geoOrientation,
      'LocalLocation': instance.localLocation,
      'LocalOrientation': instance.localOrientation,
      'Entity': instance.entity,
      'Token': instance.token,
      '@Fixed': instance.fixed,
      'GeoSource': instance.geoSource,
      '@AutoGeo': instance.autoGeo,
    };

GeoLocation _$GeoLocationFromJson(Map<String, dynamic> json) => GeoLocation(
  lat: OnvifUtil.nullableDoubleMappedFromXml(
    json['lat'] as Map<String, dynamic>?,
  ),
  lon: OnvifUtil.nullableDoubleMappedFromXml(
    json['lon'] as Map<String, dynamic>?,
  ),
  elevation: OnvifUtil.nullableDoubleMappedFromXml(
    json['elevation'] as Map<String, dynamic>?,
  ),
);

Map<String, dynamic> _$GeoLocationToJson(GeoLocation instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lon': instance.lon,
      'elevation': instance.elevation,
    };

GeoOrientation _$GeoOrientationFromJson(Map<String, dynamic> json) =>
    GeoOrientation(
      roll: OnvifUtil.nullableDoubleMappedFromXml(
        json['roll'] as Map<String, dynamic>?,
      ),
      pitch: OnvifUtil.nullableDoubleMappedFromXml(
        json['pitch'] as Map<String, dynamic>?,
      ),
      yaw: OnvifUtil.nullableDoubleMappedFromXml(
        json['yaw'] as Map<String, dynamic>?,
      ),
    );

Map<String, dynamic> _$GeoOrientationToJson(GeoOrientation instance) =>
    <String, dynamic>{
      'roll': instance.roll,
      'pitch': instance.pitch,
      'yaw': instance.yaw,
    };

LocalLocation _$LocalLocationFromJson(
  Map<String, dynamic> json,
) => LocalLocation(
  x: OnvifUtil.nullableDoubleMappedFromXml(json['x'] as Map<String, dynamic>?),
  y: OnvifUtil.nullableDoubleMappedFromXml(json['y'] as Map<String, dynamic>?),
  z: OnvifUtil.nullableDoubleMappedFromXml(json['z'] as Map<String, dynamic>?),
);

Map<String, dynamic> _$LocalLocationToJson(LocalLocation instance) =>
    <String, dynamic>{'x': instance.x, 'y': instance.y, 'z': instance.z};

LocalOrientation _$LocalOrientationFromJson(Map<String, dynamic> json) =>
    LocalOrientation(
      roll: OnvifUtil.nullableDoubleMappedFromXml(
        json['roll'] as Map<String, dynamic>?,
      ),
      tilt: OnvifUtil.nullableDoubleMappedFromXml(
        json['tilt'] as Map<String, dynamic>?,
      ),
      pan: OnvifUtil.nullableDoubleMappedFromXml(
        json['pan'] as Map<String, dynamic>?,
      ),
    );

Map<String, dynamic> _$LocalOrientationToJson(LocalOrientation instance) =>
    <String, dynamic>{
      'pan': instance.pan,
      'tilt': instance.tilt,
      'roll': instance.roll,
    };
