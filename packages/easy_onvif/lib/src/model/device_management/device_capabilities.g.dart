// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceCapabilities _$DeviceCapabilitiesFromJson(
  Map<String, dynamic> json,
) => DeviceCapabilities(
  xAddr: OnvifUtil.stringMappedFromXml(json['XAddr'] as Map<String, dynamic>),
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

Map<String, dynamic> _$DeviceCapabilitiesToJson(DeviceCapabilities instance) =>
    <String, dynamic>{
      'Network': instance.network,
      'System': instance.system,
      'IO': instance.io,
      'Security': instance.security,
      'Extension': instance.extension,
      'XAddr': instance.xAddr,
    };
