import 'dart:async';

import 'package:easy_onvif/probe.dart';

import 'base_multicast_probe.dart';

/// Web-platform implementation of [BaseMulticastProbe].
///
/// ONVIF WS-Discovery relies on UDP multicast sockets and, on Windows, a
/// native `discovery.dll` loaded through `dart:ffi`. Neither capability is
/// available when compiling to JavaScript or WASM: browsers do not expose
/// raw UDP sockets and `dart:ffi` has no web backend. Every member of this
/// class therefore throws [UnsupportedError] so the limitation surfaces at
/// runtime with a clear, catchable error rather than an
/// `UnimplementedError`.
///
/// On the web, callers should connect to cameras by a known endpoint, e.g.
/// `Onvif.connect(host: ..., username: ..., password: ...)`, typically via a
/// reverse proxy that handles CORS and mixed-content concerns.
class MulticastProbeImpl implements BaseMulticastProbe {
  MulticastProbeImpl({int? timeout, bool? releaseMode});

  static const _unsupportedMessage =
      'ONVIF multicast discovery is not supported on the web platform. '
      'Browsers cannot open raw UDP sockets and `dart:ffi` is unavailable '
      'when compiling to JavaScript or WASM. Connect to cameras by a known '
      'endpoint instead (e.g. `Onvif.connect(host: ...)`).';

  List<ProbeMatch> get onvifDevices =>
      throw UnsupportedError(_unsupportedMessage);

  @override
  Future<void> probe() async => throw UnsupportedError(_unsupportedMessage);

  @override
  Future<void> bye() async => throw UnsupportedError(_unsupportedMessage);

  @override
  Future<void> hello() async => throw UnsupportedError(_unsupportedMessage);

  @override
  Future<void> announce() async => throw UnsupportedError(_unsupportedMessage);

  @override
  Completer<void> get stopSignal => throw UnsupportedError(_unsupportedMessage);

  @override
  void shutdown() => throw UnsupportedError(_unsupportedMessage);
}
