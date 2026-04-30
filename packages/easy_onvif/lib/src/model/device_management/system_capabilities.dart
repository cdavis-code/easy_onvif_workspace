import 'dart:convert';

import 'package:easy_onvif/src/util/util.dart';
import 'package:json_annotation/json_annotation.dart';

import 'system_capabilities_extension.dart';
import 'version.dart';

part 'system_capabilities.g.dart';

/// System capabilities.
@JsonSerializable()
class SystemCapabilities {
  /// Indicates support for WS Discovery resolve requests.
  @JsonKey(name: 'DiscoveryResolve', fromJson: _complexBool)
  final bool discoveryResolve;

  /// Indicates support for WS-Discovery Bye.
  @JsonKey(name: 'DiscoveryBye', fromJson: _complexBool)
  final bool discoveryBye;

  /// Indicates support for remote discovery.
  @JsonKey(name: 'RemoteDiscovery', fromJson: _complexBool)
  final bool remoteDiscovery;

  /// Indicates support for system backup through MTOM.
  @JsonKey(name: 'SystemBackup', fromJson: _complexBool)
  final bool systemBackup;

  /// Indicates support for retrieval of system logging through MTOM.
  @JsonKey(name: 'SystemLogging', fromJson: _complexBool)
  final bool systemLogging;

  /// Indicates support for firmware upgrade through MTOM.
  @JsonKey(name: 'FirmwareUpgrade', fromJson: _complexBool)
  final bool firmwareUpgrade;

  /// Indicates supported ONVIF version(s).
  @JsonKey(name: 'SupportedVersions', fromJson: _fromJson)
  final List<Version>? supportedVersions;

  @JsonKey(name: 'Extension')
  final SystemCapabilitiesExtension? extension;

  SystemCapabilities({
    required this.discoveryResolve,
    required this.discoveryBye,
    required this.remoteDiscovery,
    required this.systemBackup,
    required this.systemLogging,
    required this.firmwareUpgrade,
    required this.supportedVersions,
    this.extension,
  });

  factory SystemCapabilities.fromJson(Map<String, dynamic> json) =>
      _$SystemCapabilitiesFromJson(<String, dynamic>{
        for (var key in json.keys) key.replaceFirst('@', ''): json[key]!,
      });

  Map<String, dynamic> toJson() => _$SystemCapabilitiesToJson(this);

  @override
  String toString() => json.encode(toJson());

  static bool _complexBool(dynamic value) => value is String
      ? OnvifUtil.stringToBool(value)
      : OnvifUtil.boolMappedFromXml(value as Map<String, dynamic>);

  static List<Version> _fromJson(dynamic json) => OnvifUtil.jsonList<Version>(
    json,
    (json) => Version.fromJson(json as Map<String, dynamic>),
  );
}
