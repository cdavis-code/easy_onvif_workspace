// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_service_capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceServiceCapabilities _$DeviceServiceCapabilitiesFromJson(
  Map<String, dynamic> json,
) => DeviceServiceCapabilities(
  network: json['Network'] == null
      ? null
      : NetworkCapabilities.fromJson(json['Network'] as Map<String, dynamic>),
  system: json['System'] == null
      ? null
      : SystemCapabilities.fromJson(json['System'] as Map<String, dynamic>),
  io: json['IO'] == null
      ? null
      : IoCapabilities.fromJson(json['IO'] as Map<String, dynamic>),
  security: json['Security'] == null
      ? null
      : SecurityCapabilities.fromJson(json['Security'] as Map<String, dynamic>),
  extension: json['Extension'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$DeviceServiceCapabilitiesToJson(
  DeviceServiceCapabilities instance,
) => <String, dynamic>{
  'Network': instance.network,
  'System': instance.system,
  'IO': instance.io,
  'Security': instance.security,
  'Extension': instance.extension,
};
