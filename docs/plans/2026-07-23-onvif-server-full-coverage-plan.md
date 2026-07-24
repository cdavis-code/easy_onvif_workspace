# ONVIF Server Full Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the simulated ONVIF device in `server/` to cover every operation in the easy_onvif README: real disk recording (Annex-B segments + JSON index), RTSP replay, search over real indexes, an Imaging service, remaining Device/Media gap operations, and a YAML settings file with per-service flags.

**Architecture:** New `lib/src/recording/` module taps the existing live `NalStreamSource` broadcast stream and writes keyframe-aligned `.h264` segments; `RtspServer` gains path routing so `/onvif/replay/<token>` sessions play a `FileH264Source` through the existing `RtpPacketizer`. New SOAP services (`trc`, `tse`, `trp`, `timg`) follow the existing `OnvifService` pattern with fixture-shaped `SoapEnvelopeBuilder` responses. A `ServerSettings` YAML loader drives `ServerConfig` and the service registry.

**Tech Stack:** Dart/Flutter, `package:yaml`, existing pure-Dart SOAP/RTSP/RTP stack, `flutter_test` integration tests using the real `easy_onvif` client, ffmpeg/ffprobe for stream verification in tests.

**Working branch:** `feature/server-full-onvif-coverage` (already created; `server/` committed at `0cf66da`). All paths below are relative to `/Users/chrisdavis/projects/my/easy_onvif_workspace/server/` unless prefixed with `packages/`.

**Design doc:** `docs/plans/2026-07-23-onvif-server-full-coverage-design.md`

**Conventions (match existing code):**
- Namespace constants from `package:easy_onvif/soap.dart` (`Xmlns.trc`, `Xmlns.tse`, `Xmlns.trp`, `Xmlns.timg`, `Xmlns.tt` all exist).
- Responses built with `SoapEnvelopeBuilder.response((b) {...})`; faults with `SoapEnvelopeBuilder.fault(subcode:, reason:)`.
- `SoapDispatcher` already faults `ActionNotSupported` for unregistered namespaces — disabling a service just means not registering it.
- Run all commands from the `server/` directory. Tests: `flutter test test/<file> `. Analysis: `flutter analyze`.
- Commit after every task with `git add <files> && git commit`.

---

## File Map

| File | Status | Responsibility |
|---|---|---|
| `pubspec.yaml` | modify | add `yaml` dep, `assets/settings.yaml` asset |
| `lib/src/settings.dart` | create | `ServerSettings`, `ServiceFlags`, YAML parsing/loading |
| `lib/src/config.dart` | modify | new service URLs, `endpointUuid`, replay RTSP URL |
| `lib/src/log_buffer.dart` | create | `BufferedLoggyPrinter` ring buffer for GetSystemLog |
| `lib/src/onvif_device.dart` | modify | settings-driven service registry, recording manager wiring |
| `lib/src/services/device_service.dart` | modify | 6 gap ops + flag-aware GetServices/GetCapabilities |
| `lib/src/services/media1_service.dart` | modify | GetMetadataConfiguration |
| `lib/src/services/media2_service.dart` | modify | 4 gap ops |
| `lib/src/services/imaging_service.dart` | create | `timg` service |
| `lib/src/services/recording_service.dart` | create | `trc` service |
| `lib/src/services/search_service.dart` | create | `tse` service |
| `lib/src/services/replay_service.dart` | create | `trp` service |
| `lib/src/hardware/device_state.dart` | modify | imaging preset state |
| `lib/src/streaming/stream_backend.dart` | modify | `nalSource` getter |
| `lib/src/streaming/ffmpeg_backend.dart` | modify | expose `nalSource` |
| `lib/src/streaming/camera_stream_backend.dart` | modify | expose `nalSource` |
| `lib/src/streaming/rtsp_server.dart` | modify | replay path routing, per-session sources, Range |
| `lib/src/streaming/file_h264_source.dart` | create | paced playback of recorded segments |
| `lib/src/recording/recording_index.dart` | create | `RecordingIndex`/`RecordingSegment` (+JSON) |
| `lib/src/recording/recording_store.dart` | create | directory management, load/create/delete/retention |
| `lib/src/recording/segment_recorder.dart` | create | live NAL tap → segment files |
| `lib/src/recording/recording_manager.dart` | create | recordings + jobs state machine |
| `lib/main.dart` | modify | settings load, recording status row |
| `assets/settings.yaml` | create | documented default settings |
| `test/settings_test.dart` | create | Task 1, 3 |
| `test/recording_store_test.dart` | create | Task 7, 8 |
| `test/recording_integration_test.dart` | create | Task 9 |
| `test/replay_integration_test.dart` | create | Task 10, 11 |
| `test/search_integration_test.dart` | create | Task 12 |
| `test/coverage_integration_test.dart` | create | Task 4, 5, 13 (device/media/imaging gaps) |

---

### Task 1: ServerSettings YAML loader

**Files:**
- Modify: `pubspec.yaml` (add `yaml: ^3.1.0` under `dependencies`)
- Create: `lib/src/settings.dart`
- Test: `test/settings_test.dart`

- [ ] **Step 1: Add the `yaml` dependency**

In `pubspec.yaml` under `dependencies:` add `yaml: ^3.1.0`, then run `flutter pub get`. Expected: resolves without conflicts (yaml 3.x is already in the workspace graph).

- [ ] **Step 2: Write the failing test**

`test/settings_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/settings.dart';

void main() {
  test('defaults apply when yaml is empty', () {
    final settings = ServerSettings.parse('');

    expect(settings.config.httpPort, 8080);
    expect(settings.config.rtspPort, 8554);
    expect(settings.config.username, 'admin');
    expect(settings.config.manufacturer, 'easy_onvif');
    expect(settings.services.recording, isTrue);
    expect(settings.services.replay, isTrue);
    expect(settings.services.search, isTrue);
    expect(settings.services.imaging, isTrue);
    expect(settings.segmentSeconds, 10);
    expect(settings.maxRetentionMinutes, isNull);
    expect(settings.recordingDirectory, isNull);
    expect(settings.imagingPresets, isNotEmpty);
    expect(settings.geoFallback, isNull);
  });

  test('yaml values override defaults', () {
    const yaml = '''
device:
  manufacturer: Acme
  model: SimCam 9000
  firmware: 9.9.9
  serial: SN-1234
  hardwareId: hw-77
  hostname: acme-cam
network:
  httpPort: 9080
  rtspPort: 9554
auth:
  username: operator
  password: secret
services:
  recording: false
  imaging: false
recording:
  directory: /tmp/onvif_recordings
  segmentSeconds: 4
  maxRetentionMinutes: 30
imaging:
  presets:
    - token: night
      name: Night Mode
      type: NightMode
geolocation:
  lat: 43.65
  lon: -79.38
  elevation: 76.0
''';

    final settings = ServerSettings.parse(yaml);

    expect(settings.config.manufacturer, 'Acme');
    expect(settings.config.model, 'SimCam 9000');
    expect(settings.config.firmwareVersion, '9.9.9');
    expect(settings.config.serialNumber, 'SN-1234');
    expect(settings.config.hardwareId, 'hw-77');
    expect(settings.config.hostname, 'acme-cam');
    expect(settings.config.httpPort, 9080);
    expect(settings.config.rtspPort, 9554);
    expect(settings.config.username, 'operator');
    expect(settings.config.password, 'secret');
    expect(settings.services.recording, isFalse);
    expect(settings.services.replay, isTrue);
    expect(settings.services.imaging, isFalse);
    expect(settings.recordingDirectory, '/tmp/onvif_recordings');
    expect(settings.segmentSeconds, 4);
    expect(settings.maxRetentionMinutes, 30);
    expect(settings.imagingPresets.single.token, 'night');
    expect(settings.imagingPresets.single.name, 'Night Mode');
    expect(settings.imagingPresets.single.type, 'NightMode');
    expect(settings.geoFallback!.latitude, 43.65);
    expect(settings.geoFallback!.longitude, -79.38);
    expect(settings.geoFallback!.elevation, 76.0);
  });

  test('malformed yaml throws FormatException', () {
    expect(() => ServerSettings.parse(': not yaml : ['),
        throwsA(isA<FormatException>()));
  });
}
```

- [ ] **Step 3: Run the test — verify it fails**

Run: `flutter test test/settings_test.dart`
Expected: FAIL (settings.dart does not exist).

- [ ] **Step 4: Implement `lib/src/settings.dart`**

```dart
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
/// Search order for [load]: explicit [path] argument, then
/// `~/.easy_onvif_server/settings.yaml`. Missing files and missing keys fall
/// back to the defaults baked into [ServerConfig].
class ServerSettings {
  final ServerConfig config;
  final ServiceFlags services;

  /// Recording storage directory. `null` means the caller picks a platform
  /// default (e.g. application support dir).
  final String? recordingDirectory;
  final int segmentSeconds;
  final int? maxRetentionMinutes;
  final List<ImagingPresetSetting> imagingPresets;

  /// Fallback location for `GetGeoLocation` when the platform has no fix.
  final GeoLocation? geoFallback;

  static const defaultImagingPresets = [
    ImagingPresetSetting(token: 'ImagingPreset_1', name: 'Standard', type: 'Auto'),
    ImagingPresetSetting(token: 'ImagingPreset_2', name: 'Low Light', type: 'LowLight'),
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
  factory ServerSettings.parse(String yamlText,
      {ServerConfig base = const ServerConfig()}) {
    final Object? doc;

    try {
      doc = yamlText.trim().isEmpty ? null : loadYaml(yamlText);
    } on YamlException catch (error) {
      throw FormatException('Invalid settings YAML: $error');
    }

    final map = doc is YamlMap ? doc : const <String, Object?>{};

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

    final presets = <ImagingPresetSetting>[];
    final presetList = imaging['presets'];
    if (presetList is YamlList) {
      for (final entry in presetList) {
        if (entry is YamlMap) {
          presets.add(ImagingPresetSetting(
            token: '${entry['token'] ?? 'ImagingPreset_${presets.length + 1}'}',
            name: '${entry['name'] ?? 'Preset ${presets.length + 1}'}',
            type: '${entry['type'] ?? 'Auto'}',
          ));
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
        username: (auth['username'] as String?) ?? base.username,
        password: (auth['password'] as String?) ?? base.password,
        manufacturer: (device['manufacturer'] as String?) ?? base.manufacturer,
        model: (device['model'] as String?) ?? base.model,
        firmwareVersion: (device['firmware'] as String?) ?? base.firmwareVersion,
        serialNumber: (device['serial'] as String?) ?? base.serialNumber,
        hardwareId: (device['hardwareId'] as String?) ?? base.hardwareId,
        hostname: (device['hostname'] as String?) ?? base.hostname,
      ),
      services: ServiceFlags(
        recording: (servicesMap['recording'] as bool?) ?? true,
        replay: (servicesMap['replay'] as bool?) ?? true,
        search: (servicesMap['search'] as bool?) ?? true,
        imaging: (servicesMap['imaging'] as bool?) ?? true,
      ),
      recordingDirectory: recording['directory'] as String?,
      segmentSeconds: (recording['segmentSeconds'] as int?) ?? 10,
      maxRetentionMinutes: recording['maxRetentionMinutes'] as int?,
      imagingPresets: presets.isEmpty ? defaultImagingPresets : presets,
      geoFallback: geoFallback,
    );
  }

  /// Loads settings from disk. Tries [path] first (if given), then
  /// `~/.easy_onvif_server/settings.yaml`, then [fallbackYaml] (e.g. a bundled
  /// asset), then pure defaults.
  static Future<ServerSettings> load({String? path, String? fallbackYaml}) async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

    final candidates = [
      if (path != null) path,
      if (home != null) '$home/.easy_onvif_server/settings.yaml',
    ];

    for (final candidate in candidates) {
      final file = File(candidate);
      if (file.existsSync()) return ServerSettings.parse(await file.readAsString());
    }

    if (fallbackYaml != null) return ServerSettings.parse(fallbackYaml);

    return const ServerSettings();
  }
}
```

- [ ] **Step 5: Run the test — verify it passes**

Run: `flutter test test/settings_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/src/settings.dart test/settings_test.dart
git commit -m "feat(server): add YAML settings loader"
```

---

### Task 2: ServerConfig service URLs + endpoint UUID

**Files:**
- Modify: `lib/src/config.dart`
- Modify: `lib/src/discovery/ws_discovery_server.dart` (use the config UUID instead of its own `_endpointId`)

- [ ] **Step 1: Extend `ServerConfig`**

Add to `lib/src/config.dart` (new final field with default in the const constructor, and new URL helpers alongside the existing ones):

```dart
  /// Stable device endpoint UUID, shared by WS-Discovery and
  /// `GetEndpointReference`.
  final String endpointUuid;
  // in the const constructor parameter list:
  //   this.endpointUuid = '3fa1fe68-b915-4053-a3e1-a8294933d5b2',

  /// The Imaging service endpoint for the advertised [host].
  String imagingServiceUrl(String host) => '${baseUrl(host)}/onvif/Imaging';

  /// The Recording service endpoint for the advertised [host].
  String recordingServiceUrl(String host) => '${baseUrl(host)}/onvif/Recording';

  /// The Search service endpoint for the advertised [host].
  String searchServiceUrl(String host) => '${baseUrl(host)}/onvif/SearchRecording';

  /// The Replay service endpoint for the advertised [host].
  String replayServiceUrl(String host) => '${baseUrl(host)}/onvif/Replay';

  /// The RTSP replay URL for a recording.
  String replayRtspUrl(String host, String recordingToken) =>
      'rtsp://$host:$rtspPort/onvif/replay/$recordingToken';
```

- [ ] **Step 2: Point WS-Discovery at the shared UUID**

In `lib/src/discovery/ws_discovery_server.dart`, replace the locally generated `_endpointId` with `config.endpointUuid` (the field already receives `config`; grep for `_endpointId` and substitute — the `urn:uuid:` prefix stays where it is).

- [ ] **Step 3: Verify**

Run: `flutter analyze && flutter test test/discovery_integration_test.dart`
Expected: no analysis issues, discovery test passes.

- [ ] **Step 4: Commit**

```bash
git add lib/src/config.dart lib/src/discovery/ws_discovery_server.dart
git commit -m "feat(server): add service URLs and shared endpoint UUID to config"
```

---

### Task 3: Settings-driven service registry

**Files:**
- Modify: `lib/src/onvif_device.dart`
- Modify: `lib/src/services/device_service.dart` (GetServices/GetCapabilities advertise per flags)
- Test: `test/settings_test.dart` (extend)

Note: this task registers imaging/recording/search/replay in `GetServices` but the services themselves arrive in Tasks 9–13. To keep every commit green, `OnvifDevice` gets the flags and DeviceService advertises **only enabled AND registered** services — accomplished by constructing the advertised list from the flags, and adding the actual service objects to the dispatcher in later tasks. `GetServices` may advertise a namespace one task before its handler lands only within this feature branch; the final integration tests validate the complete matrix.

- [ ] **Step 1: Write the failing test (extend `test/settings_test.dart`)**

Append a new group that boots a full device with recording disabled and checks `GetServices` and the fault path (this requires Tasks 9-13 services to exist to be fully meaningful, but the flags plumbing is testable now via the device namespace list):

```dart
// Add imports at top of settings_test.dart:
// import 'package:easy_onvif/onvif.dart';
// import 'package:easy_onvif_server/src/config.dart';
// import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
// import 'package:easy_onvif_server/src/onvif_device.dart';
// import 'package:easy_onvif_server/src/streaming/stream_backend.dart';

  group('service flags', () {
    test('disabled services are not advertised and fault when called', () async {
      const config = ServerConfig(httpPort: 8095, rtspPort: 8561);

      final device = OnvifDevice(
        config: config,
        hardware: StubHardwareAdapter(),
        streamBackend: StubStreamBackend(urlFor: config.rtspUrl),
        settings: ServerSettings.parse('''
services:
  recording: false
  replay: false
  search: false
  imaging: false
''', base: config),
      );

      await device.start();
      addTearDown(device.stop);

      final onvif = await Onvif.connect(
        host: 'localhost:8095',
        username: 'admin',
        password: 'admin',
      );

      final services = await onvif.deviceManagement.getServices();
      final namespaces = services.map((s) => s.nameSpace).toList();

      expect(namespaces, isNot(contains('http://www.onvif.org/ver10/recording/wsdl')));
      expect(namespaces, isNot(contains('http://www.onvif.org/ver10/search/wsdl')));
      expect(namespaces, isNot(contains('http://www.onvif.org/ver10/replay/wsdl')));
      expect(namespaces, isNot(contains('http://www.onvif.org/ver20/imaging/wsdl')));
      expect(namespaces, contains('http://www.onvif.org/ver10/device/wsdl'));

      // Client getters throw when the service was not advertised.
      expect(() => onvif.recordings, throwsException);
    });
  });
```

(Check the actual `Service` field name for the namespace with `grep -n "nameSpace\|namespace" packages/easy_onvif/lib/src/model/service.dart` and adjust the accessor.)

- [ ] **Step 2: Run — verify it fails** (`settings` is not a parameter of `OnvifDevice`).

- [ ] **Step 3: Implement**

`lib/src/onvif_device.dart`:
- Add `final ServerSettings settings;` with constructor parameter `ServerSettings? settings` stored as `settings = settings ?? const ServerSettings()` (import `settings.dart`).
- Pass `settings` into `DeviceService(config: config, state: this.state, hardware: hardware, settings: settings)`.

`lib/src/services/device_service.dart`:
- Add `final ServerSettings settings;` constructor field.
- In `_getServices`, append to the `services` list:
```dart
      if (settings.services.imaging) (Xmlns.timg, config.imagingServiceUrl(host)),
      if (settings.services.recording) (Xmlns.trc, config.recordingServiceUrl(host)),
      if (settings.services.search) (Xmlns.tse, config.searchServiceUrl(host)),
      if (settings.services.replay) (Xmlns.trp, config.replayServiceUrl(host)),
```
- In `_getCapabilities`, inside the `Capabilities` element add an `Extension` block when the flags are on (fixture shape — ENP1A14 `GetCapabilitiesResponse.xml` nests these under `tt:Extension`):
```xml
<tt:Extension>
  <tt:Recording><tt:XAddr>.../onvif/Recording</tt:XAddr>
    <tt:ReceiverSource>false</tt:ReceiverSource><tt:MediaProfileSource>true</tt:MediaProfileSource>
    <tt:DynamicRecordings>true</tt:DynamicRecordings><tt:DynamicTracks>false</tt:DynamicTracks>
    <tt:MaxStringLength>256</tt:MaxStringLength></tt:Recording>
  <tt:Search><tt:XAddr>.../onvif/SearchRecording</tt:XAddr><tt:MetadataSearch>false</tt:MetadataSearch></tt:Search>
  <tt:Replay><tt:XAddr>.../onvif/Replay</tt:XAddr></tt:Replay>
</tt:Extension>
```
and an `Imaging` sibling of `Media`/`PTZ` when imaging is on:
```xml
<tt:Imaging><tt:XAddr>.../onvif/Imaging</tt:XAddr></tt:Imaging>
```

- [ ] **Step 4: Run — verify it passes**

Run: `flutter test test/settings_test.dart && flutter test`
Expected: all pass (existing suite still green — default flags keep prior behavior except four extra `GetServices` entries; if `device_integration_test.dart` asserts an exact service count, update that assertion to `greaterThanOrEqualTo(4)`).

- [ ] **Step 5: Commit**

```bash
git add lib/src/onvif_device.dart lib/src/services/device_service.dart test/settings_test.dart
git commit -m "feat(server): settings-driven service advertisement"
```

---

### Task 4: Log ring buffer + Device Management gap operations

**Files:**
- Create: `lib/src/log_buffer.dart`
- Modify: `lib/src/onvif_device.dart` (install buffered printer)
- Modify: `lib/src/services/device_service.dart` (6 new operations)
- Test: `test/coverage_integration_test.dart` (new)

- [ ] **Step 1: Write the failing test**

`test/coverage_integration_test.dart` (this file grows in Tasks 5 and 13; create it with the device-management group now):

```dart
import 'package:easy_onvif/onvif.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/streaming/stream_backend.dart';

void main() {
  const httpPort = 8096;
  const config = ServerConfig(httpPort: httpPort, rtspPort: 8562);

  late OnvifDevice device;
  late Onvif onvif;

  setUpAll(() async {
    device = OnvifDevice(
      config: config,
      hardware: StubHardwareAdapter(),
      streamBackend: StubStreamBackend(urlFor: config.rtspUrl),
      settings: ServerSettings.parse('', base: config),
    );

    await device.start();

    onvif = await Onvif.connect(
      host: 'localhost:$httpPort',
      username: 'admin',
      password: 'admin',
    );
  });

  tearDownAll(() => device.stop());

  group('device management gaps', () {
    test('getSystemLog returns recent log lines', () async {
      final log = await onvif.deviceManagement.getSystemLog('System');
      expect(log.string, isNotEmpty);
    });

    test('getSystemSupportInformation returns platform info', () async {
      final info = await onvif.deviceManagement.getSystemSupportInformation();
      expect(info.string, isNotEmpty);
    });

    test('getEndpointReference returns the device uuid', () async {
      final ref = await onvif.deviceManagement.getEndpointReference();
      expect(ref.toString(), contains(config.endpointUuid));
    });

    test('getIPAddressFilter returns an empty Allow filter', () async {
      final filter = await onvif.deviceManagement.getIPAddressFilter();
      expect(filter.type, 'Allow');
    });

    test('storage configurations report the recording directory', () async {
      final configs = await onvif.deviceManagement.getStorageConfigurations();
      expect(configs, hasLength(1));
      expect(configs.first.data.type, 'Local');

      final single = await onvif.deviceManagement
          .getStorageConfiguration(configs.first.token!);
      expect(single.data.type, 'Local');
    });
  });
}
```

Before finalizing the test, check exact client method signatures and model field names in `packages/easy_onvif/lib/src/device_management.dart` and its models (e.g. `getSystemLog` takes a log-type string; `SystemInformation.string`; `IpAddressFilter.type`; `StorageConfiguration.token/.data.type`) — adjust accessors to the real ones, keep the assertions' *meaning*.

- [ ] **Step 2: Run — verify it fails** (`ActionNotSupported` faults surface as exceptions).

- [ ] **Step 3: Implement the ring buffer**

`lib/src/log_buffer.dart`:

```dart
import 'dart:collection';

import 'package:loggy/loggy.dart';

/// A [LoggyPrinter] decorator that keeps the last [capacity] formatted log
/// lines in memory so `GetSystemLog` can return real device logs.
class BufferedLoggyPrinter extends LoggyPrinter {
  final LoggyPrinter inner;
  final int capacity;

  static final Queue<String> _lines = Queue<String>();
  static int _capacity = 200;

  BufferedLoggyPrinter(this.inner, {this.capacity = 200}) {
    _capacity = capacity;
  }

  @override
  void onLog(LogRecord record) {
    inner.onLog(record);

    _lines.addLast(
        '${record.time.toIso8601String()} ${record.level.name} ${record.message}');
    while (_lines.length > _capacity) {
      _lines.removeFirst();
    }
  }

  /// The buffered log lines, oldest first.
  static List<String> get lines => List.unmodifiable(_lines);
}
```

In `lib/src/onvif_device.dart` `start()`, wrap the supplied printer:
`Loggy.initLoggy(logPrinter: BufferedLoggyPrinter(printer), logOptions: logOptions);`
(also update `OnvifServer.start` to not re-init loggy with the raw printer, or pass the wrapped printer down — simplest: wrap once in `OnvifDevice.start` and pass the wrapped instance to `server.start`).

- [ ] **Step 4: Implement the six operations in `DeviceService`**

Add cases to the `switch` and handlers producing these response bodies (existing builder style; all response elements in `Xmlns.tds`, inner types in `Xmlns.tt` unless noted):

- `GetSystemLog` → `GetSystemLogResponse > SystemLog(tds) > tt:String` containing `BufferedLoggyPrinter.lines.join('\n')` (fixture: IPG-8150PSS `GetSystemLogResponse.xml`).
- `GetSystemSupportInformation` → `GetSystemSupportInformationResponse > SupportInformation(tds) > tt:String` containing `'OS: ${Platform.operatingSystemVersion}\nDart: ${Platform.version}'`.
- `GetEndpointReference` → `GetEndpointReferenceResponse > GUID(tds)` = `config.endpointUuid`.
- `GetIPAddressFilter` → `GetIPAddressFilterResponse > IPAddressFilter(tds) > tt:Type` = `Allow`.
- `GetStorageConfigurations` → `GetStorageConfigurationsResponse > StorageConfigurations(tds, token="StorageToken_1") > Data(tds, type="Local") > tds:LocalPath` = the recordings directory (fixture: ENP1A14 `GetStorageConfigurationsResponse.xml`, with `Local` instead of `NFS`). DeviceService needs the resolved recordings path — add `final String Function() recordingDirectory;` supplied by `OnvifDevice` (returns `settings.recordingDirectory ?? '<system temp>/easy_onvif_recordings'` until Task 9 wires the real store path).
- `GetStorageConfiguration` → same single `StorageConfiguration(tds)` element (non-plural wrapper).

- [ ] **Step 5: Run — verify it passes**

Run: `flutter test test/coverage_integration_test.dart`
Expected: PASS (5 tests). Then `flutter test` — full suite green.

- [ ] **Step 6: Commit**

```bash
git add lib/src/log_buffer.dart lib/src/onvif_device.dart lib/src/services/device_service.dart lib/src/server/onvif_server.dart test/coverage_integration_test.dart
git commit -m "feat(server): device management gap operations with real log/storage data"
```

---

### Task 5: Media1/Media2 gap operations

**Files:**
- Modify: `lib/src/services/media1_service.dart`, `lib/src/services/media2_service.dart`
- Test: `test/coverage_integration_test.dart` (extend)

- [ ] **Step 1: Write the failing tests (append a `media gaps` group)**

```dart
  group('media gaps', () {
    test('media1 getMetadataConfiguration', () async {
      final mc = await onvif.media.media1.getMetadataConfiguration('MetadataConfig_1');
      expect(mc.token, 'MetadataConfig_1');
    });

    test('media2 getVideoEncoderConfigurations', () async {
      // Low-level: the client Media facade may not expose this; use transport.
      Transport.builder.element('GetVideoEncoderConfigurations', nest: () {
        Transport.builder.namespace(Xmlns.tr2);
      });
      final envelope = await onvif.media.media2.transport.securedRequest(
        onvif.media.media2.uri,
        Body(request: Transport.builder.buildFragment()),
      );
      expect(envelope.body.response!['Configurations'], isNotNull);
    });

    test('media2 getVideoEncoderInstances', () async {
      final info = await onvif.media.media2.getVideoEncoderInstances('VideoEncoderConfig_1');
      expect(info.total, greaterThanOrEqualTo(1));
    });

    test('media2 getVideoSourceConfigurationOptions', () async {
      final options = await onvif.media.media2.getVideoSourceConfigurationOptions();
      expect(options, isNotNull);
    });

    test('media2 getMetadataConfigurationOptions', () async {
      final options = await onvif.media.media2.getMetadataConfigurationOptions();
      expect(options, isNotNull);
    });
  });
```

Verify accessor paths first (`onvif.media.media1` / `onvif.media.media2` getters exist in `packages/easy_onvif/lib/src/media.dart`; `Transport`, `Body`, `Xmlns` come from `package:easy_onvif/soap.dart`). Adjust imports/accessors to what's actually exported; keep assertion meaning.

- [ ] **Step 2: Run — verify the new tests fail.**

- [ ] **Step 3: Implement**

`media1_service.dart` — add case `GetMetadataConfiguration`:
`GetMetadataConfigurationResponse(trt) > Configuration(trt, token="MetadataConfig_1") > tt:Name "Metadata 1", tt:UseCount 1, tt:SessionTimeout PT60S` (fixture: ENP1A14 media1 `GetMetadataConfigurationResponse.xml`).

`media2_service.dart` — add four cases (all response elements in `Xmlns.tr2`, type children in `Xmlns.tt`):
- `GetVideoEncoderConfigurations` → `Configurations(tr2, token="VideoEncoderConfig_1", GovLength="15", Profile="Main")` with `tt:Name "VideoEncoder_1"`, `tt:UseCount 1`, `tt:Encoding H264`, `tt:Resolution > tt:Width 1280 / tt:Height 720`, `tt:RateControl > tt:FrameRateLimit 15 / tt:BitrateLimit 2048`, `tt:Quality 5.0` — the resolution/frame rate constants must match the actual stream (1280×720@15, see `_platformVideoInput`).
- `GetVideoEncoderInstances` → `Info(tr2) > tr2:Total 1`.
- `GetVideoSourceConfigurationOptions` → `Options(tr2) > tt:BoundsRange > tt:XRange(tt:Min 0, tt:Max 0) / tt:YRange(0,0) / tt:WidthRange(tt:Min 1280, tt:Max 1280) / tt:HeightRange(720,720)`, plus `tt:VideoSourceTokensAvailable VideoSource_1`.
- `GetMetadataConfigurationOptions` → `Options(tr2) > tt:PTZStatusFilterOptions > tt:PanTiltStatusSupported false / tt:ZoomStatusSupported false` (fixture: ENP1A14 media2 `GetMetadataConfigurationOptionsResponse.xml` for the shape).

If a client model class fails to parse a minimal shape, open the corresponding fixture under `packages/easy_onvif/test/xml/ENP1A14-IR_25X/media2/` and mirror its element set exactly — fixtures win over this plan's sketch.

- [ ] **Step 4: Run — verify pass** (`flutter test test/coverage_integration_test.dart`, then full suite).

- [ ] **Step 5: Commit**

```bash
git add lib/src/services/media1_service.dart lib/src/services/media2_service.dart test/coverage_integration_test.dart
git commit -m "feat(server): media1/media2 gap operations"
```

---

### Task 6: Expose the live NAL source on StreamBackend

**Files:**
- Modify: `lib/src/streaming/stream_backend.dart`, `ffmpeg_backend.dart`, `camera_stream_backend.dart`

- [ ] **Step 1: Add to the `StreamBackend` interface** (in `stream_backend.dart`, with import of `h264_source.dart`):

```dart
  /// The live H.264 NAL source feeding the RTSP server, or `null` when the
  /// backend is not running or does not expose one. Used by the recording
  /// engine to tap the stream without opening the camera twice.
  NalStreamSource? get nalSource;
```

- [ ] **Step 2: Implement in all three backends**

- `StubStreamBackend`: `@override NalStreamSource? get nalSource => null;`
- `FfmpegBackend`: `@override NalStreamSource? get nalSource => _source;`
- `CameraStreamBackend`: `@override NalStreamSource? get nalSource => _source;`

- [ ] **Step 3: Verify** — `flutter analyze && flutter test` (no behavior change).

- [ ] **Step 4: Commit**

```bash
git add lib/src/streaming/stream_backend.dart lib/src/streaming/ffmpeg_backend.dart lib/src/streaming/camera_stream_backend.dart
git commit -m "feat(server): expose live NAL source on stream backends"
```

---

### Task 7: RecordingIndex + RecordingStore

**Files:**
- Create: `lib/src/recording/recording_index.dart`, `lib/src/recording/recording_store.dart`
- Test: `test/recording_store_test.dart`

- [ ] **Step 1: Write the failing test**

`test/recording_store_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/recording/recording_index.dart';
import 'package:easy_onvif_server/src/recording/recording_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('onvif_store_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('create, persist and reload a recording index', () async {
    final store = RecordingStore(root: tempDir);
    await store.open();
    expect(store.recordings, isEmpty);

    final index = await store.create(
      recordingToken: 'OnvifRecordingToken_1',
      frameRate: 15,
      sourceToken: 'VideoSource_1',
      profileToken: 'Profile_1',
    );

    index.segments.add(RecordingSegment(
      file: 'seg_00001.h264',
      startUtc: DateTime.utc(2026, 7, 23, 12, 0, 0),
      endUtc: DateTime.utc(2026, 7, 23, 12, 0, 10),
      frameCount: 150,
    ));
    await index.save();

    // Fresh store re-reads from disk.
    final store2 = RecordingStore(root: tempDir);
    await store2.open();

    expect(store2.recordings, hasLength(1));
    final loaded = store2.byToken('OnvifRecordingToken_1')!;
    expect(loaded.frameRate, 15);
    expect(loaded.segments.single.frameCount, 150);
    expect(loaded.earliestUtc, DateTime.utc(2026, 7, 23, 12, 0, 0));
    expect(loaded.latestUtc, DateTime.utc(2026, 7, 23, 12, 0, 10));
  });

  test('delete removes the directory', () async {
    final store = RecordingStore(root: tempDir);
    await store.open();
    await store.create(
      recordingToken: 'R1', frameRate: 15,
      sourceToken: 'VideoSource_1', profileToken: 'Profile_1');

    await store.delete('R1');

    expect(store.recordings, isEmpty);
    expect(Directory('${tempDir.path}/R1').existsSync(), isFalse);
  });
}
```

- [ ] **Step 2: Run — verify FAIL** (`flutter test test/recording_store_test.dart`).

- [ ] **Step 3: Implement `lib/src/recording/recording_index.dart`**

```dart
import 'dart:convert';
import 'dart:io';

/// One `.h264` segment of a recording.
class RecordingSegment {
  final String file;
  final DateTime startUtc;
  DateTime endUtc;
  int frameCount;

  RecordingSegment({
    required this.file,
    required this.startUtc,
    required this.endUtc,
    this.frameCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'file': file,
        'startUtc': startUtc.toIso8601String(),
        'endUtc': endUtc.toIso8601String(),
        'frameCount': frameCount,
      };

  factory RecordingSegment.fromJson(Map<String, dynamic> json) =>
      RecordingSegment(
        file: json['file'] as String,
        startUtc: DateTime.parse(json['startUtc'] as String),
        endUtc: DateTime.parse(json['endUtc'] as String),
        frameCount: json['frameCount'] as int? ?? 0,
      );
}

/// The on-disk metadata for a single recording (persisted as `index.json`).
class RecordingIndex {
  final String recordingToken;
  final Directory directory;
  final DateTime createdUtc;
  final int frameRate;
  final String sourceToken;
  final String profileToken;
  final List<RecordingSegment> segments;

  RecordingIndex({
    required this.recordingToken,
    required this.directory,
    required this.createdUtc,
    required this.frameRate,
    required this.sourceToken,
    required this.profileToken,
    List<RecordingSegment>? segments,
  }) : segments = segments ?? [];

  DateTime? get earliestUtc =>
      segments.isEmpty ? null : segments.first.startUtc;
  DateTime? get latestUtc => segments.isEmpty ? null : segments.last.endUtc;

  File get indexFile => File('${directory.path}/index.json');
  File segmentFile(RecordingSegment segment) =>
      File('${directory.path}/${segment.file}');

  Future<void> save() async {
    await indexFile.writeAsString(const JsonEncoder.withIndent('  ').convert({
      'recordingToken': recordingToken,
      'createdUtc': createdUtc.toIso8601String(),
      'frameRate': frameRate,
      'sourceToken': sourceToken,
      'profileToken': profileToken,
      'segments': segments.map((s) => s.toJson()).toList(),
    }));
  }

  static Future<RecordingIndex?> load(Directory directory) async {
    final file = File('${directory.path}/index.json');

    if (!file.existsSync()) return null;

    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      return RecordingIndex(
        recordingToken: json['recordingToken'] as String,
        directory: directory,
        createdUtc: DateTime.parse(json['createdUtc'] as String),
        frameRate: json['frameRate'] as int? ?? 15,
        sourceToken: json['sourceToken'] as String? ?? 'VideoSource_1',
        profileToken: json['profileToken'] as String? ?? 'Profile_1',
        segments: [
          for (final s in (json['segments'] as List? ?? []))
            RecordingSegment.fromJson(s as Map<String, dynamic>),
        ],
      );
    } catch (_) {
      // A corrupt index is skipped rather than crashing startup.
      return null;
    }
  }
}
```

- [ ] **Step 4: Implement `lib/src/recording/recording_store.dart`**

```dart
import 'dart:io';

import 'recording_index.dart';

/// Owns the recordings directory: loads existing recordings at startup,
/// creates/deletes recording directories, and applies retention pruning.
class RecordingStore {
  final Directory root;
  final int? maxRetentionMinutes;

  final Map<String, RecordingIndex> _recordings = {};

  RecordingStore({required this.root, this.maxRetentionMinutes});

  List<RecordingIndex> get recordings => _recordings.values.toList();

  RecordingIndex? byToken(String token) => _recordings[token];

  /// Loads all recordings found under [root] (recordings survive restarts).
  Future<void> open() async {
    if (!root.existsSync()) await root.create(recursive: true);

    await for (final entry in root.list()) {
      if (entry is Directory) {
        final index = await RecordingIndex.load(entry);

        if (index != null) _recordings[index.recordingToken] = index;
      }
    }
  }

  Future<RecordingIndex> create({
    required String recordingToken,
    required int frameRate,
    required String sourceToken,
    required String profileToken,
  }) async {
    final directory = Directory('${root.path}/$recordingToken');

    await directory.create(recursive: true);

    final index = RecordingIndex(
      recordingToken: recordingToken,
      directory: directory,
      createdUtc: DateTime.now().toUtc(),
      frameRate: frameRate,
      sourceToken: sourceToken,
      profileToken: profileToken,
    );

    await index.save();

    _recordings[recordingToken] = index;

    return index;
  }

  Future<void> delete(String recordingToken) async {
    final index = _recordings.remove(recordingToken);

    if (index != null && index.directory.existsSync()) {
      await index.directory.delete(recursive: true);
    }
  }

  /// Drops segments older than the retention window (called on rotation).
  Future<void> prune(RecordingIndex index) async {
    final retention = maxRetentionMinutes;

    if (retention == null) return;

    final cutoff =
        DateTime.now().toUtc().subtract(Duration(minutes: retention));

    while (index.segments.length > 1 &&
        index.segments.first.endUtc.isBefore(cutoff)) {
      final segment = index.segments.removeAt(0);
      final file = index.segmentFile(segment);

      if (file.existsSync()) await file.delete();
    }

    await index.save();
  }
}
```

- [ ] **Step 5: Run — verify PASS**, then **commit**:

```bash
git add lib/src/recording/recording_index.dart lib/src/recording/recording_store.dart test/recording_store_test.dart
git commit -m "feat(server): recording store with persistent JSON index"
```

---

### Task 8: SegmentRecorder

**Files:**
- Create: `lib/src/recording/segment_recorder.dart`
- Test: `test/recording_store_test.dart` (extend)

- [ ] **Step 1: Write the failing test (append)**

The test drives the recorder with a fake `NalStreamSource` emitting synthetic NALs (an IDR every 3 frames). Append to `recording_store_test.dart`:

```dart
// Add imports:
// import 'dart:async';
// import 'dart:typed_data';
// import 'package:easy_onvif_server/src/recording/segment_recorder.dart';
// import 'package:easy_onvif_server/src/streaming/h264_source.dart';

class FakeNalSource implements NalStreamSource {
  final _controller = StreamController<H264NalUnit>.broadcast();

  @override
  Stream<H264NalUnit> get nals => _controller.stream;

  @override
  Uint8List? get sps => Uint8List.fromList([0x67, 0x42, 0xC0, 0x1E]);

  @override
  Uint8List? get pps => Uint8List.fromList([0x68, 0xCE, 0x38, 0x80]);

  @override
  Future<void> get parametersReady => Future.value();

  /// Emits [frames] access units at [interval]; every third frame is an IDR
  /// (type 5), the rest are non-IDR slices (type 1).
  Future<void> emitFrames(int frames, Duration interval) async {
    for (var i = 0; i < frames; i++) {
      final isIdr = i % 3 == 0;
      final header = isIdr ? 0x65 : 0x41;
      final nal = Uint8List.fromList([header, 0x88, ...List.filled(64, i)]);

      _controller.add(H264NalUnit(nal, i * 6000, true));

      await Future<void>.delayed(interval);
    }
  }

  Future<void> close() => _controller.close();
}

// New group inside main():
  group('segment recorder', () {
    test('writes keyframe-aligned segments and updates the index', () async {
      final store = RecordingStore(root: tempDir);
      await store.open();

      final index = await store.create(
        recordingToken: 'R1', frameRate: 15,
        sourceToken: 'VideoSource_1', profileToken: 'Profile_1');

      final source = FakeNalSource();
      final recorder = SegmentRecorder(
        index: index,
        source: source,
        store: store,
        segmentSeconds: 1,
      );

      await recorder.start();
      // ~30 frames over ~3s => at least 2 rotated segments (1s each).
      await source.emitFrames(30, const Duration(milliseconds: 100));
      await recorder.stop();
      await source.close();

      expect(index.segments.length, greaterThanOrEqualTo(2));

      for (final segment in index.segments) {
        final bytes = index.segmentFile(segment).readAsBytesSync();
        // Starts with an Annex-B start code followed by SPS (0x67).
        expect(bytes.sublist(0, 5), [0, 0, 0, 1, 0x67]);
        expect(segment.frameCount, greaterThan(0));
      }

      // The reloaded index sees the same segments (save() ran on rotation/stop).
      final reloaded = await RecordingIndex.load(index.directory);
      expect(reloaded!.segments.length, index.segments.length);
    });
  });
```

- [ ] **Step 2: Run — verify FAIL.**

- [ ] **Step 3: Implement `lib/src/recording/segment_recorder.dart`**

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../streaming/h264_source.dart';
import 'recording_index.dart';
import 'recording_store.dart';

/// Records a live [NalStreamSource] into rotating Annex-B segment files.
///
/// Waits for a keyframe before starting each segment (so every segment decodes
/// standalone), prefixes SPS/PPS, and rotates on the first keyframe after
/// [segmentSeconds]. The index is saved on every rotation so a crash loses at
/// most the currently-open segment's tail.
class SegmentRecorder {
  static const _startCode = [0, 0, 0, 1];

  final RecordingIndex index;
  final NalStreamSource source;
  final RecordingStore store;
  final int segmentSeconds;

  StreamSubscription<H264NalUnit>? _subscription;
  IOSink? _sink;
  RecordingSegment? _segment;
  int _segmentNumber = 0;
  DateTime? _segmentStartedAt;

  SegmentRecorder({
    required this.index,
    required this.source,
    required this.store,
    this.segmentSeconds = 10,
  });

  bool get isRecording => _subscription != null;

  Future<void> start() async {
    if (_subscription != null) return;

    _segmentNumber = index.segments.length;

    _subscription = source.nals.listen(_onNal);
  }

  void _onNal(H264NalUnit nal) {
    final now = DateTime.now().toUtc();
    final isKeyframe = nal.type == 5;

    // Not yet in a segment: wait for a keyframe to open the first one.
    if (_sink == null) {
      if (!isKeyframe) return;

      _openSegment(now);
    } else if (isKeyframe &&
        now.difference(_segmentStartedAt!).inSeconds >= segmentSeconds) {
      _rotate(now);
    }

    // Skip parameter sets in the body; they were written at segment open.
    if (nal.isSps || nal.isPps) return;

    _sink!.add(_startCode);
    _sink!.add(nal.data);

    final segment = _segment!;

    segment.endUtc = now;

    if (nal.lastOfFrame) segment.frameCount++;
  }

  void _openSegment(DateTime now) {
    _segmentNumber++;

    final name = 'seg_${_segmentNumber.toString().padLeft(5, '0')}.h264';
    final file = File('${index.directory.path}/$name');

    _sink = file.openWrite();
    _segmentStartedAt = now;
    _segment = RecordingSegment(file: name, startUtc: now, endUtc: now);

    index.segments.add(_segment!);

    // Every segment starts with SPS/PPS so it decodes standalone.
    final sps = source.sps;
    final pps = source.pps;

    if (sps != null) _sink!..add(_startCode)..add(sps);
    if (pps != null) _sink!..add(_startCode)..add(pps);
  }

  void _rotate(DateTime now) {
    final closing = _sink;

    _sink = null;

    closing?.close();

    _openSegment(now);

    // Persist the index and apply retention after each rotation.
    unawaited(index.save().then((_) => store.prune(index)));
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    await _sink?.close();
    _sink = null;
    _segment = null;

    await index.save();
  }
}
```

Note the type import: `H264NalUnit.isSps/isPps/type` already exist in `h264_source.dart`.

- [ ] **Step 4: Run — verify PASS** (`flutter test test/recording_store_test.dart`), then **commit**:

```bash
git add lib/src/recording/segment_recorder.dart test/recording_store_test.dart
git commit -m "feat(server): segment recorder taps live NAL stream to disk"
```

---

### Task 9: RecordingManager + RecordingService (trc)

**Files:**
- Create: `lib/src/recording/recording_manager.dart`, `lib/src/services/recording_service.dart`
- Modify: `lib/src/onvif_device.dart` (construct store/manager, register service, wire storage path into DeviceService)
- Test: `test/recording_integration_test.dart`

- [ ] **Step 1: Write the failing integration test**

`test/recording_integration_test.dart` — uses the real client against a live ffmpeg test-pattern stream (same pattern as `rtsp_integration_test.dart`; requires ffmpeg on PATH like the existing suite):

```dart
import 'dart:io';

import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/recordings.dart' show RecordingJobConfigurationMode;
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_backend.dart';

void main() {
  const httpPort = 8097;
  const rtspPort = 8563;
  const config = ServerConfig(httpPort: httpPort, rtspPort: rtspPort);

  late Directory recordingsDir;
  late OnvifDevice device;
  late Onvif onvif;

  setUpAll(() async {
    recordingsDir = await Directory.systemTemp.createTemp('onvif_rec_test');

    device = OnvifDevice(
      config: config,
      hardware: StubHardwareAdapter(),
      streamBackend: FfmpegBackend(
        config: config,
        frameRate: 15,
        inputArgs: ['-f', 'lavfi', '-i', 'testsrc=size=640x480:rate=15'],
      ),
      settings: ServerSettings.parse('''
recording:
  directory: ${recordingsDir.path}
  segmentSeconds: 2
''', base: config),
    );

    await device.start();

    onvif = await Onvif.connect(
      host: 'localhost:$httpPort',
      username: 'admin',
      password: 'admin',
    );
  });

  tearDownAll(() async {
    await device.stop();
    if (recordingsDir.existsSync()) recordingsDir.deleteSync(recursive: true);
  });

  test('recording lifecycle produces real segments on disk', () async {
    final capabilities = await onvif.recordings.getServiceCapabilities();
    expect(capabilities.dynamicRecordings, isTrue);

    final recordings = await onvif.recordings.getRecordings();
    expect(recordings, isEmpty);

    // Create a recording + an active job; the fixture-shaped request models
    // come from the client package.
    // Check packages/easy_onvif/lib/recordings.dart exports for the exact
    // RecordingConfiguration / RecordingJobConfiguration constructors and
    // build minimal instances (source: VideoSource_1, content 'Test',
    // maximumRetentionTime 'PT0S'; job: mode Active, priority 1).
    // If constructing the typed request is impractical, fall back to a
    // low-level Transport request with the same XML the CLI would send.
    final recordingToken = await onvif.recordings.createRecording(
      buildTestRecordingConfiguration(), // helper defined in this file
    );
    expect(recordingToken, isNotEmpty);

    final job = await onvif.recordings.createRecordingJob(
      buildTestJobConfiguration(recordingToken), // helper defined in this file
    );

    // Let it capture ~5s of live stream (segmentSeconds: 2 → >=2 segments).
    await Future<void>.delayed(const Duration(seconds: 5));

    final state = await onvif.recordings.getRecordingJobState(job.jobToken);
    expect(state.state, 'Active');

    await onvif.recordings.setRecordingJobMode(
      jobToken: job.jobToken,
      mode: RecordingJobConfigurationMode.idle,
    );

    final segDir = Directory('${recordingsDir.path}/$recordingToken');
    final segments = segDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.h264'))
        .toList();

    expect(segments.length, greaterThanOrEqualTo(2));
    expect(segments.first.lengthSync(), greaterThan(1000));

    final listed = await onvif.recordings.getRecordings();
    expect(listed.single.recordingToken, recordingToken);

    await onvif.recordings.deleteRecording(recordingToken);
    expect(segDir.existsSync(), isFalse);
  }, timeout: const Timeout(Duration(seconds: 90)));
}
```

Before finalizing: inspect `packages/easy_onvif/lib/recordings.dart` exports to write `buildTestRecordingConfiguration()`/`buildTestJobConfiguration()` with the real model constructors (`RecordingConfiguration`, `RecordingJobConfiguration`, enum casing for `RecordingJobConfigurationMode`). Also confirm `CreateRecordingJobResponse.jobToken` and `RecordingJobStateInformation.state` accessor names. Adjust the test code accordingly — meaning stays fixed.

- [ ] **Step 2: Run — verify FAIL** (`onvif.recordings` throws: service not advertised... it *is* advertised since Task 3, so the failure is `ActionNotSupported` from the missing `trc` service).

- [ ] **Step 3: Implement `lib/src/recording/recording_manager.dart`**

```dart
import '../settings.dart';
import '../streaming/stream_backend.dart';
import 'recording_index.dart';
import 'recording_store.dart';
import 'segment_recorder.dart';

/// A recording job binding a recording to the live stream.
class RecordingJob {
  final String jobToken;
  final String recordingToken;
  String mode; // 'Active' | 'Idle'
  final int priority;

  RecordingJob({
    required this.jobToken,
    required this.recordingToken,
    required this.mode,
    this.priority = 1,
  });
}

/// The SOAP-facing recording state machine: recordings, jobs, and the
/// [SegmentRecorder]s that do the actual disk capture.
class RecordingManager {
  static const maxRecordings = 5;

  final RecordingStore store;
  final StreamBackend backend;
  final ServerSettings settings;

  final Map<String, RecordingJob> _jobs = {};
  final Map<String, SegmentRecorder> _recorders = {};

  int _recordingCounter = 0;
  int _jobCounter = 0;

  RecordingManager({
    required this.store,
    required this.backend,
    required this.settings,
  });

  List<RecordingIndex> get recordings => store.recordings;
  List<RecordingJob> get jobs => _jobs.values.toList();

  RecordingIndex? recording(String token) => store.byToken(token);
  RecordingJob? job(String token) => _jobs[token];

  bool isRecordingActive(String recordingToken) => _jobs.values.any(
      (j) => j.recordingToken == recordingToken && j.mode == 'Active');

  /// Creates a recording; throws [StateError] beyond [maxRecordings].
  Future<RecordingIndex> createRecording() async {
    if (store.recordings.length >= maxRecordings) {
      throw StateError('MaxRecordings');
    }

    // Tokens continue past any recordings reloaded from disk.
    while (store.byToken('OnvifRecordingToken_${++_recordingCounter}') != null) {}

    return store.create(
      recordingToken: 'OnvifRecordingToken_$_recordingCounter',
      frameRate: 15,
      sourceToken: 'VideoSource_1',
      profileToken: 'Profile_1',
    );
  }

  Future<void> deleteRecording(String recordingToken) async {
    final jobTokens = _jobs.values
        .where((j) => j.recordingToken == recordingToken)
        .map((j) => j.jobToken)
        .toList();

    for (final token in jobTokens) {
      await deleteJob(token);
    }

    await store.delete(recordingToken);
  }

  /// Creates a job; mode `Active` starts capture immediately.
  Future<RecordingJob> createJob(String recordingToken, String mode) async {
    final index = store.byToken(recordingToken);

    if (index == null) throw ArgumentError('NoRecording');

    final job = RecordingJob(
      jobToken: 'RecordingJobToken_${++_jobCounter}',
      recordingToken: recordingToken,
      mode: 'Idle',
    );

    _jobs[job.jobToken] = job;

    if (mode == 'Active') await setJobMode(job.jobToken, 'Active');

    return job;
  }

  Future<void> setJobMode(String jobToken, String mode) async {
    final job = _jobs[jobToken];

    if (job == null) throw ArgumentError('NoRecordingJob');
    if (job.mode == mode) return;

    if (mode == 'Active') {
      final source = backend.nalSource;

      if (source == null) throw StateError('NoSource');

      final recorder = SegmentRecorder(
        index: store.byToken(job.recordingToken)!,
        source: source,
        store: store,
        segmentSeconds: settings.segmentSeconds,
      );

      await recorder.start();

      _recorders[jobToken] = recorder;
    } else {
      await _recorders.remove(jobToken)?.stop();
    }

    job.mode = mode;
  }

  Future<void> deleteJob(String jobToken) async {
    await _recorders.remove(jobToken)?.stop();
    _jobs.remove(jobToken);
  }

  Future<void> dispose() async {
    for (final recorder in _recorders.values) {
      await recorder.stop();
    }
    _recorders.clear();
    _jobs.clear();
  }
}
```

- [ ] **Step 4: Implement `lib/src/services/recording_service.dart`**

`OnvifService` for `Xmlns.trc`; `isPreAuth` → `GetServiceCapabilities`. Operation handlers (response element namespaces: wrapper `trc`, type children `tt` — mirror the ENP1A14 `recordings/` fixtures):

- `GetServiceCapabilities` → `Capabilities(trc)` attributes `DynamicRecordings="true" DynamicTracks="false" Encoding="H264" MaxRate="2048" MaxTotalRate="2048" MaxRecordings="5" MaxRecordingJobs="5" Options="true" MetadataRecording="false"`.
- `CreateRecording` → call `manager.createRecording()`; respond `CreateRecordingResponse > trc:RecordingToken`. On `StateError` → fault `subcode: 'MaxRecordings', reason: 'The maximum number of recordings has been reached.'`.
- `DeleteRecording` → param `RecordingToken` (`ctx.param('RecordingToken')`); unknown token → fault `NoRecording`; else `manager.deleteRecording` + empty `DeleteRecordingResponse`.
- `GetRecordings` → for each `manager.recordings` emit the fixture shape (ENP1A14 `GetRecordingsResponse.xml`): `trc:RecordingItem > tt:RecordingToken`, `tt:Configuration > tt:Source(tt:SourceId=<sourceToken>, tt:Name=<sourceToken>, tt:Location 'Location', tt:Description 'Live capture', tt:Address <profile schema url>) , tt:Content 'RecordContent', tt:MaximumRetentionTime PT0S`, `tt:Tracks > tt:Track > tt:TrackToken videotracktoken_1, tt:Configuration > tt:TrackType Video, tt:Description VideoTrack` (video track only — no audio/metadata; recordings hold video segments only).
- `CreateRecordingJob` → parse `JobConfiguration > RecordingToken` and `JobConfiguration > Mode` from `ctx.operationElement` (walk `childElements` like `PtzService._vector` does); respond `CreateRecordingJobResponse > trc:JobToken` + `trc:JobConfiguration > tt:RecordingToken, tt:Mode, tt:Priority 1`.
- `DeleteRecordingJob` → param `JobToken`; `manager.deleteJob`; empty response. **Note:** the client's `deleteRecordingJob` sends `DeleteRecording` with the job token (client bug — see `recordings.dart:132`); the integration test uses `setRecordingJobMode` to stop instead, so no server workaround is needed.
- `GetRecordingJobs` → `trc:JobItem > tt:JobToken + tt:JobConfiguration(tt:RecordingToken, tt:Mode, tt:Priority)` per job.
- `GetRecordingJobState` → param `JobToken`; respond `trc:State > tt:RecordingToken, tt:State (Active|Idle)`.
- `SetRecordingJobMode` → params `JobToken`, `Mode`; call `manager.setJobMode`; empty response.
- `GetRecordingOptions` → param `RecordingToken`; respond `trc:Options > tt:Job(Spare="4" CompatibleSources="VideoSource_1") + tt:Track(SpareTotal="0")` (attribute-style, matching `RecordingOptions` model — verify against ENP1A14 fixture and the client model parse).

- [ ] **Step 5: Wire into `OnvifDevice`**

- Construct in the constructor when `settings.services.recording`: `RecordingStore(root: Directory(<resolved recordings dir>), maxRetentionMinutes: settings.maxRetentionMinutes)` and `RecordingManager(store:, backend: streamBackend, settings:)`. Resolved dir: `settings.recordingDirectory ?? '${Directory.systemTemp.path}/easy_onvif_recordings'`.
- `start()`: `await store.open()` before the server starts.
- `stop()`: `await recordingManager?.dispose()`.
- Register `RecordingService(manager: recordingManager!)` in the services list when the flag is on.
- Replace Task 4's placeholder `recordingDirectory` closure in `DeviceService` with the store's real path.

- [ ] **Step 6: Run — verify PASS** (`flutter test test/recording_integration_test.dart`, then the full suite).

- [ ] **Step 7: Commit**

```bash
git add lib/src/recording/ lib/src/services/recording_service.dart lib/src/onvif_device.dart lib/src/services/device_service.dart test/recording_integration_test.dart
git commit -m "feat(server): recording service with real disk capture"
```

---

### Task 10: FileH264Source + RtspServer replay routing

**Files:**
- Create: `lib/src/streaming/file_h264_source.dart`
- Modify: `lib/src/streaming/rtsp_server.dart`
- Test: `test/replay_integration_test.dart` (created here, extended in Task 11)

- [ ] **Step 1: Implement `lib/src/streaming/file_h264_source.dart`**

```dart
import 'dart:async';
import 'dart:typed_data';

import '../recording/recording_index.dart';
import 'h264_source.dart';

/// Plays a recorded segment sequence back as a live-like NAL stream, paced at
/// the recorded frame rate. One instance per replay session.
class FileH264Source implements NalStreamSource {
  final RecordingIndex index;

  /// Optional seek target: playback starts at the first segment whose end is
  /// after this instant (segments are keyframe-aligned).
  final DateTime? startUtc;

  final _controller = StreamController<H264NalUnit>.broadcast();
  late final AccessUnitFramer _framer =
      AccessUnitFramer(frameRate: index.frameRate);

  Timer? _timer;
  final List<List<H264NalUnit>> _accessUnits = [];
  int _position = 0;

  FileH264Source({required this.index, this.startUtc});

  @override
  Stream<H264NalUnit> get nals => _controller.stream;

  @override
  Uint8List? get sps => _framer.sps;

  @override
  Uint8List? get pps => _framer.pps;

  @override
  Future<void> get parametersReady => _framer.parametersReady;

  /// Loads segments (honoring [startUtc]) and begins paced emission.
  Future<void> start() async {
    final seek = startUtc;
    final segments = seek == null
        ? index.segments
        : index.segments.where((s) => s.endUtc.isAfter(seek)).toList();

    // Group the file NALs into timestamped access units by running them
    // through the shared framer and buffering its output.
    final buffered = <H264NalUnit>[];
    final sub = _framer.nals.listen(buffered.add);
    final splitter = AnnexBSplitter();

    for (final segment in segments) {
      final file = index.segmentFile(segment);

      if (!file.existsSync()) continue;

      for (final nal in splitter.feed(await file.readAsBytes())) {
        _framer.addNal(nal);
      }
      // Terminate the trailing NAL (splitter emits on next start code).
      _framer.addNal(Uint8List.fromList([0x09, 0x10])); // AUD, dropped by framer
    }

    _framer.flush();
    await sub.cancel();

    // Regroup buffered NALs by timestamp into access units.
    for (final nal in buffered) {
      if (_accessUnits.isEmpty ||
          _accessUnits.last.first.timestamp != nal.timestamp) {
        _accessUnits.add([nal]);
      } else {
        _accessUnits.last.add(nal);
      }
    }

    final interval = Duration(microseconds: 1000000 ~/ index.frameRate);

    _timer = Timer.periodic(interval, (_) {
      if (_position >= _accessUnits.length) {
        _timer?.cancel();
        return; // End of recording: stop emitting, keep session open.
      }

      for (final nal in _accessUnits[_position]) {
        _controller.add(nal);
      }

      _position++;
    });
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;

    await _controller.close();
  }
}
```

Implementation note: `AnnexBSplitter.feed` only emits a NAL once the *next* start code arrives, so the file's final NAL needs the pushed AUD (type 9, which `AccessUnitFramer` drops) to flush — that is why each segment feed ends with the dummy AUD.

- [ ] **Step 2: Add replay routing to `RtspServer`**

Changes to `lib/src/streaming/rtsp_server.dart`:

1. Constructor gains an optional resolver:
```dart
  /// Creates a per-session replay source for `/onvif/replay/<token>` URLs, or
  /// `null` if the token is unknown. When absent, replay paths 404.
  final Future<FileH264Source?> Function(String recordingToken, DateTime? startUtc)?
      replaySourceFor;

  RtspServer({required this.source, required this.port, this.replaySourceFor});
```
2. `_buildSdp` takes the session's source as a parameter (`String _buildSdp(NalStreamSource source)`) instead of reading `this.source` (the `baseUrl` parameter is already unused — drop it).
3. `_RtspConnection` gains:
```dart
  NalStreamSource? _sessionSource;   // live default or replay file source
  FileH264Source? _fileSource;       // owned; disposed on close
  DateTime? _pendingSeek;            // parsed from PLAY Range header
```
4. `_handleDescribe(cseq, url)`: parse the URL path. If it matches `RegExp(r'/onvif/replay/([^/?]+)')` and `server.replaySourceFor != null`, resolve `_fileSource` (with `startUtc: null` — Range comes at PLAY; the source is (re)created in `_handlePlay` if a seek arrives) and set `_sessionSource = _fileSource`; on `null` resolution respond `404 Not Found`. Otherwise `_sessionSource = server.source`. Then await `_sessionSource!.parametersReady` (same 5s timeout) and respond with `_buildSdp(_sessionSource!)`.
5. `_handleRequest` passes `headers` to `_handlePlay(cseq, url, headers)`. `_handlePlay` parses `Range: clock=<start>-` with `RegExp(r'clock=(\d{8}T\d{6}(?:\.\d+)?Z)')`; on match converts `20260723T120005Z` → `DateTime.utc` (substring parse: year 0-4, month 4-6, day 6-8, hour 9-11, min 11-13, sec 13-15). If this is a replay session and a seek time arrived, dispose and re-resolve `_fileSource` passing the seek. Then respond (existing headers) and `_startStreaming()`.
6. `_startStreaming`: subscribe to `_sessionSource!.nals` instead of `server.source.nals`; for a replay session call `unawaited(_fileSource!.start())` after subscribing.
7. `close()`/`_stopStreaming`: also `await _fileSource?.stop(); _fileSource = null;`.

- [ ] **Step 3: Verify no regression**

Run: `flutter analyze && flutter test test/rtsp_integration_test.dart`
Expected: clean analysis; live-stream tests still pass (live path untouched semantically).

- [ ] **Step 4: Commit**

```bash
git add lib/src/streaming/file_h264_source.dart lib/src/streaming/rtsp_server.dart
git commit -m "feat(server): RTSP replay routing with file-backed H.264 source"
```

---

### Task 11: ReplayService (trp) + replay integration test

**Files:**
- Create: `lib/src/services/replay_service.dart`
- Modify: `lib/src/onvif_device.dart` (register; give backends the resolver)
- Modify: `lib/src/streaming/ffmpeg_backend.dart`, `camera_stream_backend.dart` (pass `replaySourceFor` into their `RtspServer`)
- Test: `test/replay_integration_test.dart`

- [ ] **Step 1: Write the failing test**

`test/replay_integration_test.dart` — same server setup block as `recording_integration_test.dart` (ports 8098/8564, its own temp dir; copy the `setUpAll`/`tearDownAll` and the two `buildTest*Configuration` helpers):

```dart
  test('replay serves recorded footage as decodable H.264', () async {
    // Record ~5 seconds of the live test pattern.
    final recordingToken =
        await onvif.recordings.createRecording(buildTestRecordingConfiguration());
    final job = await onvif.recordings
        .createRecordingJob(buildTestJobConfiguration(recordingToken));

    await Future<void>.delayed(const Duration(seconds: 5));

    await onvif.recordings.setRecordingJobMode(
      jobToken: job.jobToken,
      mode: RecordingJobConfigurationMode.idle,
    );

    final replayUri = await onvif.replay.getReplayUri(recordingToken);

    expect(replayUri, startsWith('rtsp://'));
    expect(replayUri, contains('/onvif/replay/$recordingToken'));

    // Re-encode 2s from the replay endpoint — proves it serves real video.
    final capture = '${recordingsDir.path}/replay_capture.mp4';
    final record = await Process.run('ffmpeg', [
      '-hide_banner', '-loglevel', 'error', '-y',
      '-rtsp_transport', 'tcp', '-i', replayUri,
      '-t', '2', '-c:v', 'libx264', '-preset', 'ultrafast', '-f', 'mp4', capture,
    ]);
    expect(record.exitCode, 0, reason: 'ffmpeg: ${record.stderr}');

    final probe = await Process.run('ffprobe', [
      '-hide_banner', '-loglevel', 'error', '-i', capture,
      '-show_entries', 'stream=codec_name,width,height', '-of', 'csv=p=0',
    ]);
    expect(probe.exitCode, 0);
    expect(probe.stdout.toString(), contains('h264'));
    expect(probe.stdout.toString(), contains('640'));

    // Replay configuration round-trip.
    final replayConfig = await onvif.replay.getReplayConfiguration();
    expect(replayConfig.sessionTimeout, isNotNull);

    final capabilities = await onvif.replay.getServiceCapabilities();
    expect(capabilities, isNotNull);
  }, timeout: const Timeout(Duration(seconds: 120)));
```

(Verify `Replay` client method names/models in `packages/easy_onvif/lib/src/replay.dart`: `getReplayUri(String recordingToken)`, `getReplayConfiguration()`, `setReplayConfiguration(...)`, `getServiceCapabilities()` — adjust accessors.)

- [ ] **Step 2: Run — verify FAIL** (`trp` not registered).

- [ ] **Step 3: Implement `lib/src/services/replay_service.dart`**

`OnvifService` for `Xmlns.trp`; `isPreAuth` → `GetServiceCapabilities`. State: `String _sessionTimeout = 'PT60S';`. Constructor takes `RecordingManager manager` and `ServerConfig config`. Handlers:

- `GetReplayUri` → param `RecordingToken`; unknown → fault `NoRecording`; else `GetReplayUriResponse > trp:Uri` = `config.replayRtspUrl(host, token)`.
- `GetReplayConfiguration` → `GetReplayConfigurationResponse > trp:Configuration > tt:SessionTimeout` = `_sessionTimeout`.
- `SetReplayConfiguration` → read `Configuration > SessionTimeout` child text if present, store it; empty `SetReplayConfigurationResponse`.
- `GetServiceCapabilities` → `Capabilities(trp)` attributes `ReversePlayback="false" SessionTimeoutRange="10 120" RTP_RTSP_TCP="true" RTSPWebSocketUri=""`.

- [ ] **Step 4: Wire the resolver through the backends**

- `FfmpegBackend` and `CameraStreamBackend` gain a field
  `final Future<FileH264Source?> Function(String, DateTime?)? replaySourceFor;`
  (constructor parameter) passed into their `RtspServer(...)` construction.
- `OnvifDevice` builds the resolver when recording is enabled:
```dart
  Future<FileH264Source?> _replaySource(String token, DateTime? startUtc) async {
    final index = recordingManager?.store.byToken(token);

    if (index == null || index.segments.isEmpty) return null;

    return FileH264Source(index: index, startUtc: startUtc);
  }
```
  and passes it to the backend. Since backends are constructed by callers (`main.dart`, tests), the cleanest wiring: `OnvifDevice` sets it via a new mutable backend property `set replaySourceFor(...)` assigned in the constructor before `start()`. Choose the property approach — no caller changes needed.

- [ ] **Step 5: Register `ReplayService` in `OnvifDevice`** when `settings.services.replay` (requires the manager; when recording is disabled but replay enabled, construct the store read-only and a manager without job capability — acceptable: manager works, jobs simply never started).

- [ ] **Step 6: Run — verify PASS** (`flutter test test/replay_integration_test.dart`), then full suite, then **commit**:

```bash
git add lib/src/services/replay_service.dart lib/src/onvif_device.dart lib/src/streaming/ffmpeg_backend.dart lib/src/streaming/camera_stream_backend.dart test/replay_integration_test.dart
git commit -m "feat(server): replay service serving recordings over RTSP"
```

---

### Task 12: SearchService (tse)

**Files:**
- Create: `lib/src/services/search_service.dart`
- Modify: `lib/src/onvif_device.dart` (register when `settings.services.search`)
- Test: `test/search_integration_test.dart`

- [ ] **Step 1: Write the failing test**

`test/search_integration_test.dart` — same server setup as `recording_integration_test.dart` (ports 8099/8565, own temp dir, same helpers):

```dart
  test('search returns real recording time ranges', () async {
    // Produce one real recording (~4s).
    final recordingToken =
        await onvif.recordings.createRecording(buildTestRecordingConfiguration());
    final job = await onvif.recordings
        .createRecordingJob(buildTestJobConfiguration(recordingToken));
    await Future<void>.delayed(const Duration(seconds: 4));
    await onvif.recordings.setRecordingJobMode(
      jobToken: job.jobToken,
      mode: RecordingJobConfigurationMode.idle,
    );

    final before = DateTime.now().toUtc();

    // FindRecordings → search token; results reference the real recording.
    final searchToken = await onvif.search.findRecordings();
    expect(searchToken, isNotEmpty);

    final results = await onvif.search.getRecordingSearchResults(
      searchToken: searchToken,
    );
    expect(results, hasLength(1));
    expect(results.single.recordingToken, recordingToken);

    final info = await onvif.search.getRecordingInformation(recordingToken);
    expect(info.recordingToken, recordingToken);
    expect(info.earliestRecording, isNotNull);
    expect(info.latestRecording, isNotNull);
    // The recorded range is real: it ends near "now" and spans ~4s.
    expect(before.difference(DateTime.parse('${info.latestRecording}')).inSeconds.abs(),
        lessThan(30));

    final summary = await onvif.search.getRecordingSummary();
    expect(summary.numberRecordings, 1);
    expect(summary.dataFrom, isNotNull);
    expect(summary.dataUntil, isNotNull);
  }, timeout: const Timeout(Duration(seconds: 90)));
```

(Verify `Search` client signatures in `packages/easy_onvif/lib/src/search.dart` — `findRecordings({...})` named params, `getRecordingSearchResults` parameter name, `RecordingInformation` / `RecordingSummary` / `FindRecordingResult` field names and whether date fields parse as `DateTime` or `String`. Adjust accessors; keep assertion meaning.)

- [ ] **Step 2: Run — verify FAIL** (`tse` not registered).

- [ ] **Step 3: Implement `lib/src/services/search_service.dart`**

`OnvifService` for `Xmlns.tse`; `isPreAuth` → `GetServiceCapabilities`. Constructor takes `RecordingManager manager`. State: `int _searchCounter = 0;` and `final Map<String, List<String>> _searches = {};` (search token → recording tokens snapshot taken at FindRecordings time — search completes immediately).

Handlers (wrapper elements `tse`, type children `tt`):

- `GetServiceCapabilities` → `Capabilities(tse)` attributes `MetadataSearch="false" GeneralStartEvents="false"`.
- `FindRecordings` → snapshot `manager.recordings` tokens into `_searches['RecordingSearchToken_${++_searchCounter}']`; respond `FindRecordingsResponse > tse:SearchToken`.
- `GetRecordingSearchResults` → param `SearchToken` (unknown → fault `InvalidToken`); respond
  `GetRecordingSearchResultsResponse > tse:ResultList > tt:SearchState Completed` then per recording `tt:RecordingInformation > (recording info shape below)`.
- `GetRecordingInformation` → param `RecordingToken` (unknown → fault `NoRecording`); respond `GetRecordingInformationResponse > tse:RecordingInformation > (shape below)`.
- `GetRecordingSummary` → aggregate over `manager.recordings`: earliest `earliestUtc`, latest `latestUtc`, count; respond
  `GetRecordingSummaryResponse > tse:Summary > tt:DataFrom, tt:DataUntil, tt:NumberRecordings`. With zero recordings use `DateTime.now().toUtc()` for both bounds.

Recording-information shape (all `tt`, from the recording's `RecordingIndex`):
```xml
<tt:RecordingToken>OnvifRecordingToken_1</tt:RecordingToken>
<tt:Source>
  <tt:SourceId>VideoSource_1</tt:SourceId><tt:Name>VideoSource_1</tt:Name>
  <tt:Location>Location</tt:Location><tt:Description>Live capture</tt:Description>
  <tt:Address>http://www.onvif.org/ver10/schema/Profile</tt:Address>
</tt:Source>
<tt:EarliestRecording>2026-07-23T12:00:00.000Z</tt:EarliestRecording>
<tt:LatestRecording>2026-07-23T12:00:10.000Z</tt:LatestRecording>
<tt:Content>RecordContent</tt:Content>
<tt:Track>
  <tt:TrackToken>videotracktoken_1</tt:TrackToken>
  <tt:TrackInformation>
    <tt:TrackType>Video</tt:TrackType><tt:Description>VideoTrack</tt:Description>
    <tt:DataFrom>2026-07-23T12:00:00.000Z</tt:DataFrom>
    <tt:DataTo>2026-07-23T12:00:10.000Z</tt:DataTo>
  </tt:TrackInformation>
</tt:Track>
<tt:RecordingStatus>Stopped</tt:RecordingStatus>
```
Timestamps come from `index.earliestUtc/latestUtc` (`toIso8601String()`); `RecordingStatus` is `Recording` when `manager.isRecordingActive(token)`, else `Stopped`. Omit `EarliestRecording`/`LatestRecording` elements when the index has no segments.

- [ ] **Step 4: Register in `OnvifDevice`** when `settings.services.search` (shares the manager instance from Task 9/11).

- [ ] **Step 5: Run — verify PASS**, full suite, **commit**:

```bash
git add lib/src/services/search_service.dart lib/src/onvif_device.dart test/search_integration_test.dart
git commit -m "feat(server): search service over real recording indexes"
```

---

### Task 13: ImagingService (timg)

**Files:**
- Create: `lib/src/services/imaging_service.dart`
- Modify: `lib/src/hardware/device_state.dart` (imaging preset state)
- Modify: `lib/src/onvif_device.dart` (seed presets, register when flag on)
- Test: `test/coverage_integration_test.dart` (extend)

- [ ] **Step 1: Write the failing tests (append an `imaging` group)**

```dart
  group('imaging', () {
    test('presets round-trip', () async {
      final presets = await onvif.imaging.getPresets('VideoSource_1');
      expect(presets.length, greaterThanOrEqualTo(2));

      await onvif.imaging.setCurrentPreset(
        videoSourceToken: 'VideoSource_1',
        presetToken: presets.last.token,
      );

      final current = await onvif.imaging.getCurrentPreset('VideoSource_1');
      expect(current.token, presets.last.token);
    });

    test('status and capabilities', () async {
      final status = await onvif.imaging.getStatus('VideoSource_1');
      expect(status, isNotNull);

      final capabilities = await onvif.imaging.getServiceCapabilities();
      expect(capabilities, isNotNull);
    });
  });
```

(Verify `Imaging` client signatures in `packages/easy_onvif/lib/src/imaging.dart` — `getPresets` exists? The README lists it; if the client method is missing for `getPresets`, use a low-level `Transport` request for that one. `getCurrentPreset(videoSourceToken)`, `setCurrentPreset({videoSourceToken, presetToken})`, `getStatus(videoSourceToken)` are confirmed present.)

- [ ] **Step 2: Run — verify FAIL** (`onvif.imaging` service faults).

- [ ] **Step 3: Add imaging state to `DeviceState`**

```dart
/// A simulated imaging preset (seeded from settings).
class ImagingPreset {
  final String token;
  final String name;
  final String type;

  const ImagingPreset({required this.token, required this.name, required this.type});
}

// Fields on DeviceState:
  final List<ImagingPreset> imagingPresets = [];
  String? currentImagingPreset;
```

`OnvifDevice`'s constructor seeds `state.imagingPresets` from `settings.imagingPresets` and sets `currentImagingPreset` to the first token.

- [ ] **Step 4: Implement `lib/src/services/imaging_service.dart`**

`OnvifService` for `Xmlns.timg`; `isPreAuth` → `GetServiceCapabilities`. Constructor takes `DeviceState state`. Handlers (wrapper `timg`, type children `tt`):

- `GetServiceCapabilities` → `Capabilities(timg)` attributes `ImageStabilization="false" Presets="true" AdaptablePreset="false"`.
- `GetPresets` → per `state.imagingPresets`: `Preset(timg, token=<token>, type=<type>) > timg:Name <name>`.
- `GetCurrentPreset` → the current preset in the same single-`Preset` shape (or empty response body element if none).
- `SetCurrentPreset` → params `VideoSourceToken`, `PresetToken`; unknown preset → fault `NoConfig`; else set `state.currentImagingPreset`; empty `SetCurrentPresetResponse`.
- `GetStatus` → `GetStatusResponse > timg:Status > tt:FocusStatus20 > tt:Position 0.5, tt:MoveStatus IDLE, tt:Error` (empty Error element omitted; check the client's `ImagingStatus20.fromJson` required fields and match).

- [ ] **Step 5: Register in `OnvifDevice`** when `settings.services.imaging`.

- [ ] **Step 6: Run — verify PASS** (`flutter test test/coverage_integration_test.dart`), full suite, **commit**:

```bash
git add lib/src/services/imaging_service.dart lib/src/hardware/device_state.dart lib/src/onvif_device.dart test/coverage_integration_test.dart
git commit -m "feat(server): imaging service with settings-seeded presets"
```

---

### Task 14: Geolocation fallback, UI recording row, bundled settings, README

**Files:**
- Modify: `lib/src/services/device_service.dart` (geo fallback)
- Modify: `lib/main.dart` (load settings, recording status row)
- Create: `assets/settings.yaml`
- Modify: `pubspec.yaml` (assets entry), `README.md`

- [ ] **Step 1: Geolocation fallback**

In `DeviceService._getGeoLocation`, when `hardware.currentLocation()` returns `null`, fall back to `settings.geoFallback` (may still be null → empty response, current behavior).

- [ ] **Step 2: Bundled `assets/settings.yaml`**

Create with every key present but commented, matching parse defaults:

```yaml
# easy_onvif_server settings.
# Runtime override: ~/.easy_onvif_server/settings.yaml
#
# device:
#   manufacturer: easy_onvif
#   model: Dart ONVIF Server
#   firmware: 0.1.0
#   serial: EASY-ONVIF-SERVER-0001
#   hardwareId: "1"
#   hostname: easy-onvif-server
# network:
#   httpPort: 8080
#   rtspPort: 8554
# auth:
#   username: admin
#   password: admin
# services:
#   recording: true
#   replay: true
#   search: true
#   imaging: true
# recording:
#   directory: /path/to/recordings   # default: system temp
#   segmentSeconds: 10
#   maxRetentionMinutes: 60
# imaging:
#   presets:
#     - token: ImagingPreset_1
#       name: Standard
#       type: Auto
# geolocation:
#   lat: 43.65
#   lon: -79.38
#   elevation: 76.0
```

Register in `pubspec.yaml` under `flutter:` → `assets:` → `- assets/settings.yaml`.

- [ ] **Step 3: Load settings in `main.dart`**

In `_ServerHomePageState._start()`, before constructing the device:

```dart
      final bundled = await rootBundle.loadString('assets/settings.yaml');
      final settings = await ServerSettings.load(fallbackYaml: bundled);
```

Pass `settings: settings` into `OnvifDevice(...)` and use `settings.config` instead of the hard-coded `_config` (keep `_config` as the pre-start display default; after start, read ports from `settings.config`).

- [ ] **Step 4: Recording status row**

In the `_StatusCard` (or a small new `_RecordingStatusCard` below it), when the device is running and recording is enabled show: number of recordings (`device.recordingManager?.recordings.length`), whether any job is `Active`, and the replay URL template `rtsp://<host>:<rtspPort>/onvif/replay/<recordingToken>`. Expose `RecordingManager? get recordingManager` on `OnvifDevice`. Follow the existing card widget style in `main.dart` (SelectableText rows). Refresh via the existing preview timer/setState cycle — no new state management.

- [ ] **Step 5: README**

Update `server/README.md`: new services table (Device/Media1/Media2/PTZ/Imaging/Recording/Search/Replay), the settings file schema and search order, recording storage layout, and the replay URL scheme.

- [ ] **Step 6: Verify**

Run: `flutter analyze && flutter test` — all green.
Run: `flutter build macos --debug` — builds.

- [ ] **Step 7: Commit**

```bash
git add lib/main.dart lib/src/services/device_service.dart assets/settings.yaml pubspec.yaml README.md lib/src/onvif_device.dart
git commit -m "feat(server): settings asset, geo fallback and recording status UI"
```

---

### Task 15: Final verification sweep

- [ ] **Step 1: Full static + test pass**

```bash
flutter analyze          # expected: No issues found
flutter test             # expected: all tests pass (old 16 + new suites)
```

- [ ] **Step 2: Coverage cross-check against the README matrix**

For each operation listed under "Supported Onvif Operations" in `packages/easy_onvif/README.md`, confirm a `case` exists in the corresponding service (`grep -n "case '" lib/src/services/*.dart`). Expected sets:
- Device: CreateUsers, DeleteUsers, GetCapabilities, GetDeviceInformation, GetDiscoveryMode, GetDNS, GetEndpointReference, GetHostname, GetIPAddressFilter, GetNetworkProtocols, GetNTP, GetServiceCapabilities, GetServices, GetStorageConfiguration, GetStorageConfigurations, GetSystemDateAndTime, GetSystemUris, GetSystemLog, GetSystemSupportInformation, GetUsers, SystemReboot (+GetGeoLocation)
- Imaging: GetCurrentPreset, GetPresets, GetServiceCapabilities, GetStatus, SetCurrentPreset
- Media1: GetAudioSources, GetMetadataConfiguration, GetMetadataConfigurations, GetProfile, GetProfiles, GetServiceCapabilities, GetSnapshotUri, GetStreamUri, GetVideoSources, StartMulticastStreaming, StopMulticastStreaming
- Media2: GetMetadataConfigurationOptions, GetMetadataConfigurations, GetProfiles, GetServiceCapabilities, GetSnapshotUri, GetStreamUri, GetVideoEncoderInstances, GetVideoSourceConfigurationOptions, GetVideoEncoderConfigurations, StartMulticastStreaming, StopMulticastStreaming
- PTZ: unchanged (already complete except preset tours — GetPresetTour/GetPresetTours return an empty-list response: add two trivial cases `GetPresetTours` → empty `GetPresetToursResponse` and `GetPresetTour` → fault `NoToken`, matching devices that support the call but have no tours)
- Recording: CreateRecording, CreateRecordingJob, DeleteRecording, DeleteRecordingJob, GetRecordingJobs, GetRecordingJobState, GetRecordingOptions, GetRecordings, GetServiceCapabilities, SetRecordingJobMode
- Replay: GetReplayConfiguration, GetReplayUri, GetServiceCapabilities, SetReplayConfiguration
- Search: FindRecordings, GetRecordingSearchResults, GetRecordingInformation, GetRecordingSummary

If the PTZ preset-tour cases were not yet added, add them now with a matching assertion in `test/media_ptz_integration_test.dart`.

- [ ] **Step 3: Manual smoke (optional, macOS)**

`flutter run -d macos` → start server → VLC plays `rtsp://<host>:8554/onvif/Profile_1`; create a recording via `onvif` CLI or test; VLC plays `rtsp://<host>:8554/onvif/replay/OnvifRecordingToken_1`.

- [ ] **Step 4: Final commit (if Step 2 produced changes)**

```bash
git add lib/src/services/ptz_service.dart test/media_ptz_integration_test.dart
git commit -m "feat(server): ptz preset tour stubs complete README coverage"
```

---

## Self-Review Notes

- **Spec coverage:** Design §1 → Tasks 1–3, 14 (settings, flags, geo fallback). §2 → Tasks 6–9 (nalSource, store, recorder, manager/service). §3 → Tasks 10–12 (FileH264Source, RTSP routing, replay, search). §4 → Tasks 4, 5, 13, 14, 15 (device/media gaps, imaging, UI, tests). All README operations mapped in Task 15's checklist.
- **Known client quirk:** `Recordings.deleteRecordingJob` sends `DeleteRecording` (client bug at `recordings.dart:132`); tests avoid it by using `setRecordingJobMode(Idle)`.
- **Type consistency:** `NalStreamSource`/`H264NalUnit`/`AccessUnitFramer`/`AnnexBSplitter` from `h264_source.dart`; `FileH264Source.start/stop`; `RecordingManager.store` is public (used by the replay resolver and DeviceService storage path). `SegmentRecorder` takes `store` for retention pruning.
- **Port allocation:** integration tests use unique port pairs (8095–8099 / 8561–8565) to allow parallel/sequential runs without clashes with existing tests (8090s range used by current suite — verify no overlap with `device_integration_test.dart`/`media_ptz_integration_test.dart` ports before finalizing each test file).
- **Client model verification steps are built into each test-writing step**: where the plan could not guarantee a model's exact field names, the step says to check the specific client file first and keep the assertion meaning. Response *shapes* always defer to the fixtures under `packages/easy_onvif/test/xml/` on conflict.
