/// MCP facade for the ONVIF client.
///
/// [EasyOnvifMcpServer] exposes the generic ONVIF services (device management,
/// media, PTZ, imaging, recordings, replay, search) as MCP tools through the
/// `easy_api_annotations` package. The class is annotated with
/// `@Server(transport: McpTransport.stdio)`, so `build_runner` generates a
/// stdio dispatcher at `easy_onvif_mcp_server.mcp.dart` — run it with
/// `bin/easy_onvif_mcp_server.dart`.
///
/// The generated dispatcher constructs a fresh server instance per tool call,
/// which is why the device connection, the dispatch lock and the host hooks are
/// all `static`.
///
/// This class must stay free of `dart:io`: the same code is imported by the
/// Node.js entry that is compiled with `dart compile js` for the
/// `easy-onvif-mcp` npm package. Host-specific pieces (Dio adapter, discovery
/// probe, credentials file) are injected through the static hooks below.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_api_annotations/mcp_annotations.dart';
import 'package:easy_onvif/media1.dart' as m1;
import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/ptz.dart';
import 'package:easy_onvif/shared.dart';
import 'package:loggy/loggy.dart';

import 'json_safe.dart';

/// Environment variable holding the device host (optionally `host:port`).
const String envHost = 'ONVIF_HOST';

/// Environment variable holding the device username.
const String envUsername = 'ONVIF_USERNAME';

/// Environment variable holding the device password.
const String envPassword = 'ONVIF_PASSWORD';

/// Unified MCP facade exposing ONVIF devices as tools.
@Server(transport: McpTransport.stdio, toolPrefix: 'onvif_', logErrors: true)
class EasyOnvifMcpServer {
  /// Creates an HTTP client for the current host.
  ///
  /// The Node.js entry overrides this with a fetch-backed adapter, because the
  /// compiled default adapter expects `XMLHttpRequest`.
  static DioFactory dioFactory = defaultDio;

  /// WS-Discovery probe for the current host, in seconds of listening time.
  ///
  /// Injected by each entry point: the Dart VM uses the io multicast probe, the
  /// Node.js entry the `node:dgram` one. Defaults to unsupported.
  static Future<List<Map<String, dynamic>>> Function(int seconds)? probeHook;

  /// Extra credentials source, e.g. the `easy_onvif_cli` config file.
  ///
  /// The Dart VM entry supplies a reader for `~/.onvif/credentials.json`; a
  /// compiled Node process has no reliable home directory, so it leaves this
  /// null and relies on the environment.
  static Future<Map<String, String>?> Function()? credentialsHook;

  /// The live device connection, shared across the per-call instances the
  /// generated dispatcher creates.
  static Onvif? _client;

  /// In-flight connection attempt, so a burst of calls triggers one connect.
  static Future<Onvif>? _connectFlight;

  /// Tail of the dispatch queue.
  ///
  /// ponytail: `Transport.timeDelta` and `Transport.builder` are static inside
  /// `easy_onvif`, so two in-flight SOAP requests corrupt each other's
  /// WS-Security timestamp and XML fragment. Serializing every call keeps the
  /// protocol correct at the cost of throughput, and pins this server to one
  /// device per process.
  static Future<void> _dispatchTail = Future<void>.value();

  /// Canonical acknowledgement for tools that have no natural return value.
  static const Map<String, dynamic> _ok = <String, dynamic>{'ok': true};

  static Dio defaultDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Queues [body] behind every previously dispatched tool call.
  ///
  /// Re-entrant: a tool that serializes a unit of work may still call helpers
  /// that serialize themselves (e.g. `ensureConnected`) without deadlocking.
  static Future<T> _serialized<T>(Future<T> Function() body) {
    if (Zone.current[_lockToken] == true) return Future<T>.sync(body);
    final result = _dispatchTail.then(
      (_) => runZoned(body, zoneValues: {_lockToken: true}),
    );
    _dispatchTail = result.then((_) {}, onError: (_) {});
    return result;
  }

  static final Object _lockToken = Object();

  /// Runs [body] as one serialized unit.
  ///
  /// Hosts that wrap a whole tool call (the Node.js registry does) use this so
  /// the lock spans both the implicit connect and the device request.
  static Future<T> serializedCall<T>(Future<T> Function() body) =>
      _serialized(body);

  /// The live connection, bootstrapping it on first use.
  static Future<Onvif> _onvif() => _serialized(() async {
    final client = _client;
    if (client != null) return client;
    return _connectFlight ??= _bootstrap().whenComplete(() {
      _connectFlight = null;
    });
  });

  /// A tool body that runs against the connected device, serialized.
  static Future<Object?> _read(FutureOr<Object?> Function(Onvif onvif) body) =>
      _serialized(() async => jsonSafe(await body(await _onvif())));

  static Future<Onvif> _bootstrap() async {
    final credentials = await _resolveCredentials();
    return _connect(
      host: credentials['host']!,
      username: credentials['username']!,
      password: credentials['password']!,
    );
  }

  static Future<Onvif> _connect({
    required String host,
    required String username,
    required String password,
  }) async {
    await _close();
    final onvif = await Onvif.connect(
      host: host,
      username: username,
      password: password,
      // stdout carries the JSON-RPC stream, and the SOAP interceptor chain is
      // chatty even at debug level, so logging is silenced entirely.
      logOptions: const LogOptions(LogLevel.off, stackTraceLevel: LogLevel.off),
      printer: _StderrPrinter(),
      dio: dioFactory(),
    );
    _client = onvif;
    return onvif;
  }

  static Future<void> _close() async {
    final client = _client;
    _client = null;
    _connectFlight = null;
    if (client != null) client.transport.dio.close(force: true);
  }

  // ---------------------------------------------------------------------------
  // Public host surface.
  //
  // The generated dispatcher only needs the annotated methods above. These
  // statics exist because the Node.js bundle runs its own registry (the
  // generated dispatcher imports `dart:io` and cannot be compiled with
  // `dart compile js`) and has to drive the same connection state.
  // ---------------------------------------------------------------------------

  /// Whether a device connection is currently held.
  static bool get hasClient => _client != null;

  /// The live connection, bootstrapping it on first use.
  static Future<Onvif> ensureConnected() => _onvif();

  /// Connects with explicit credentials, replacing any existing connection.
  static Future<Onvif> connectTo({
    required String host,
    required String username,
    required String password,
  }) => _serialized(
    () => _connect(host: host, username: username, password: password),
  );

  /// Closes the current device connection, if any.
  static Future<void> disconnectDevice() => _serialized(_close);

  /// Runs the host WS-Discovery probe.
  static Future<List<Map<String, dynamic>>> probeDevices(int seconds) async {
    final hook = probeHook;
    if (hook == null) {
      throw UnsupportedError('WS-Discovery is not available on this host.');
    }
    return hook(seconds);
  }

  /// Merges the host credential source with the environment, environment
  /// winning, and reports which field is missing rather than echoing values.
  static Future<Map<String, String>> _resolveCredentials() async {
    final resolved = <String, String>{};

    final fromHook = await credentialsHook?.call();
    if (fromHook != null) resolved.addAll(fromHook);

    for (final entry in {
      'host': envHost,
      'username': envUsername,
      'password': envPassword,
    }.entries) {
      final value = _env(entry.value);
      if (value != null && value.isNotEmpty) resolved[entry.key] = value;
    }

    for (final key in ['host', 'username', 'password']) {
      if (resolved[key] == null || resolved[key]!.isEmpty) {
        throw StateError(
          'No $key for the device. Set $envHost / $envUsername / $envPassword, '
          'or call onvif_connect.',
        );
      }
    }
    return resolved;
  }

  /// Environment lookup, replaceable by the Node.js entry.
  static String? Function(String name) envReader = _defaultEnv;

  static String? _defaultEnv(String name) => null;

  static String? _env(String name) => envReader(name);

  // ===========================================================================
  // Connection lifecycle
  // ===========================================================================

  /// Connects to an ONVIF device and discovers its services.
  ///
  /// The password is never a tool argument: it is read from `ONVIF_PASSWORD` or
  /// the host credential source. Echoing a rejected value is how credentials
  /// leak into a model transcript (numeric default passwords are common), so
  /// there is nothing here to echo.
  @Tool(
    name: 'connect',
    description:
        'Connect to an ONVIF device and discover its services. The password '
        'comes from ONVIF_PASSWORD (or the ~/.onvif/credentials.json file on '
        'the Dart VM), never from a tool argument.',
  )
  Future<Map<String, dynamic>> connect({
    @Parameter(
      title: 'Host',
      description:
          'Device host, optionally with a port or scheme, e.g. 192.168.1.10:8080.',
      example: '192.168.1.10',
    )
    required String host,
    @Parameter(
      title: 'Username',
      description: 'Device username.',
      example: 'admin',
    )
    required String username,
  }) => _serialized(() async {
    final password =
        _env(envPassword) ?? (await credentialsHook?.call())?['password'];
    if (password == null || password.isEmpty) {
      throw StateError(
        'No device password. Set $envPassword before calling onvif_connect.',
      );
    }
    final onvif = await _connect(
      host: host,
      username: username,
      password: password,
    );
    return <String, dynamic>{
      'connected': true,
      'host': onvif.authInfo.host,
      'services': onvif.serviceMap.keys.toList(),
    };
  });

  /// Closes the current device connection.
  @Tool(name: 'disconnect', description: 'Close the current device connection.')
  Future<Map<String, dynamic>> disconnect() => _serialized(() async {
    await _close();
    return <String, dynamic>{'connected': false};
  });

  /// Reports whether a device connection is held.
  @Tool(
    name: 'is_connected',
    description: 'Return whether a device connection is currently held.',
  )
  bool isConnected() => _client != null;

  /// Reports the connection and the discovered services.
  @Tool(
    name: 'status',
    description:
        'Report whether a device is connected and which services were discovered.',
  )
  Future<Map<String, dynamic>> status() => _serialized(() async {
    final client = _client;
    if (client == null) return <String, dynamic>{'connected': false};
    return <String, dynamic>{
      'connected': true,
      'host': client.authInfo.host,
      'services': client.serviceMap.keys.toList(),
    };
  });

  /// WS-Discovery multicast probe.
  @Tool(
    name: 'probe',
    description:
        'WS-Discovery multicast probe. Finds ONVIF devices on the local '
        'network without needing credentials.',
  )
  Future<Map<String, dynamic>> probe({
    @Parameter(
      title: 'Timeout',
      description: 'Seconds to listen for probe responses (default 2).',
      example: 2,
    )
    int? timeout,
  }) => _serialized(() async {
    final hook = probeHook;
    if (hook == null) {
      throw UnsupportedError('WS-Discovery is not available on this host.');
    }
    final devices = await hook(timeout ?? 2);
    return <String, dynamic>{'devices': devices, 'count': devices.length};
  });

  // ===========================================================================
  // Device management (read-only)
  // ===========================================================================

  /// Manufacturer, model, firmware, serial number and hardware id.
  @Tool(
    name: 'get_device_information',
    description:
        'Manufacturer, model, firmware, serial number and hardware id of the device.',
  )
  Future<Object?> getDeviceInformation() =>
      _read((onvif) => onvif.deviceManagement.getDeviceInformation());

  /// The services the device implements, with endpoint URLs.
  @Tool(
    name: 'get_services',
    description:
        'The services the device implements, with their endpoint URLs.',
  )
  Future<Object?> getServices() => _read(
    (onvif) => onvif.deviceManagement.getServices(includeCapability: true),
  );

  /// The full capability report.
  @Tool(
    name: 'get_capabilities',
    description: 'The full device capability report (all categories).',
  )
  Future<Object?> getCapabilities() =>
      _read((onvif) => onvif.deviceManagement.getCapabilities());

  /// The device clock.
  @Tool(
    name: 'get_system_date_and_time',
    description:
        'The device clock, including whether it is NTP or manually set.',
  )
  Future<Object?> getSystemDateAndTime() =>
      _read((onvif) => onvif.deviceManagement.getSystemDateAndTime());

  /// Hostname and whether it is DHCP-assigned.
  @Tool(
    name: 'get_hostname',
    description: 'The device hostname and whether it is DHCP-assigned.',
  )
  Future<Object?> getHostname() =>
      _read((onvif) => onvif.deviceManagement.getHostname());

  /// DNS configuration.
  @Tool(name: 'get_dns', description: 'The device DNS configuration.')
  Future<Object?> getDns() => _read((onvif) => onvif.deviceManagement.getDns());

  /// NTP configuration.
  @Tool(name: 'get_ntp', description: 'The device NTP configuration.')
  Future<Object?> getNtp() => _read((onvif) => onvif.deviceManagement.getNtp());

  /// Dynamic DNS settings.
  @Tool(
    name: 'get_dynamic_dns',
    description: 'The device dynamic DNS settings (type, name, TTL).',
  )
  Future<Object?> getDynamicDns() =>
      _read((onvif) => onvif.deviceManagement.getDynamicDns());

  /// Configured network protocols.
  @Tool(
    name: 'get_network_protocols',
    description: 'Configured network protocols with ports and enabled flags.',
  )
  Future<Object?> getNetworkProtocols() =>
      _read((onvif) => onvif.deviceManagement.getNetworkProtocols());

  /// Registered users and access levels.
  @Tool(
    name: 'get_users',
    description: 'The registered device users and their access levels.',
  )
  Future<Object?> getUsers() =>
      _read((onvif) => onvif.deviceManagement.getUsers());

  /// Relay outputs and their settings.
  @Tool(
    name: 'get_relay_outputs',
    description: 'The available relay outputs and their settings.',
  )
  Future<Object?> getRelayOutputs() =>
      _read((onvif) => onvif.deviceManagement.getRelayOutputs());

  /// Storage configurations.
  @Tool(
    name: 'get_storage_configurations',
    description:
        'The storage configurations (SD cards, mounts) the device reports.',
  )
  Future<Object?> getStorageConfigurations() =>
      _read((onvif) => onvif.deviceManagement.getStorageConfigurations());

  /// Discovery mode.
  @Tool(
    name: 'get_discovery_mode',
    description:
        'The discovery mode of the device (e.g. Discoverable / DiscoverableInUse).',
  )
  Future<Object?> getDiscoveryMode() =>
      _read((onvif) => onvif.deviceManagement.getDiscoveryMode());

  /// Endpoint reference of the device service.
  @Tool(
    name: 'get_endpoint_reference',
    description:
        'The device service endpoint reference, used to derive the password '
        'equivalent for remote user operation.',
  )
  Future<Object?> getEndpointReference() =>
      _read((onvif) => onvif.deviceManagement.getEndpointReference());

  // ===========================================================================
  // Media
  // ===========================================================================

  /// All media profiles, or one by reference token.
  @Tool(
    name: 'get_profiles',
    description:
        'All media profiles. Every other media and PTZ tool needs a '
        '`profile_token` from this list.',
  )
  Future<Object?> getProfiles({
    @Parameter(
      title: 'Reference Token',
      description: 'Optional profile token to fetch a single profile.',
    )
    String? referenceToken,
  }) =>
      _read((onvif) => onvif.media.getProfiles(referenceToken: referenceToken));

  /// A single Media1 profile by token.
  @Tool(
    name: 'get_profile',
    description:
        'A single media profile by token, as reported by the Media1 service of '
        'the device. Use onvif_get_profiles on Media2-only devices.',
  )
  Future<Object?> getProfile({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
  }) => _read((onvif) => onvif.media.getProfile(profileToken));

  /// The RTSP URI for a live stream.
  @Tool(
    name: 'get_stream_uri',
    description:
        'The RTSP URI for a live stream from the given profile, with credentials '
        'embedded where the device allows it.',
  )
  Future<Object?> getStreamUri({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
  }) => _read(
    (onvif) async => {'uri': await onvif.media.getStreamUri(profileToken)},
  );

  /// The JPEG snapshot URI for a profile.
  @Tool(
    name: 'get_snapshot_uri',
    description: 'The URI that returns a JPEG snapshot for the given profile.',
  )
  Future<Object?> getSnapshotUri({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
  }) => _read(
    (onvif) async => {'uri': await onvif.media.getSnapshotUri(profileToken)},
  );

  /// Physical video inputs (Media1).
  @Tool(
    name: 'get_video_sources',
    description:
        'The physical video inputs available on the device (Media1 only).',
  )
  Future<Object?> getVideoSources() =>
      _read((onvif) => onvif.media.getVideoSources());

  /// Physical audio inputs (Media1).
  @Tool(
    name: 'get_audio_sources',
    description:
        'The physical audio inputs available on the device (Media1 only).',
  )
  Future<Object?> getAudioSources() =>
      _read((onvif) => onvif.media.getAudioSources());

  /// Media service capabilities.
  @Tool(
    name: 'get_media_service_capabilities',
    description: 'The capabilities of the device Media service.',
  )
  Future<Object?> getMediaServiceCapabilities() =>
      _read((onvif) => onvif.media.getServiceCapabilities());

  // ===========================================================================
  // PTZ
  // ===========================================================================

  /// Current PTZ position and movement state.
  @Tool(
    name: 'ptz_get_status',
    description: 'The current PTZ position and movement state.',
  )
  Future<Object?> ptzGetStatus({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
  }) => _read((onvif) => onvif.ptz.getStatus(profileToken));

  /// Saved PTZ presets.
  @Tool(
    name: 'ptz_get_presets',
    description: 'All saved PTZ presets for the profile, with their tokens.',
  )
  Future<Object?> ptzGetPresets({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(
      title: 'Limit',
      description: 'Maximum presets to return (default 100).',
    )
    int? limit,
  }) => _read((onvif) => onvif.ptz.getPresets(profileToken, limit: limit));

  /// PTZ configurations.
  @Tool(
    name: 'ptz_get_configurations',
    description: 'All PTZ configurations defined on the device.',
  )
  Future<Object?> ptzGetConfigurations() =>
      _read((onvif) => onvif.ptz.getConfigurations());

  /// Move to a saved preset.
  @Tool(
    name: 'ptz_goto_preset',
    description: 'Move the camera to a saved preset.',
  )
  Future<Map<String, dynamic>> ptzGotoPreset({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(
      title: 'Preset Token',
      description: 'Preset token, from onvif_ptz_get_presets.',
    )
    required String presetToken,
  }) => _write(
    (onvif) => onvif.ptz.gotoPreset(profileToken, presetToken: presetToken),
  );

  /// Save the current position as a preset.
  @Tool(
    name: 'ptz_set_preset',
    description:
        'Save the current camera position as a preset. Returns the preset token.',
  )
  Future<Object?> ptzSetPreset({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(title: 'Preset Name', description: 'Human readable preset name.')
    String? presetName,
    @Parameter(
      title: 'Preset Token',
      description: 'Existing token to overwrite instead of creating one.',
    )
    String? presetToken,
  }) => _read(
    (onvif) async => {
      'preset_token': await onvif.ptz.setPreset(
        profileToken,
        presetName: presetName,
        presetToken: presetToken,
      ),
    },
  );

  /// Delete a preset.
  @Tool(name: 'ptz_remove_preset', description: 'Delete a saved preset.')
  Future<Map<String, dynamic>> ptzRemovePreset({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(title: 'Preset Token', description: 'Preset token to remove.')
    required String presetToken,
  }) => _write(
    (onvif) => onvif.ptz.removePreset(
      profileToken,
      preset: Preset.fromToken(presetToken),
    ),
  );

  /// Absolute move.
  @Tool(
    name: 'ptz_absolute_move',
    description:
        'Move pan/tilt/zoom to an absolute position in the profile coordinate '
        'space (typically -1.0 to 1.0 for pan/tilt).',
  )
  Future<Map<String, dynamic>> ptzAbsoluteMove({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(title: 'Pan', description: 'Target pan position.')
    required double panTiltX,
    @Parameter(title: 'Tilt', description: 'Target tilt position.')
    required double panTiltY,
    @Parameter(title: 'Zoom', description: 'Target zoom position.')
    double? zoom,
  }) => _write(
    (onvif) => onvif.ptz.absoluteMove(
      profileToken,
      position: _ptzVector(panTiltX, panTiltY, zoom),
    ),
  );

  /// Relative move.
  @Tool(
    name: 'ptz_relative_move',
    description:
        'Move pan/tilt/zoom by a relative amount from the current position.',
  )
  Future<Map<String, dynamic>> ptzRelativeMove({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(title: 'Pan Delta', description: 'Pan translation to apply.')
    required double panTiltX,
    @Parameter(title: 'Tilt Delta', description: 'Tilt translation to apply.')
    required double panTiltY,
    @Parameter(title: 'Zoom Delta', description: 'Zoom translation to apply.')
    double? zoom,
  }) => _write(
    (onvif) => onvif.ptz.relativeMove(
      profileToken,
      _ptzVector(panTiltX, panTiltY, zoom),
      null,
    ),
  );

  /// Continuous move.
  @Tool(
    name: 'ptz_continuous_move',
    description:
        'Move at a constant velocity until stopped. Pair with onvif_ptz_stop '
        '(or pass a timeout where the device honours one).',
  )
  Future<Map<String, dynamic>> ptzContinuousMove({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(
      title: 'Pan Velocity',
      description: 'Pan velocity (-1.0 to 1.0).',
    )
    double? panTiltX,
    @Parameter(
      title: 'Tilt Velocity',
      description: 'Tilt velocity (-1.0 to 1.0).',
    )
    double? panTiltY,
    @Parameter(
      title: 'Zoom Velocity',
      description: 'Zoom velocity (-1.0 to 1.0).',
    )
    double? zoom,
    @Parameter(
      title: 'Timeout',
      description: 'Optional device-side timeout, seconds.',
    )
    int? timeout,
  }) => _write(
    (onvif) => onvif.ptz.continuousMove(
      profileToken,
      velocity: PtzSpeed(
        panTilt: Vector2D(x: panTiltX ?? 0, y: panTiltY ?? 0),
        zoom: zoom == null ? null : Vector1D(x: zoom),
      ),
      timeout: timeout,
    ),
  );

  /// Stop movement.
  @Tool(
    name: 'ptz_stop',
    description: 'Stop ongoing pan/tilt and/or zoom movement.',
  )
  Future<Map<String, dynamic>> ptzStop({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(
      title: 'Stop Pan/Tilt',
      description: 'Stop pan/tilt (default true).',
    )
    bool? panTilt,
    @Parameter(title: 'Stop Zoom', description: 'Stop zoom (default true).')
    bool? zoom,
  }) => _write(
    (onvif) => onvif.ptz.stop(
      profileToken,
      panTilt: panTilt ?? true,
      zoom: zoom ?? true,
    ),
  );

  /// One directional step with fallback.
  @Tool(
    name: 'ptz_move',
    description:
        'One small step in a direction, with automatic fallback when the device '
        'rejects relative moves. Use for "pan left a little" style commands.',
  )
  Future<Map<String, dynamic>> ptzMove({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(
      title: 'Pan Delta',
      description: 'Pan delta; positive pans right (default 0.025).',
    )
    double? x,
    @Parameter(
      title: 'Tilt Delta',
      description: 'Tilt delta; positive tilts up (default 0.025).',
    )
    double? y,
    @Parameter(title: 'Zoom Delta', description: 'Zoom delta (default 0).')
    double? zoom,
  }) => _write(
    (onvif) => onvif.ptz.move(
      profileToken,
      direction: Vector2D(x: x ?? 0.025, y: y ?? 0.025),
      zoom: zoom == null ? null : Vector1D(x: zoom),
    ),
  );

  /// Tilt up one step.
  @Tool(name: 'ptz_move_up', description: 'Tilt the camera up by one step.')
  Future<Map<String, dynamic>> ptzMoveUp({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(
      title: 'Step',
      description: 'Magnitude of the step; omit to use the device default.',
    )
    double? step,
  }) => _write(
    (onvif) => step == null
        ? onvif.ptz.moveUp(profileToken)
        : onvif.ptz.moveUp(profileToken, step),
  );

  /// Tilt down one step.
  @Tool(name: 'ptz_move_down', description: 'Tilt the camera down by one step.')
  Future<Map<String, dynamic>> ptzMoveDown({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(
      title: 'Step',
      description: 'Magnitude of the step; omit to use the device default.',
    )
    double? step,
  }) => _write(
    (onvif) => step == null
        ? onvif.ptz.moveDown(profileToken)
        : onvif.ptz.moveDown(profileToken, step),
  );

  /// Pan left one step.
  @Tool(name: 'ptz_move_left', description: 'Pan the camera left by one step.')
  Future<Map<String, dynamic>> ptzMoveLeft({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(
      title: 'Step',
      description: 'Magnitude of the step; omit to use the device default.',
    )
    double? step,
  }) => _write(
    (onvif) => step == null
        ? onvif.ptz.moveLeft(profileToken)
        : onvif.ptz.moveLeft(profileToken, step),
  );

  /// Pan right one step.
  @Tool(
    name: 'ptz_move_right',
    description: 'Pan the camera right by one step.',
  )
  Future<Map<String, dynamic>> ptzMoveRight({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(
      title: 'Step',
      description: 'Magnitude of the step; omit to use the device default.',
    )
    double? step,
  }) => _write(
    (onvif) => step == null
        ? onvif.ptz.moveRight(profileToken)
        : onvif.ptz.moveRight(profileToken, step),
  );

  /// One zoom step.
  @Tool(
    name: 'ptz_zoom',
    description: 'One zoom step. Positive zooms in, negative zooms out.',
  )
  Future<Map<String, dynamic>> ptzZoom({
    @Parameter(title: 'Profile Token', description: 'Media profile token.')
    required String profileToken,
    @Parameter(title: 'Zoom Step', description: 'Zoom step (default 0.025).')
    double? x,
  }) =>
      _write((onvif) => onvif.ptz.zoom(profileToken, Vector1D(x: x ?? 0.025)));

  /// PTZ service capabilities.
  @Tool(
    name: 'ptz_get_service_capabilities',
    description: 'The capabilities of the device PTZ service.',
  )
  Future<Object?> ptzGetServiceCapabilities() =>
      _read((onvif) => onvif.ptz.getServiceCapabilities());

  // ===========================================================================
  // Imaging (read-only)
  // ===========================================================================

  /// Current imaging settings.
  @Tool(
    name: 'imaging_get_status',
    description: 'The current imaging settings for a video source.',
  )
  Future<Object?> imagingGetStatus({
    @Parameter(
      title: 'Video Source Token',
      description: 'Video source token, from onvif_get_video_sources.',
    )
    required String videoSourceToken,
  }) => _read((onvif) => onvif.imaging.getStatus(videoSourceToken));

  /// Imaging presets.
  @Tool(
    name: 'imaging_get_presets',
    description: 'The imaging presets available for a video source.',
  )
  Future<Object?> imagingGetPresets({
    @Parameter(
      title: 'Video Source Token',
      description: 'Video source token, from onvif_get_video_sources.',
    )
    required String videoSourceToken,
  }) => _read((onvif) => onvif.imaging.getPresets(videoSourceToken));

  /// Imaging preset in use.
  @Tool(
    name: 'imaging_get_current_preset',
    description: 'The imaging preset currently applied to a video source.',
  )
  Future<Object?> imagingGetCurrentPreset({
    @Parameter(
      title: 'Video Source Token',
      description: 'Video source token, from onvif_get_video_sources.',
    )
    required String videoSourceToken,
  }) => _read((onvif) => onvif.imaging.getCurrentPreset(videoSourceToken));

  // ===========================================================================
  // Recordings, replay and search
  // ===========================================================================

  /// Recordings stored on the device.
  @Tool(
    name: 'get_recordings',
    description: 'The recordings stored on the device.',
  )
  Future<Object?> getRecordings() =>
      _read((onvif) => onvif.recordings.getRecordings());

  /// Recording jobs.
  @Tool(
    name: 'get_recording_jobs',
    description: 'The recording jobs configured on the device.',
  )
  Future<Object?> getRecordingJobs() =>
      _read((onvif) => onvif.recordings.getRecordingJobs());

  /// Replay URI for a stored recording.
  @Tool(
    name: 'get_replay_uri',
    description: 'The RTSP URI to replay a stored recording.',
  )
  Future<Object?> getReplayUri({
    @Parameter(
      title: 'Recording Token',
      description: 'Recording token, from onvif_get_recordings.',
    )
    required String recordingToken,
  }) => _read(
    (onvif) async => {
      'uri': await onvif.replay.getReplayUri(
        recordingToken,
        streamSetup: m1.StreamSetup(
          stream: 'RTP-Unicast',
          transport: m1.Transport(protocol: 'RTSP'),
        ),
      ),
    },
  );

  /// Summary of available recordings.
  @Tool(
    name: 'get_recording_summary',
    description: 'A summary of the recordings available on the device.',
  )
  Future<Object?> getRecordingSummary() =>
      _read((onvif) => onvif.search.getRecordingSummary());

  /// Start a recording search.
  @Tool(
    name: 'find_recordings',
    description:
        'Starts a recording search and returns the search token. Poll '
        'onvif_get_recording_search_results with that token for matches.',
  )
  Future<Object?> findRecordings({
    @Parameter(
      title: 'Keep Alive Time',
      description: 'How long the search stays alive, in seconds (e.g. 5).',
    )
    required int keepAliveTime,
    @Parameter(
      title: 'Max Matches',
      description: 'Upper bound on matches the device should return.',
    )
    int? maxMatches,
  }) => _read(
    (onvif) async => {
      'search_token': await onvif.search.findRecordings(
        keepAliveTime: keepAliveTime,
        maxMatches: maxMatches,
      ),
    },
  );

  /// Fetch results for a search token.
  @Tool(
    name: 'get_recording_search_results',
    description:
        'Fetches results for a search token from onvif_find_recordings, waiting '
        'up to `wait_time` seconds for more matches to arrive.',
  )
  Future<Object?> getRecordingSearchResults({
    @Parameter(
      title: 'Search Token',
      description: 'Token from onvif_find_recordings.',
    )
    required String searchToken,
    @Parameter(
      title: 'Wait Time',
      description: 'ISO 8601 duration to wait for results, e.g. `PT5S`.',
    )
    String? waitTime,
  }) => _read(
    (onvif) => onvif.search.getRecordingSearchResults(
      searchToken,
      waitTime: waitTime ?? 'PT5S',
    ),
  );

  /// A mutating tool body: serialized, reports `ok`.
  static Future<Map<String, dynamic>> _write(
    FutureOr<Object?> Function(Onvif onvif) body,
  ) => _serialized(() async {
    await body(await _onvif());
    return _ok;
  });

  /// Builds the pan/tilt/zoom vector shared by the move tools.
  static PtzVector _ptzVector(double panTiltX, double panTiltY, double? zoom) =>
      PtzVector(
        panTilt: Vector2D(x: panTiltX, y: panTiltY),
        zoom: zoom == null ? null : Vector1D(x: zoom),
      );
}

/// Sends loggy output to stderr so stdout stays a clean JSON-RPC channel.
final class _StderrPrinter extends LoggyPrinter {
  @override
  void onLog(LogRecord record) =>
      stderrWriteln('${record.level.name}: ${record.message}');
}

/// Diagnostics sink, replaced by the Node.js entry.
void Function(String message) stderrWriteln = (_) {};

/// Builds the HTTP client a host wants; see [EasyOnvifMcpServer.dioFactory].
typedef DioFactory = Dio Function();
