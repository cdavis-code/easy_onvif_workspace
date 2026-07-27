import 'dart:io';

import 'package:loggy/loggy.dart';

import 'config.dart';
import 'discovery/ws_discovery_server.dart';
import 'hardware/device_state.dart';
import 'hardware/hardware_adapter.dart';
import 'log_buffer.dart';
import 'recording/recording_manager.dart';
import 'recording/recording_store.dart';
import 'server/onvif_server.dart';
import 'server/soap_dispatcher.dart';
import 'services/device_service.dart';
import 'services/imaging_service.dart';
import 'services/media1_service.dart';
import 'services/media2_service.dart';
import 'services/onvif_service.dart';
import 'services/ptz_service.dart';
import 'services/recording_service.dart';
import 'services/replay_service.dart';
import 'services/search_service.dart';
import 'settings.dart';
import 'soap/authenticator.dart';
import 'streaming/file_h264_source.dart';
import 'streaming/stream_backend.dart';
import 'webrtc/native_webrtc_session.dart';
import 'webrtc/webrtc_service.dart';

/// Assembles and runs a complete simulated ONVIF device.
///
/// Wires together the device state, hardware abstraction, stream backend, the
/// per-namespace services, the SOAP dispatcher, and the HTTP server. Both the
/// Flutter app (`main.dart`) and the integration tests drive the device
/// through this facade.
class OnvifDevice with UiLoggy {
  final ServerConfig config;
  final HardwareAdapter hardware;
  final StreamBackend streamBackend;
  final DeviceState state;

  /// Simulation settings (service flags, recording options, imaging presets).
  final ServerSettings settings;

  /// The host address advertised to clients (also used to start the stream).
  final String? advertisedHost;

  late final SoapDispatcher dispatcher;
  late final OnvifServer server;

  /// The log ring buffer wrapped around the printer supplied to [start];
  /// backs the `GetSystemLog` operation.
  BufferedLoggyPrinter? _logBuffer;

  /// The on-disk recording store and its SOAP-facing manager, present when
  /// the recording service is enabled.
  RecordingStore? recordingStore;
  RecordingManager? recordingManager;

  /// The WS-Discovery responder, present when discovery is enabled.
  final WsDiscoveryServer? discovery;

  OnvifDevice({
    required this.config,
    required this.hardware,
    required this.streamBackend,
    DeviceState? state,
    ServerSettings? settings,
    bool enableDiscovery = false,
    this.advertisedHost,
  }) : state = state ?? DeviceState(),
       settings = settings ?? const ServerSettings(),
       discovery = enableDiscovery
           ? WsDiscoveryServer(config: config, advertisedHost: advertisedHost)
           : null {
    // Seed the configured administrator account.
    this.state.users.add(
      OnvifUser(
        username: config.username,
        password: config.password,
        level: 'Administrator',
      ),
    );

    // Seed the simulated imaging presets from settings; the first preset is
    // the one initially applied. The client's `GetPresetsResponse` parses the
    // preset list with a `List` cast that only holds for two or more
    // elements, so pad short overrides with the built-in defaults.
    this.state.imagingPresets.addAll([
      for (final preset in this.settings.imagingPresets)
        ImagingPreset(
          token: preset.token,
          name: preset.name,
          type: preset.type,
        ),
    ]);
    for (final fallback in ServerSettings.defaultImagingPresets) {
      if (this.state.imagingPresets.length >= 2) break;
      if (this.state.imagingPresets.any((p) => p.token == fallback.token)) {
        continue;
      }
      this.state.imagingPresets.add(
        ImagingPreset(
          token: fallback.token,
          name: fallback.name,
          type: fallback.type,
        ),
      );
    }
    this.state.currentImagingPreset =
        this.state.imagingPresets.firstOrNull?.token;

    final authenticator = Authenticator(
      expectedUsername: config.username,
      expectedPassword: config.password,
    );

    final recordingsDirectory =
        this.settings.recordingDirectory ??
        '${Directory.systemTemp.path}/easy_onvif_recordings';

    if (this.settings.services.recording) {
      recordingStore = RecordingStore(
        root: Directory(recordingsDirectory),
        maxRetentionMinutes: this.settings.maxRetentionMinutes,
      );
      recordingManager = RecordingManager(
        store: recordingStore!,
        backend: streamBackend,
        settings: this.settings,
      );

      // Let the RTSP server resolve `/onvif/replay/<token>` sessions to
      // file-backed sources reading the recording's segments.
      streamBackend.replaySourceFor = (recordingToken, startUtc) async {
        final index = recordingStore!.byToken(recordingToken);

        if (index == null) return null;

        return FileH264Source(index: index, startUtc: startUtc);
      };
    }

    final webrtcService = WebrtcService(
      media: this.settings.media,
      sessionFactory: (send) =>
          NativeWebrtcSession(media: this.settings.media, send: send),
    );

    final List<OnvifService> services = [
      DeviceService(
        config: config,
        state: this.state,
        hardware: hardware,
        settings: this.settings,
        logLines: () => _logBuffer?.lines ?? const <String>[],
        recordingDirectory: recordingsDirectory,
      ),
      Media1Service(
        config: config,
        state: this.state,
        streamBackend: streamBackend,
        audioEnabled: this.settings.media.audioEnabled,
      ),
      Media2Service(
        config: config,
        state: this.state,
        streamBackend: streamBackend,
        webrtcService: webrtcService,
      ),
      PtzService(state: this.state),
      if (this.settings.services.imaging) ImagingService(state: this.state),
      if (recordingManager != null)
        RecordingService(manager: recordingManager!),
      if (recordingManager != null && this.settings.services.replay)
        ReplayService(config: config, manager: recordingManager!),
      if (recordingManager != null && this.settings.services.search)
        SearchService(manager: recordingManager!),
    ];

    dispatcher = SoapDispatcher(
      services: services,
      authenticator: authenticator,
    );

    server = OnvifServer(
      config: config,
      dispatcher: dispatcher,
      hardware: hardware,
      streamBackend: streamBackend,
      webrtcService: webrtcService,
    );
  }

  /// The port the SOAP server is bound to (after [start]).
  int? get port => server.port;

  Future<void> start({
    LogOptions logOptions = const LogOptions(LogLevel.info),
    LoggyPrinter printer = const PrettyPrinter(showColors: false),
  }) async {
    // Initialize logging up front so the hardware adapter (which logs during
    // camera startup) has a configured loggy. The printer is wrapped in a
    // ring buffer so `GetSystemLog` can return real device log lines.
    final bufferedPrinter = BufferedLoggyPrinter(printer);
    _logBuffer = bufferedPrinter;

    Loggy.initLoggy(logPrinter: bufferedPrinter, logOptions: logOptions);

    // Recordings persist across restarts; load the index before serving.
    await recordingStore?.open();

    await hardware.startCamera();
    await server.start(logOptions: logOptions, printer: bufferedPrinter);
    await discovery?.start();

    // Start the RTSP stream eagerly so it is reachable immediately (e.g. by
    // VLC) rather than only after a client happens to call GetStreamUri.
    try {
      await streamBackend.start(
        DeviceState.profileToken,
        host: advertisedHost ?? 'localhost',
      );
    } catch (error) {
      // Streaming is best-effort: the SOAP device must still come up if the
      // camera or encoder is unavailable.
      loggy.warning('Stream backend failed to start: $error');
    }
  }

  Future<void> stop() async {
    state.dispose();
    await recordingManager?.dispose();
    await discovery?.stop();
    await streamBackend.stop();
    await hardware.stopCamera();
    await server.stop();
  }
}
