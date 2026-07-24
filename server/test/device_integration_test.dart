import 'dart:io';

import 'package:easy_onvif/onvif.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/streaming/stream_backend.dart';

/// End-to-end verification of Milestone 1: the real `easy_onvif` client
/// connects to the server and exercises the device-management service.
void main() {
  const port = 8091;

  late OnvifDevice device;

  setUp(() async {
    device = OnvifDevice(
      config: const ServerConfig(httpPort: port),
      hardware: StubHardwareAdapter(),
      streamBackend: StubStreamBackend(
        urlFor: (host, profile) => 'rtsp://$host:8554/onvif/$profile',
      ),
    );

    await device.start();
  });

  tearDown(() async {
    await device.stop();
  });

  test('client connects and reads device information', () async {
    final onvif = await Onvif.connect(
      host: 'localhost:$port',
      username: 'admin',
      password: 'admin',
    );

    final info = await onvif.deviceManagement.getDeviceInformation();

    expect(info.manufacturer, 'easy_onvif');
    expect(info.model, 'Dart ONVIF Server');
    expect(info.firmwareVersion, '0.1.0');
  });

  test('client discovers advertised services', () async {
    final onvif = await Onvif.connect(
      host: 'localhost:$port',
      username: 'admin',
      password: 'admin',
    );

    final services = await onvif.deviceManagement.getServices();

    final namespaces = services.map((s) => s.nameSpace).toSet();

    expect(namespaces, contains('http://www.onvif.org/ver10/device/wsdl'));
    expect(namespaces, contains('http://www.onvif.org/ver10/media/wsdl'));
    expect(namespaces, contains('http://www.onvif.org/ver20/media/wsdl'));
    expect(namespaces, contains('http://www.onvif.org/ver20/ptz/wsdl'));
  });

  test(
    'pre-auth hostname is returned without credentials being checked',
    () async {
      final onvif = await Onvif.connect(
        host: 'localhost:$port',
        username: 'admin',
        password: 'admin',
      );

      final hostname = await onvif.deviceManagement.getHostname();

      expect(hostname.name, 'easy-onvif-server');
    },
  );

  test('invalid credentials are rejected', () async {
    final onvif = await Onvif.connect(
      host: 'localhost:$port',
      username: 'admin',
      password: 'admin',
    );

    // Swap in a transport with the wrong password by reconnecting with bad
    // credentials: GetDeviceInformation requires authentication.
    final badOnvif = await Onvif.connect(
      host: 'localhost:$port',
      username: 'admin',
      password: 'wrong-password',
    );

    expect(
      () => badOnvif.deviceManagement.getDeviceInformation(),
      throwsA(isA<Exception>()),
    );

    // The good connection still works.
    final info = await onvif.deviceManagement.getDeviceInformation();
    expect(info.manufacturer, 'easy_onvif');
  });

  test(
    'answers CORS preflight and tags responses for browser clients',
    () async {
      final client = HttpClient();

      // A browser sends an OPTIONS preflight before the cross-origin SOAP POST.
      final preflight = await client.openUrl(
        'OPTIONS',
        Uri.parse('http://localhost:$port/onvif/device_service'),
      );
      final preflightResponse = await preflight.close();

      expect(preflightResponse.statusCode, HttpStatus.noContent);
      expect(
        preflightResponse.headers.value('access-control-allow-origin'),
        '*',
      );
      expect(
        preflightResponse.headers.value('access-control-allow-headers'),
        contains('Content-Type'),
      );

      // The actual SOAP response must carry the CORS origin header too.
      final post = await client.openUrl(
        'POST',
        Uri.parse('http://localhost:$port/onvif/device_service'),
      );
      post.headers.set('Content-Type', 'application/soap+xml; charset=utf-8');
      post.write(
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" '
        'xmlns:tds="http://www.onvif.org/ver10/device/wsdl">'
        '<s:Body><tds:GetSystemDateAndTime/></s:Body>'
        '</s:Envelope>',
      );
      final postResponse = await post.close();

      expect(postResponse.headers.value('access-control-allow-origin'), '*');

      client.close(force: true);
    },
  );
}
