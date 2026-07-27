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

  ServiceFlags copyWith({
    bool? recording,
    bool? replay,
    bool? search,
    bool? imaging,
  }) {
    return ServiceFlags(
      recording: recording ?? this.recording,
      replay: replay ?? this.replay,
      search: search ?? this.search,
      imaging: imaging ?? this.imaging,
    );
  }
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

  MediaSettings copyWith({
    VideoSourceKind? videoSource,
    String? videoDevice,
    bool? audioEnabled,
    String? audioDevice,
  }) {
    return MediaSettings(
      videoSource: videoSource ?? this.videoSource,
      videoDevice: videoDevice ?? this.videoDevice,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      audioDevice: audioDevice ?? this.audioDevice,
    );
  }
}

/// Runtime settings for the ONVIF server, edited in the app's settings screen
/// and persisted as JSON by `SettingsStore`.
///
/// The JSON schema mirrors the class structure (nested `device`, `network`,
/// `auth`, `services`, `recording`, `imaging`, `geolocation` and `media`
/// sections); missing keys fall back to the defaults baked into [ServerConfig].
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

  /// Sentinel distinguishing "not passed" from an explicit `null` for the
  /// nullable fields in [copyWith].
  static const _unset = Object();

  ServerSettings copyWith({
    ServerConfig? config,
    ServiceFlags? services,
    Object? recordingDirectory = _unset,
    int? segmentSeconds,
    Object? maxRetentionMinutes = _unset,
    List<ImagingPresetSetting>? imagingPresets,
    Object? geoFallback = _unset,
    MediaSettings? media,
  }) {
    return ServerSettings(
      config: config ?? this.config,
      services: services ?? this.services,
      recordingDirectory: identical(recordingDirectory, _unset)
          ? this.recordingDirectory
          : recordingDirectory as String?,
      segmentSeconds: segmentSeconds ?? this.segmentSeconds,
      maxRetentionMinutes: identical(maxRetentionMinutes, _unset)
          ? this.maxRetentionMinutes
          : maxRetentionMinutes as int?,
      imagingPresets: imagingPresets ?? this.imagingPresets,
      geoFallback: identical(geoFallback, _unset)
          ? this.geoFallback
          : geoFallback as GeoLocation?,
      media: media ?? this.media,
    );
  }

  /// Builds settings from decoded JSON; an empty map yields all defaults.
  /// Unknown keys are ignored; malformed values throw [FormatException].
  factory ServerSettings.fromJson(
    Map<String, Object?> json, {
    ServerConfig base = const ServerConfig(),
  }) {
    Map<String, Object?> section(String key) {
      final value = json[key];

      return value is Map ? value.cast<String, Object?>() : const {};
    }

    final device = section('device');
    final network = section('network');
    final auth = section('auth');
    final servicesMap = section('services');
    final recording = section('recording');
    final imaging = section('imaging');
    final geo = section('geolocation');
    final mediaMap = section('media');
    final videoMap = mediaMap['video'] is Map
        ? (mediaMap['video'] as Map).cast<String, Object?>()
        : const <String, Object?>{};
    final audioMap = mediaMap['audio'] is Map
        ? (mediaMap['audio'] as Map).cast<String, Object?>()
        : const <String, Object?>{};

    // Hand-edited JSON may quote numbers or booleans; coerce rather than
    // crashing with a TypeError — a bad value is a FormatException like any
    // other parse error.
    String? text(Map<String, Object?> node, String key) {
      final value = node[key];

      return value == null ? null : '$value';
    }

    int? integer(Map<String, Object?> node, String key) {
      final value = node[key];

      if (value == null) return null;
      if (value is int) return value;

      return int.tryParse('$value') ??
          (throw FormatException(
            'Settings key "$key" is not an integer: $value',
          ));
    }

    double? decimal(Map<String, Object?> node, String key) {
      final value = node[key];

      if (value == null) return null;
      if (value is num) return value.toDouble();

      return double.tryParse('$value') ??
          (throw FormatException(
            'Settings key "$key" is not a number: $value',
          ));
    }

    bool flag(Map<String, Object?> node, String key, {required bool orElse}) {
      final value = node[key];

      if (value == null) return orElse;
      if (value is bool) return value;

      return switch ('$value'.toLowerCase()) {
        'true' => true,
        'false' => false,
        _ => throw FormatException(
          'Settings key "$key" is not a boolean: $value',
        ),
      };
    }

    final presets = <ImagingPresetSetting>[];
    final presetList = imaging['presets'];

    if (presetList is List) {
      for (final entry in presetList) {
        if (entry is Map) {
          final preset = entry.cast<String, Object?>();

          presets.add(
            ImagingPresetSetting(
              token:
                  text(preset, 'token') ??
                  'ImagingPreset_${presets.length + 1}',
              name: text(preset, 'name') ?? 'Preset ${presets.length + 1}',
              type: text(preset, 'type') ?? 'Auto',
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

  /// Serializes to the same nested-section shape [fromJson] reads, keeping
  /// the persisted file readable if opened by hand.
  Map<String, Object?> toJson() {
    return {
      'device': {
        'manufacturer': config.manufacturer,
        'model': config.model,
        'firmware': config.firmwareVersion,
        'serial': config.serialNumber,
        'hardwareId': config.hardwareId,
        'hostname': config.hostname,
      },
      'network': {'httpPort': config.httpPort, 'rtspPort': config.rtspPort},
      'auth': {'username': config.username, 'password': config.password},
      'services': {
        'recording': services.recording,
        'replay': services.replay,
        'search': services.search,
        'imaging': services.imaging,
      },
      'recording': {
        if (recordingDirectory != null) 'directory': recordingDirectory,
        'segmentSeconds': segmentSeconds,
        if (maxRetentionMinutes != null)
          'maxRetentionMinutes': maxRetentionMinutes,
      },
      'imaging': {
        'presets': [
          for (final preset in imagingPresets)
            {'token': preset.token, 'name': preset.name, 'type': preset.type},
        ],
      },
      if (geoFallback != null)
        'geolocation': {
          'lat': geoFallback!.latitude,
          'lon': geoFallback!.longitude,
          if (geoFallback!.elevation != null)
            'elevation': geoFallback!.elevation,
        },
      'media': {
        'video': {
          'source': media.videoSource.name,
          'device': media.videoDevice,
        },
        'audio': {'enabled': media.audioEnabled, 'device': media.audioDevice},
      },
    };
  }
}
