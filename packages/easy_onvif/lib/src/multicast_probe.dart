import 'package:easy_onvif/probe.dart';

import 'platform/base_multicast_probe.dart';

import 'platform/multicast_probe_stub.dart'
    if (dart.library.io) 'platform/multicast_probe_io.dart'
    if (dart.library.html) 'platform/multicast_probe_web.dart'
    if (dart.library.js_interop) 'platform/multicast_probe_web.dart';

class MulticastProbe {
  static final defaultTimeout = BaseMulticastProbe.defaultTimeout;

  final MulticastProbeImpl _multicastProbeImpl;

  List<ProbeMatch> get onvifDevices => _multicastProbeImpl.onvifDevices;

  MulticastProbe({int? timeout, bool? releaseMode})
    : _multicastProbeImpl = MulticastProbeImpl(
        timeout: timeout,
        releaseMode: releaseMode,
      );

  Future<void> probe() => _multicastProbeImpl.probe();

  Future<void> hello() => _multicastProbeImpl.hello();

  Future<void> bye() => _multicastProbeImpl.bye();
}
