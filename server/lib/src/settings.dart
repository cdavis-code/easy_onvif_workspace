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

/// What the video track streams: a camera, a display, or a test pattern.
enum VideoSourceKind { camera, display, test }

/// Which capture devices feed the stream, using raw platform identifiers
/// (camera name, CGDirectDisplayID, /dev/video0, dshow name, hw:1, …) passed
/// unmodified to the capture layer.
class MediaSettings {
  final VideoSourceKind videoSource;

  /// Raw platform identifier of the video device; empty = platform default.
  final String videoDevice;

  /// Audio streaming is opt-in.
  final bool audioEnabled;

  /// Raw platform identifier of the audio input; empty = default input.
  final String audioDevice;

  const MediaSettings({
    this.videoSource = VideoSourceKind.camera,
    this.videoDevice = '',
    this.audioEnabled = false,
    this.audioDevice = '',
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

  /// Which video/audio devices feed the live stream.
  final MediaSettings media;

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
    this.media = const MediaSettings(),
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
    final mediaMap = section('media');
    final videoMap = mediaMap['video'] is YamlMap
        ? mediaMap['video'] as YamlMap
        : const <Object?, Object?>{};
    final audioMap = mediaMap['audio'] is YamlMap
        ? mediaMap['audio'] as YamlMap
        : const <Object?, Object?>{};

    // A bare scalar like `firmware: 1` parses as int; coerce to String where
    // the target field is a String. Conversely `httpPort: "9080"` parses as
    // String; coerce numerics/bools too so quoting never crashes with a
    // TypeError — a bad value is a FormatException like any other parse error.
    String? text(Map<Object?, Object?> node, String key) {
      final value = node[key];

      return value == null ? null : '$value';
    }

    int? integer(Map<Object?, Object?> node, String key) {
      final value = node[key];

      if (value == null) return null;
      if (value is int) return value;

      return int.tryParse('$value') ??
          (throw FormatException('Settings key "$key" is not an integer: $value'));
    }

    double? decimal(Map<Object?, Object?> node, String key) {
      final value = node[key];

      if (value == null) return null;
      if (value is num) return value.toDouble();

      return double.tryParse('$value') ??
          (throw FormatException('Settings key "$key" is not a number: $value'));
    }

    bool flag(Map<Object?, Object?> node, String key, {required bool orElse}) {
      final value = node[key];

      if (value == null) return orElse;
      if (value is bool) return value;

      return switch ('$value'.toLowerCase()) {
        'true' => true,
        'false' => false,
        _ => throw FormatException('Settings key "$key" is not a boolean: $value'),
      };
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
        latitude: decimal(geo, 'lat')!,
        longitude: decimal(geo, 'lon')!,
        elevation: decimal(geo, 'elevation'),
      );
    }

    final sourceText = text(videoMap, 'source') ?? 'camera';
    final videoSource = switch (sourceText) {
      'camera' => VideoSourceKind.camera,
      'display' => VideoSourceKind.display,
      'test' => VideoSourceKind.test,
      _ => throw FormatException(
        'Settings key "source" is not one of camera|display|test: $sourceText',
      ),
    };

    return ServerSettings(
      config: ServerConfig(
        httpPort: integer(network, 'httpPort') ?? base.httpPort,
        rtspPort: integer(network, 'rtspPort') ?? base.rtspPort,
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
        recording: flag(servicesMap, 'recording', orElse: true),
        replay: flag(servicesMap, 'replay', orElse: true),
        search: flag(servicesMap, 'search', orElse: true),
        imaging: flag(servicesMap, 'imaging', orElse: true),
      ),
      recordingDirectory: text(recording, 'directory'),
      segmentSeconds: integer(recording, 'segmentSeconds') ?? 10,
      maxRetentionMinutes: integer(recording, 'maxRetentionMinutes'),
      imagingPresets: presets.isEmpty ? defaultImagingPresets : presets,
      geoFallback: geoFallback,
      media: MediaSettings(
        videoSource: videoSource,
        videoDevice: text(videoMap, 'device') ?? '',
        audioEnabled: flag(audioMap, 'enabled', orElse: false),
        audioDevice: text(audioMap, 'device') ?? '',
      ),
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
