// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemCapabilities _$SystemCapabilitiesFromJson(
  Map<String, dynamic> json,
) => SystemCapabilities(
  discoveryResolve: SystemCapabilities._complexBool(json['DiscoveryResolve']),
  discoveryBye: SystemCapabilities._complexBool(json['DiscoveryBye']),
  remoteDiscovery: SystemCapabilities._complexBool(json['RemoteDiscovery']),
  systemBackup: SystemCapabilities._complexBool(json['SystemBackup']),
  systemLogging: SystemCapabilities._complexBool(json['SystemLogging']),
  firmwareUpgrade: SystemCapabilities._complexBool(json['FirmwareUpgrade']),
  supportedVersions: SystemCapabilities._fromJson(json['SupportedVersions']),
  extension: json['Extension'] == null
      ? null
      : SystemCapabilitiesExtension.fromJson(
          json['Extension'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SystemCapabilitiesToJson(SystemCapabilities instance) =>
    <String, dynamic>{
      'DiscoveryResolve': instance.discoveryResolve,
      'DiscoveryBye': instance.discoveryBye,
      'RemoteDiscovery': instance.remoteDiscovery,
      'SystemBackup': instance.systemBackup,
      'SystemLogging': instance.systemLogging,
      'FirmwareUpgrade': instance.firmwareUpgrade,
      'SupportedVersions': instance.supportedVersions,
      'Extension': instance.extension,
    };
