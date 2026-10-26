import 'dart:async';
import 'dart:io';

import 'package:easy_onvif/probe.dart';
import 'package:easy_onvif/soap.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/streaming/stream_backend.dart';

/// End-to-end verification of Milestone 4: the server answers a WS-Discovery
/// `Probe` with a `ProbeMatches` message that the `easy_onvif` client can
/// parse, advertising the device service endpoint.
void main() {
  const httpPort = 8094;
  // Use a non-standard discovery port to avoid clashing with real
  // WS-Discovery traffic on the well-known port 3702 during testing.
  const discoveryPort = 37020;

  late OnvifDevice device;

  setUp(() async {
    device = OnvifDevice(
      config: const ServerConfig(
        httpPort: httpPort,
        discoveryPort: discoveryPort,
      ),
      hardware: StubHardwareAdapter(),
      streamBackend: StubStreamBackend(
        urlFor: (host, profile) => 'rtsp://$host:8554/onvif/$profile',
      ),
      enableDiscovery: true,
      advertisedHost: '127.0.0.1',
    );

    await device.start();
  });

  tearDown(() async {
    await device.stop();
  });

  test(
    'responds to a WS-Discovery probe with a parseable ProbeMatch',
    () async {
      final responseCompleter = Completer<String>();

      final sender = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      sender.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = sender.receive();

          if (datagram != null && !responseCompleter.isCompleted) {
            responseCompleter.complete(String.fromCharCodes(datagram.data));
          }
        }
      });

      final probe = WsDiscovery.probe();

      sender.send(
        probe.toXmlString().codeUnits,
        InternetAddress('239.255.255.250'),
        discoveryPort,
      );

      final response = await responseCompleter.future.timeout(
        const Duration(seconds: 5),
      );

      sender.close();

      final envelope = Envelope.fromXmlString(response);

      expect(envelope.body.response, isNotNull);

      final matches = ProbeMatches.fromJson(envelope.body.response!);

      expect(matches.probeMatches, isNotEmpty);

      final match = matches.probeMatches.first;

      expect(match.xAddrs, isNotEmpty);
      expect(match.xAddrs.first, contains(':$httpPort/onvif/device_service'));
      expect(match.types, isNotEmpty);
      expect(match.endpointReference.address, isNotEmpty);
    },
  );
}
