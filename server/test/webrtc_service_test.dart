import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/webrtc/webrtc_service.dart';
import 'package:easy_onvif_server/src/webrtc/webrtc_session.dart';

/// A [WebrtcSession] that records calls and emits a canned answer, so the
/// signaling routing can be tested without the native WebRTC stack.
class FakeWebrtcSession implements WebrtcSession {
  FakeWebrtcSession(this.send);

  final void Function(Map<String, dynamic> message) send;

  bool started = false;
  String? lastOffer;
  final List<String?> candidates = [];
  bool disposed = false;

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<void> handleOffer(String sdp) async {
    lastOffer = sdp;
    send({'type': 'answer', 'sdp': 'fake-answer'});
  }

  @override
  Future<void> addRemoteCandidate(
    String? candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  ) async {
    candidates.add(candidate);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  late HttpServer server;
  late WebrtcService service;
  late List<FakeWebrtcSession> created;

  Future<void> startServer() async {
    created = [];
    service = WebrtcService(
      media: const MediaSettings(),
      sessionFactory: (send) {
        final session = FakeWebrtcSession(send);
        created.add(session);
        return session;
      },
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      await service.handleConnection(socket);
    });
  }

  tearDown(() async {
    await service.dispose();
    await server.close(force: true);
  });

  test('routes the offer to the session and relays the answer', () async {
    await startServer();

    final client = await WebSocket.connect('ws://localhost:${server.port}/');
    final responses = <Map<String, dynamic>>[];
    client.listen(
      (data) => responses.add(jsonDecode(data as String) as Map<String, dynamic>),
    );

    client.add(jsonEncode({'type': 'offer', 'sdp': 'fake-offer'}));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(created, hasLength(1));
    expect(created.single.started, isTrue);
    expect(created.single.lastOffer, 'fake-offer');
    expect(
      responses.any((m) => m['type'] == 'answer' && m['sdp'] == 'fake-answer'),
      isTrue,
    );

    await client.close();
  });

  test('forwards trickle ICE candidates to the session', () async {
    await startServer();

    final client = await WebSocket.connect('ws://localhost:${server.port}/');
    client.add(jsonEncode({'type': 'offer', 'sdp': 'o'}));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    client.add(jsonEncode({
      'type': 'candidate',
      'candidate': 'candidate:1',
      'sdpMid': '0',
      'sdpMLineIndex': 0,
    }));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(created.single.candidates, contains('candidate:1'));

    await client.close();
  });

  test('disposes the session when the socket closes', () async {
    await startServer();

    final client = await WebSocket.connect('ws://localhost:${server.port}/');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(created.single.disposed, isFalse);

    await client.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(created.single.disposed, isTrue);
  });

  test('a new connection replaces the active session', () async {
    await startServer();

    final client1 = await WebSocket.connect('ws://localhost:${server.port}/');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(created, hasLength(1));

    final client2 = await WebSocket.connect('ws://localhost:${server.port}/');
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(created, hasLength(2));
    expect(created[0].disposed, isTrue);
    expect(created[1].disposed, isFalse);

    await client1.close();
    await client2.close();
  });
}
