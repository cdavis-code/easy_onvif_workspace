// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetadataConfiguration _$MetadataConfigurationFromJson(
  Map<String, dynamic> json,
) => MetadataConfiguration(
  token: json['@token'] as String,
  name: OnvifUtil.stringMappedFromXml(json['Name'] as Map<String, dynamic>),
  useCount: OnvifUtil.intMappedFromXml(
    json['UseCount'] as Map<String, dynamic>,
  ),
  compressionType: json['CompressionType'] as String?,
  geoLocation: json['GeoLocation'] as bool?,
  shapePolygon: json['ShapePolygon'] as bool?,
  ptzStatus: json['PTZStatus'] == null
      ? null
      : PtzFilter.fromJson(json['PTZStatus'] as Map<String, dynamic>),
  events: json['Events'] == null
      ? null
      : Events.fromJson(json['Events'] as Map<String, dynamic>),
  analytics: OnvifUtil.nullableBoolMappedFromXml(
    json['Analytics'] as Map<String, dynamic>?,
  ),
  multicast: OnvifUtil.emptyOrMulticastConfiguration(
    json['Multicast'] as Map<String, dynamic>?,
  ),
  sessionTimeout: OnvifUtil.stringMappedFromXml(
    json['SessionTimeout'] as Map<String, dynamic>,
  ),
  analyticsEngineConfiguration:
      json['AnalyticsEngineConfiguration'] as Map<String, dynamic>?,
  extension: json['Extension'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$MetadataConfigurationToJson(
  MetadataConfiguration instance,
) => <String, dynamic>{
  '@token': instance.token,
  'Name': instance.name,
  'UseCount': instance.useCount,
  'CompressionType': instance.compressionType,
  'GeoLocation': instance.geoLocation,
  'ShapePolygon': instance.shapePolygon,
  'PTZStatus': instance.ptzStatus,
  'Events': instance.events,
  'Analytics': instance.analytics,
  'Multicast': instance.multicast,
  'SessionTimeout': instance.sessionTimeout,
  'AnalyticsEngineConfiguration': instance.analyticsEngineConfiguration,
  'Extension': instance.extension,
};
