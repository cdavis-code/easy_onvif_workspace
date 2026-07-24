import 'package:loggy/loggy.dart';

import 'config.dart';
import 'discovery/ws_discovery_server.dart';
import 'hardware/device_state.dart';
import 'hardware/hardware_adapter.dart';
import 'server/onvif_server.dart';
import 'server/soap_dispatcher.dart';
import 'services/device_service.dart';
import 'services/media1_service.dart';
import 'services/media2_service.dart';
import 'services/onvif_service.dart';
import 'services/ptz_service.dart';
import 'soap/authenticator.dart';
import 'streaming/stream_backend.dart';

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

  /// The host address advertised to clients (also used to start the stream).
  final String? advertisedHost;

  late final SoapDispatcher dispatcher;
  late final OnvifServer server;

  /// The WS-Discovery responder, present when discovery is enabled.
  final WsDiscoveryServer? discovery;

  OnvifDevice({
    required this.config,
    required this.hardware,
    required this.streamBackend,
    DeviceState? state,
    bool enableDiscovery = false,
    this.advertisedHost,
  }) : state = state ?? DeviceState(),
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

    final authenticator = Authenticator(
      expectedUsername: config.username,
      expectedPassword: config.password,
    );

    final List<OnvifService> services = [
      DeviceService(config: config, state: this.state, hardware: hardware),
      Media1Service(
        config: config,
        state: this.state,
        streamBackend: streamBackend,
      ),
      Media2Service(
        config: config,
        state: this.state,
        streamBackend: streamBackend,
      ),
      PtzService(state: this.state),
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
    );
  }

  /// The port the SOAP server is bound to (after [start]).
  int? get port => server.port;

  Future<void> start({
    LogOptions logOptions = const LogOptions(LogLevel.info),
    LoggyPrinter printer = const PrettyPrinter(showColors: false),
  }) async {
    // Initialize logging up front so the hardware adapter (which logs during
    // camera startup) has a configured loggy.
    Loggy.initLoggy(logPrinter: printer, logOptions: logOptions);

    await hardware.startCamera();
    await server.start(logOptions: logOptions, printer: printer);
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
    await discovery?.stop();
    await streamBackend.stop();
    await hardware.stopCamera();
    await server.stop();
  }
}
