// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Capabilities _$CapabilitiesFromJson(Map<String, dynamic> json) => Capabilities(
  analytics: json['Analytics'] == null
      ? null
      : AnalyticsCapabilities.fromJson(
          json['Analytics'] as Map<String, dynamic>,
        ),
  device: json['Device'] == null
      ? null
      : DeviceCapabilities.fromJson(json['Device'] as Map<String, dynamic>),
  events: json['Events'] == null
      ? null
      : EventCapabilities.fromJson(json['Events'] as Map<String, dynamic>),
  imaging: json['Imaging'] == null
      ? null
      : ImagingCapabilities.fromJson(json['Imaging'] as Map<String, dynamic>),
  mediaCapabilities: Capabilities._fromJson(json['Media']),
  ptz: json['PTZ'] == null
      ? null
      : PtzCapabilities.fromJson(json['PTZ'] as Map<String, dynamic>),
  extension: json['Extension'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$CapabilitiesToJson(Capabilities instance) =>
    <String, dynamic>{
      'Analytics': instance.analytics,
      'Device': instance.device,
      'Events': instance.events,
      'Imaging': instance.imaging,
      'Media': instance.mediaCapabilities,
      'PTZ': instance.ptz,
      'Extension': instance.extension,
    };
