import 'dart:io';

import 'package:yaml/yaml.dart';

import 'config.dart';
import 'hardware/hardware_adapter.dart';

/// Which optional ONVIF services this device advertises and serves.
class ServiceFlags {
  final bool recording;
  final bool replay;
  final bool search;
  final bool imaging;

  const ServiceFlags({
    this.recording = true,
    this.replay = true,
    this.search = true,
    this.imaging = true,
  });
}

/// A simulated imaging preset seeded from settings.
class ImagingPresetSetting {
  final String token;
  final String name;
  final String type;

  const ImagingPresetSetting({
    required this.token,
    required this.name,
    required this.type,
  });
}

/// Runtime settings for the ONVIF server, loaded from YAML.
///
/// Search order for [load]: explicit `path` argument, then
/// `~/.easy_onvif_server/settings.yaml`, then a caller-supplied fallback
/// (e.g. a bundled asset). Missing files and missing keys fall back to the
/// defaults baked into [ServerConfig].
class ServerSettings {
  final ServerConfig config;
  final ServiceFlags services;

  /// Recording storage directory. `null` means the caller picks a platform
  /// default (e.g. the system temp directory).
  final String? recordingDirectory;

  /// Length of each recorded segment before rotating to a new file.
  final int segmentSeconds;

  /// When set, recorded segments older than this are pruned on rotation.
  final int? maxRetentionMinutes;

  /// Presets served by the simulated Imaging service.
  final List<ImagingPresetSetting> imagingPresets;

  /// Fallback location for `GetGeoLocation` when the platform has no fix.
  final GeoLocation? geoFallback;

  static const defaultImagingPresets = [
    ImagingPresetSetting(
      token: 'ImagingPreset_1',
      name: 'Standard',
      type: 'Auto',
    ),
    ImagingPresetSetting(
      token: 'ImagingPreset_2',
      name: 'Low Light',
      type: 'LowLight',
    ),
  ];

  const ServerSettings({
    this.config = const ServerConfig(),
    this.services = const ServiceFlags(),
    this.recordingDirectory,
    this.segmentSeconds = 10,
    this.maxRetentionMinutes,
    this.imagingPresets = defaultImagingPresets,
    this.geoFallback,
  });

  /// Parses [yamlText]; empty/blank text yields all defaults. Throws
  /// [FormatException] on malformed YAML.
  factory ServerSettings.parse(
    String yamlText, {
    ServerConfig base = const ServerConfig(),
  }) {
    final Object? doc;

    try {
      doc = yamlText.trim().isEmpty ? null : loadYaml(yamlText);
    } on YamlException catch (error) {
      throw FormatException('Invalid settings YAML: $error');
    }

    final map = doc is YamlMap ? doc : const <Object?, Object?>{};

    Map<Object?, Object?> section(String key) {
      final value = map[key];

      return value is YamlMap ? value : const {};
    }

    final device = section('device');
    final network = section('network');
    final auth = section('auth');
    final servicesMap = section('services');
    final recording = section('recording');
    final imaging = section('imaging');
    final geo = section('geolocation');

    // A bare scalar like `firmware: 1` parses as int; coerce to String where
    // the target field is a String.
    String? text(Map<Object?, Object?> node, String key) {
      final value = node[key];

      return value == null ? null : '$value';
    }

    final presets = <ImagingPresetSetting>[];
    final presetList = imaging['presets'];

    if (presetList is YamlList) {
      for (final entry in presetList) {
        if (entry is YamlMap) {
          presets.add(
            ImagingPresetSetting(
              token: text(entry, 'token') ?? 'ImagingPreset_${presets.length + 1}',
              name: text(entry, 'name') ?? 'Preset ${presets.length + 1}',
              type: text(entry, 'type') ?? 'Auto',
            ),
          );
        }
      }
    }

    GeoLocation? geoFallback;

    if (geo['lat'] != null && geo['lon'] != null) {
      geoFallback = GeoLocation(
        latitude: (geo['lat'] as num).toDouble(),
        longitude: (geo['lon'] as num).toDouble(),
        elevation: (geo['elevation'] as num?)?.toDouble(),
      );
    }

    return ServerSettings(
      config: ServerConfig(
        httpPort: (network['httpPort'] as int?) ?? base.httpPort,
        rtspPort: (network['rtspPort'] as int?) ?? base.rtspPort,
        username: text(auth, 'username') ?? base.username,
        password: text(auth, 'password') ?? base.password,
        manufacturer: text(device, 'manufacturer') ?? base.manufacturer,
        model: text(device, 'model') ?? base.model,
        firmwareVersion: text(device, 'firmware') ?? base.firmwareVersion,
        serialNumber: text(device, 'serial') ?? base.serialNumber,
        hardwareId: text(device, 'hardwareId') ?? base.hardwareId,
        hostname: text(device, 'hostname') ?? base.hostname,
      ),
      services: ServiceFlags(
        recording: (servicesMap['recording'] as bool?) ?? true,
        replay: (servicesMap['replay'] as bool?) ?? true,
        search: (servicesMap['search'] as bool?) ?? true,
        imaging: (servicesMap['imaging'] as bool?) ?? true,
      ),
      recordingDirectory: text(recording, 'directory'),
      segmentSeconds: (recording['segmentSeconds'] as int?) ?? 10,
      maxRetentionMinutes: recording['maxRetentionMinutes'] as int?,
      imagingPresets: presets.isEmpty ? defaultImagingPresets : presets,
      geoFallback: geoFallback,
    );
  }

  /// Loads settings from disk. Tries [path] first (if given), then
  /// `~/.easy_onvif_server/settings.yaml`, then [fallbackYaml] (e.g. a bundled
  /// asset), then pure defaults.
  static Future<ServerSettings> load({
    String? path,
    String? fallbackYaml,
  }) async {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

    final candidates = [
      ?path,
      if (home != null) '$home/.easy_onvif_server/settings.yaml',
    ];

    for (final candidate in candidates) {
      final file = File(candidate);

      if (file.existsSync()) {
        return ServerSettings.parse(await file.readAsString());
      }
    }

    if (fallbackYaml != null) return ServerSettings.parse(fallbackYaml);

    return const ServerSettings();
  }
}
