import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/server/onvif_server.dart';
import 'package:easy_onvif_server/src/server/soap_dispatcher.dart';
import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/soap/authenticator.dart';
import 'package:easy_onvif_server/src/webrtc/webrtc_service.dart';
import 'package:easy_onvif_server/src/webrtc/webrtc_session.dart';

class FakeWebrtcSession implements WebrtcSession {
  FakeWebrtcSession(this.send);

  final void Function(Map<String, dynamic>) send;

  @override
  Future<void> start() async {}

  @override
  Future<void> handleOffer(String sdp) async {
    send({'type': 'answer', 'sdp': 'fake-answer'});
  }

  @override
  Future<void> addRemoteCandidate(String? c, String? m, int? i) async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  test('OnvifServer upgrades /onvif/webrtc and routes signaling', () async {
    const config = ServerConfig(httpPort: 8106);

    final service = WebrtcService(
      media: const MediaSettings(),
      sessionFactory: (send) => FakeWebrtcSession(send),
    );

    final server = OnvifServer(
      config: config,
      dispatcher: SoapDispatcher(
        services: const [],
        authenticator: Authenticator(
          expectedUsername: 'admin',
          expectedPassword: 'admin',
        ),
      ),
      hardware: StubHardwareAdapter(),
      webrtcService: service,
    );

    await server.start();
    addTearDown(server.stop);

    final client = await WebSocket.connect(
      'ws://localhost:8106/onvif/webrtc?username=admin&password=admin',
    );
    final responses = <Map<String, dynamic>>[];
    client.listen(
      (data) =>
          responses.add(jsonDecode(data as String) as Map<String, dynamic>),
    );

    client.add(jsonEncode({'type': 'offer', 'sdp': 'offer-sdp'}));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(
      responses.any((m) => m['type'] == 'answer' && m['sdp'] == 'fake-answer'),
      isTrue,
    );

    await client.close();
  });

  test('rejects an unauthenticated /onvif/webrtc upgrade', () async {
    const config = ServerConfig(httpPort: 8107);

    final service = WebrtcService(
      media: const MediaSettings(),
      sessionFactory: (send) => FakeWebrtcSession(send),
    );

    final server = OnvifServer(
      config: config,
      dispatcher: SoapDispatcher(
        services: const [],
        authenticator: Authenticator(
          expectedUsername: 'admin',
          expectedPassword: 'admin',
        ),
      ),
      hardware: StubHardwareAdapter(),
      webrtcService: service,
    );

    await server.start();
    addTearDown(server.stop);

    // No credentials: the upgrade is refused with 401 (WebSocket.connect
    // surfaces the failed handshake as an exception).
    expect(
      () => WebSocket.connect('ws://localhost:8107/onvif/webrtc'),
      throwsA(anything),
    );
  });
}
