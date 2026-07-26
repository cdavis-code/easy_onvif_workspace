# WebRTC Browser Streaming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a browser view the ONVIF server's live camera/display (with mic audio) over WebRTC, so the example app's Live Video mode works on Flutter web where RTSP cannot play.

**Architecture:** A self-contained WebRTC subsystem runs alongside the untouched RTSP pipeline. The server captures the configured source via `flutter_webrtc` and sends it over an `RTCPeerConnection`; signaling (SDP/ICE) rides a WebSocket on the existing HTTP server. The example app uses a web-only `flutter_webrtc` receiver; native platforms keep media_kit + RTSP.

**Tech Stack:** Dart/Flutter, `flutter_webrtc` 1.5.2 (libwebrtc), `web_socket_channel`, `dart:io` `WebSocketTransformer`.

**Design doc:** `docs/plans/2026-07-23-webrtc-browser-streaming-design.md`

---

## Environment notes (READ FIRST)

- Work happens in two packages: the server (`/Users/chrisdavis/projects/my/easy_onvif_workspace/server`) and the example (`/Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif/example`).
- **`git`, `grep`, `ls`, `cat` MUST be prefixed with `rtk`** (a hook blocks them otherwise): `rtk git add …`, `rtk grep -E …`.
- Test runs print huge logs; always redirect and grep the verdict:
  `flutter test <file> > /tmp/t.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t.log | tail -1`
- **Prerequisite (working tree):** the example's `lib/main.dart` already has the Snapshot/Live-Video `ViewMode` toggle using media_kit (uncommitted). This plan extends that file.
- WebRTC media cannot run headless (`flutter test` has no native libwebrtc/camera). The signaling routing IS testable headless with a fake session; actual media is a manual smoke test.
- Verified `flutter_webrtc`/`webrtc_interface` API (1.5.2 / 1.5.1):
  - `navigator.mediaDevices.getUserMedia(Map)` / `getDisplayMedia(Map)` → `Future<MediaStream>`
  - `createPeerConnection(Map configuration, [Map constraints])` → `Future<RTCPeerConnection>`
  - `RTCPeerConnection`: `onIceCandidate` (`Function(RTCIceCandidate)`), `onTrack` (`Function(RTCTrackEvent)`, use `event.streams.first`), `addTrack(track, [stream])`, `addTransceiver({kind, init})`, `createOffer([c])`, `createAnswer([c])`, `setLocalDescription(RTCSessionDescription)`, `setRemoteDescription(RTCSessionDescription)`, `addCandidate(RTCIceCandidate)`, `close()`
  - `RTCSessionDescription(sdp, type)`, `RTCIceCandidate(candidate, sdpMid, sdpMLineIndex)`
  - `RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly)`, `RTCRtpMediaType.RTCRtpMediaTypeVideo/Audio`
  - `MediaStreamTrack.stop()`, `MediaStream.getTracks()/getAudioTracks()/getVideoTracks()/dispose()`
  - `RTCVideoRenderer()` → `await initialize()`, `srcObject = stream`, `dispose()`; `RTCVideoView(renderer, {objectFit})`

## File structure

| File | Responsibility |
|---|---|
| `server/lib/src/webrtc/webrtc_session.dart` (create) | `WebrtcSession` interface (transport-agnostic) |
| `server/lib/src/webrtc/webrtc_service.dart` (create) | Session manager + WebSocket signaling routing (≤1 active session) |
| `server/lib/src/webrtc/native_webrtc_session.dart` (create) | `flutter_webrtc` capture + peer connection |
| `server/lib/src/server/onvif_server.dart` (modify) | Upgrade `/onvif/webrtc`, route to service, dispose on stop |
| `server/lib/src/onvif_device.dart` (modify) | Build `WebrtcService` with the native factory, pass to server |
| `server/test/webrtc_service_test.dart` (create) | Headless signaling-routing tests (fake session) |
| `server/test/webrtc_endpoint_test.dart` (create) | OnvifServer WebSocket-upgrade wiring test |
| `server/pubspec.yaml` (modify) | add `flutter_webrtc` |
| `example/lib/webrtc_player.dart` (create) | Web-only WebRTC receiver widget |
| `example/lib/main.dart` (modify) | Use `WebrtcPlayer` on web for Live Video |
| `example/pubspec.yaml` (modify) | add `flutter_webrtc`, `web_socket_channel` |
| `server/README.md` (modify) | document the WebRTC browser preview |

---

### Task 1: Add `flutter_webrtc` to the server

**Files:**
- Modify: `server/pubspec.yaml`

- [ ] **Step 1: Add the dependency**

Run:
```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server
flutter pub add flutter_webrtc
```
Expected: `Changed N dependencies!` (pulls `flutter_webrtc` + `webrtc_interface`).

- [ ] **Step 2: Verify the project still analyzes**

Run: `cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server && flutter analyze 2>&1 | tail -1`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server
rtk git add pubspec.yaml pubspec.lock
rtk git commit -m "chore(server): add flutter_webrtc dependency"
```

---

### Task 2: `WebrtcSession` interface + `WebrtcService` (TDD)

**Files:**
- Create: `server/lib/src/webrtc/webrtc_session.dart`
- Create: `server/lib/src/webrtc/webrtc_service.dart`
- Test: `server/test/webrtc_service_test.dart`

- [ ] **Step 1: Write the failing test** — `server/test/webrtc_service_test.dart`:

```dart
import 'dart:async';
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
```

- [ ] **Step 2: Run — verify FAIL** (missing `webrtc_service.dart`/`webrtc_session.dart`).

Run: `cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server && flutter test test/webrtc_service_test.dart > /tmp/t2.log 2>&1; rtk grep -E "(All tests passed|Some tests failed|Error)" /tmp/t2.log | tail -1`

- [ ] **Step 3: Implement** `server/lib/src/webrtc/webrtc_session.dart`:

```dart
/// One browser WebRTC session: captures the configured media source and
/// streams it to a remote peer over a peer connection.
///
/// Transport-agnostic: outgoing signaling messages (ICE candidates) are
/// reported through the `send` callback supplied at construction; incoming
/// messages arrive via [handleOffer] and [addRemoteCandidate]. The WebSocket
/// plumbing lives in `WebrtcService`.
abstract interface class WebrtcSession {
  /// Captures the media source and prepares the peer connection. Must be
  /// called before [handleOffer]. Throws if capture fails (no device, denied
  /// permission, unsupported source).
  Future<void> start();

  /// Applies the browser's SDP offer and produces the answer, reported via the
  /// `send` callback as `{"type":"answer","sdp":...}`.
  Future<void> handleOffer(String sdp);

  /// Adds a trickle ICE candidate received from the browser.
  Future<void> addRemoteCandidate(
    String? candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  );

  /// Stops all captured tracks and closes the peer connection.
  Future<void> dispose();
}
```

- [ ] **Step 4: Implement** `server/lib/src/webrtc/webrtc_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:loggy/loggy.dart';

import '../settings.dart';
import 'webrtc_session.dart';

/// Builds a [WebrtcSession] that reports outgoing signaling messages through
/// [send]. Injected so tests can substitute a fake session.
typedef WebrtcSessionFactory =
    WebrtcSession Function(void Function(Map<String, dynamic> message) send);

/// Manages browser WebRTC sessions for the `/onvif/webrtc` signaling endpoint.
///
/// Capture is single-consumer (one camera/screen owner), so at most one session
/// is active at a time: a new connection disposes the previous session before
/// starting its own capture.
class WebrtcService with UiLoggy {
  WebrtcService({required this.media, required WebrtcSessionFactory sessionFactory})
      : _sessionFactory = sessionFactory;

  /// The configured media source (video kind/device, audio enabled/device).
  final MediaSettings media;

  final WebrtcSessionFactory _sessionFactory;

  WebrtcSession? _active;

  /// Handles one upgraded WebSocket signaling connection.
  Future<void> handleConnection(WebSocket socket) async {
    // Single-consumer capture: tear down any in-progress session first.
    final previous = _active;
    _active = null;
    await previous?.dispose();

    void send(Map<String, dynamic> message) {
      try {
        socket.add(jsonEncode(message));
      } catch (_) {
        // The peer disconnected mid-write; teardown follows via onDone.
      }
    }

    final session = _sessionFactory(send);

    try {
      await session.start();
    } catch (error) {
      loggy.warning('WebRTC capture failed: $error');
      send({'type': 'error', 'message': '$error'});
      await session.dispose();
      await socket.close();
      return;
    }

    _active = session;

    Future<void> teardown() async {
      await session.dispose();
      if (_active == session) _active = null;
    }

    socket.listen(
      (data) async {
        try {
          final message = jsonDecode(data as String) as Map<String, dynamic>;
          switch (message['type']) {
            case 'offer':
              await session.handleOffer(message['sdp'] as String);
            case 'candidate':
              await session.addRemoteCandidate(
                message['candidate'] as String?,
                message['sdpMid'] as String?,
                (message['sdpMLineIndex'] as num?)?.toInt(),
              );
          }
        } catch (error) {
          loggy.warning('WebRTC signaling error: $error');
        }
      },
      onDone: teardown,
      onError: (_) => teardown(),
    );
  }

  /// Disposes the active session (called on server shutdown).
  Future<void> dispose() async {
    final active = _active;
    _active = null;
    await active?.dispose();
  }
}
```

- [ ] **Step 5: Run — verify PASS**, then `flutter analyze`.

Run: `cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server && flutter test test/webrtc_service_test.dart > /tmp/t2.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t2.log | tail -1`

- [ ] **Step 6: Commit**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server
rtk git add lib/src/webrtc/webrtc_session.dart lib/src/webrtc/webrtc_service.dart test/webrtc_service_test.dart
rtk git commit -m "feat(server): WebRTC session manager and signaling routing"
```

---

### Task 3: `NativeWebrtcSession` (flutter_webrtc capture + peer)

**Files:**
- Create: `server/lib/src/webrtc/native_webrtc_session.dart`

> Not headless-testable (needs native libwebrtc + a real capture device). Verified by `flutter analyze` here and the manual smoke test in Task 6.

- [ ] **Step 1: Implement** `server/lib/src/webrtc/native_webrtc_session.dart`:

```dart
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:loggy/loggy.dart';

import '../settings.dart';
import 'webrtc_session.dart';

/// A [WebrtcSession] backed by `flutter_webrtc`: captures the configured media
/// source (camera or display, plus microphone) and streams it to the browser
/// over an [RTCPeerConnection]. libwebrtc encodes the tracks (H.264/Opus).
class NativeWebrtcSession with UiLoggy implements WebrtcSession {
  NativeWebrtcSession({required this.media, required this.send});

  final MediaSettings media;

  /// Reports outgoing signaling messages (ICE candidates) to the browser.
  final void Function(Map<String, dynamic> message) send;

  RTCPeerConnection? _pc;
  final List<MediaStream> _streams = [];

  @override
  Future<void> start() async {
    final pc = await createPeerConnection({
      'iceServers': <Map<String, dynamic>>[],
    });

    pc.onIceCandidate = (candidate) {
      send({
        'type': 'candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _pc = pc;

    await _capture(pc);
  }

  Future<void> _capture(RTCPeerConnection pc) async {
    switch (media.videoSource) {
      case VideoSourceKind.display:
        // Screen video + (optionally) microphone audio, from two captures.
        final display = await navigator.mediaDevices.getDisplayMedia({
          'video': true,
        });
        _streams.add(display);
        for (final track in display.getVideoTracks()) {
          await pc.addTrack(track, display);
        }

        if (media.audioEnabled) {
          final mic = await navigator.mediaDevices.getUserMedia({
            'audio': true,
            'video': false,
          });
          _streams.add(mic);
          for (final track in mic.getAudioTracks()) {
            await pc.addTrack(track, mic);
          }
        }

      case VideoSourceKind.camera:
      case VideoSourceKind.test:
        // flutter_webrtc cannot synthesize a test pattern; `test` falls back
        // to the default camera.
        final camera = await navigator.mediaDevices.getUserMedia({
          'video': true,
          'audio': media.audioEnabled,
        });
        _streams.add(camera);
        for (final track in camera.getTracks()) {
          await pc.addTrack(track, camera);
        }
    }
  }

  @override
  Future<void> handleOffer(String sdp) async {
    final pc = _pc;
    if (pc == null) throw StateError('Session not started');

    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    send({'type': 'answer', 'sdp': answer.sdp});
  }

  @override
  Future<void> addRemoteCandidate(
    String? candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  ) async {
    await _pc?.addCandidate(RTCIceCandidate(candidate, sdpMid, sdpMLineIndex));
  }

  @override
  Future<void> dispose() async {
    for (final stream in _streams) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }
    _streams.clear();

    await _pc?.close();
    _pc = null;
  }
}
```

- [ ] **Step 2: Verify analyze is clean**

Run: `cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server && flutter analyze 2>&1 | tail -1`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server
rtk git add lib/src/webrtc/native_webrtc_session.dart
rtk git commit -m "feat(server): flutter_webrtc capture session for browser streaming"
```


---

### Task 4: Wire WebRTC into `OnvifServer` + `OnvifDevice` (TDD)

**Files:**
- Modify: `server/lib/src/server/onvif_server.dart`
- Modify: `server/lib/src/onvif_device.dart`
- Test: `server/test/webrtc_endpoint_test.dart`

- [ ] **Step 1: Write the failing test** — `server/test/webrtc_endpoint_test.dart`:

```dart
import 'dart:async';
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

    final client = await WebSocket.connect('ws://localhost:8106/onvif/webrtc');
    final responses = <Map<String, dynamic>>[];
    client.listen(
      (data) => responses.add(jsonDecode(data as String) as Map<String, dynamic>),
    );

    client.add(jsonEncode({'type': 'offer', 'sdp': 'offer-sdp'}));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(
      responses.any((m) => m['type'] == 'answer' && m['sdp'] == 'fake-answer'),
      isTrue,
    );

    await client.close();
  });
}
```

- [ ] **Step 2: Run — verify FAIL** (`OnvifServer` has no `webrtcService` parameter).

Run: `cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server && flutter test test/webrtc_endpoint_test.dart > /tmp/t4.log 2>&1; rtk grep -E "(All tests passed|Some tests failed|Error)" /tmp/t4.log | tail -1`

- [ ] **Step 3: Modify** `server/lib/src/server/onvif_server.dart`.

Add the import (after the `stream_backend.dart` import):

```dart
import '../webrtc/webrtc_service.dart';
```

Add the field (after `final StreamBackend? streamBackend;`):

```dart
  /// Handles browser WebRTC signaling (`/onvif/webrtc`). Null disables the
  /// endpoint (it answers 501).
  final WebrtcService? webrtcService;
```

Add the constructor parameter:

```dart
  OnvifServer({
    required this.config,
    required this.dispatcher,
    required this.hardware,
    this.streamBackend,
    this.webrtcService,
  });
```

Add a branch in `_handleRequest`, immediately before the final `else { 404 }`:

```dart
      } else if (request.uri.path == '/onvif/webrtc' &&
          WebSocketTransformer.isUpgradeRequest(request)) {
        await _handleWebRtc(request);
      } else {
```

Add the handler method (after `_handleSnapshot`):

```dart
  /// Upgrades the `/onvif/webrtc` request to a WebSocket and hands it to the
  /// WebRTC signaling service (browser live-video preview).
  Future<void> _handleWebRtc(HttpRequest request) async {
    final service = webrtcService;

    if (service == null) {
      request.response.statusCode = HttpStatus.notImplemented;
      await request.response.close();
      return;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    await service.handleConnection(socket);
  }
```

Dispose the service in `stop()`:

```dart
  Future<void> stop() async {
    await webrtcService?.dispose();
    await _server?.close(force: true);
    _server = null;
  }
```

- [ ] **Step 4: Modify** `server/lib/src/onvif_device.dart`.

Add imports (after the `stream_backend.dart` import):

```dart
import 'webrtc/native_webrtc_session.dart';
import 'webrtc/webrtc_service.dart';
```

In the constructor, replace the `server = OnvifServer(...)` block with:

```dart
    final webrtcService = WebrtcService(
      media: this.settings.media,
      sessionFactory: (send) => NativeWebrtcSession(
        media: this.settings.media,
        send: send,
      ),
    );

    server = OnvifServer(
      config: config,
      dispatcher: dispatcher,
      hardware: hardware,
      streamBackend: streamBackend,
      webrtcService: webrtcService,
    );
```

- [ ] **Step 5: Run — verify PASS**, then the full server suite + analyze.

Run:
```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server
flutter test test/webrtc_endpoint_test.dart test/webrtc_service_test.dart > /tmp/t4.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t4.log | tail -1
flutter test > /tmp/t4_all.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t4_all.log | tail -1
flutter analyze 2>&1 | tail -1
```
Expected: all green; `No issues found!`

- [ ] **Step 6: Commit**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server
rtk git add lib/src/server/onvif_server.dart lib/src/onvif_device.dart test/webrtc_endpoint_test.dart
rtk git commit -m "feat(server): serve WebRTC signaling at /onvif/webrtc"
```

---

### Task 5: Web-only WebRTC player in the example

**Files:**
- Modify: `example/pubspec.yaml`
- Create: `example/lib/webrtc_player.dart`
- Modify: `example/lib/main.dart`

- [ ] **Step 1: Add dependencies**

Run:
```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif/example
flutter pub add flutter_webrtc
flutter pub add web_socket_channel
```
Expected: `Changed N dependencies!`

- [ ] **Step 2: Create** `example/lib/webrtc_player.dart`:

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A browser-only live-video player that receives the server's WebRTC stream.
///
/// Connects to the server's `/onvif/webrtc` signaling WebSocket, negotiates a
/// receive-only peer connection, and renders the incoming track. Used on
/// Flutter web, where the RTSP stream cannot play; native platforms use
/// media_kit instead.
class WebrtcPlayer extends StatefulWidget {
  /// The server's `host:port` (e.g. `192.168.1.50:8080`).
  final String host;

  const WebrtcPlayer({super.key, required this.host});

  @override
  State<WebrtcPlayer> createState() => _WebrtcPlayerState();
}

class _WebrtcPlayerState extends State<WebrtcPlayer> {
  final _renderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  WebSocketChannel? _channel;
  MediaStream? _remoteStream;
  String? _error;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      await _renderer.initialize();

      final pc = await createPeerConnection({
        'iceServers': <Map<String, dynamic>>[],
      });
      _pc = pc;

      pc.onTrack = (event) {
        if (_disposed || event.streams.isEmpty) return;
        setState(() {
          _remoteStream = event.streams.first;
          _renderer.srcObject = _remoteStream;
        });
      };

      pc.onIceCandidate = (candidate) {
        _channel?.sink.add(jsonEncode({
          'type': 'candidate',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }));
      };

      // Receive-only transceivers: the server sends, the browser only receives.
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      final channel = WebSocketChannel.connect(
        Uri.parse('ws://${widget.host}/onvif/webrtc'),
      );
      _channel = channel;

      channel.stream.listen(
        (data) async {
          if (_disposed) return;
          final message = jsonDecode(data as String) as Map<String, dynamic>;
          switch (message['type']) {
            case 'answer':
              await pc.setRemoteDescription(
                RTCSessionDescription(message['sdp'] as String?, 'answer'),
              );
            case 'candidate':
              await pc.addCandidate(RTCIceCandidate(
                message['candidate'] as String?,
                message['sdpMid'] as String?,
                (message['sdpMLineIndex'] as num?)?.toInt(),
              ));
            case 'error':
              if (!_disposed) {
                setState(() => _error = message['message'] as String?);
              }
          }
        },
        onError: (Object error) {
          if (!_disposed) setState(() => _error = '$error');
        },
      );

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      channel.sink.add(jsonEncode({'type': 'offer', 'sdp': offer.sdp}));
    } catch (error) {
      if (!_disposed) setState(() => _error = '$error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    // Null the rendered stream before disposing so RTCVideoView never rebuilds
    // against a torn-down renderer.
    _renderer.srcObject = null;
    _remoteStream = null;
    _channel?.sink.close();
    _pc?.close();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Live video unavailable: $error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RTCVideoView(
      _renderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    );
  }
}
```

- [ ] **Step 3: Modify** `example/lib/main.dart`.

Add the import (after `import 'device_page.dart';`):

```dart
import 'webrtc_player.dart';
```

Replace `_enterVideoMode`'s guard so web skips the media_kit player. Change:

```dart
  Future<void> _enterVideoMode() async {
    if (_viewMode == ViewMode.video || videoUrl.isEmpty) return;

    final player = Player();
```

to:

```dart
  Future<void> _enterVideoMode() async {
    if (_viewMode == ViewMode.video) return;

    // On web the WebrtcPlayer manages its own peer connection; there is no
    // media_kit player to create (RTSP cannot play in a browser).
    if (kIsWeb) {
      setState(() => _viewMode = ViewMode.video);
      return;
    }

    if (videoUrl.isEmpty) return;

    final player = Player();
```

Replace the `ViewMode.video` arm of the switch in `_buildMedia`. Change:

```dart
      ViewMode.video =>
        _videoController != null
            ? Video(controller: _videoController!, controls: NoVideoControls())
            : const Text('Live video not available'),
```

to:

```dart
      ViewMode.video =>
        kIsWeb
            ? WebrtcPlayer(host: '${config['host']}')
            : (_videoController != null
                ? Video(controller: _videoController!, controls: NoVideoControls())
                : const Text('Live video not available')),
```

(`kIsWeb` is available via the existing `package:flutter/material.dart` import.)

- [ ] **Step 4: Verify analyze + web build**

Run:
```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif/example
flutter analyze lib/main.dart lib/webrtc_player.dart 2>&1 | tail -1
flutter build web > /tmp/t5_web.log 2>&1; tail -2 /tmp/t5_web.log
```
Expected: `No issues found!` and a successful web build (`✓ Built build/web`).

- [ ] **Step 5: Commit**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif/example
rtk git add pubspec.yaml pubspec.lock lib/webrtc_player.dart lib/main.dart
rtk git commit -m "feat(example): WebRTC live-video player for Flutter web"
```

---

### Task 6: Documentation + final verification

**Files:**
- Modify: `server/README.md`

- [ ] **Step 1: Add a Features bullet** in `server/README.md` (after the **Audio streaming** bullet):

```markdown
- **Browser live preview** — a WebRTC endpoint (`/onvif/webrtc`) lets a browser
  view the live camera/display with microphone audio; the example app uses it
  automatically on Flutter web, where RTSP cannot play.
```

- [ ] **Step 2: Add a subsection** after "Choosing what to stream":

```markdown
### Browser preview (WebRTC)

The server exposes a WebRTC signaling endpoint at
`ws://<host>:<httpPort>/onvif/webrtc`. A browser client negotiates a
receive-only peer connection and the server streams the configured source
(camera or display, plus the microphone when `media.audio.enabled` is true),
encoded by libwebrtc (H.264 video / Opus audio).

The example app uses this automatically when run on Flutter web
(`flutter run -d chrome`): its **Live Video** mode connects over WebRTC, while
native platforms keep using RTSP.

Notes:

- One active WebRTC session at a time (camera capture is single-consumer); a new
  viewer replaces the previous one.
- On macOS, `source: display` (ScreenCaptureKit) coexists with RTSP; `source:
  camera` may contend with the RTSP camera capture — stop RTSP or use `display`
  if you need both at once.
- LAN only (host ICE candidates); no TURN/STUN relay.
```

- [ ] **Step 3: Final verification sweep**

Run:
```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server
flutter analyze 2>&1 | tail -1
flutter test > /tmp/t6_all.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t6_all.log | tail -1
flutter build macos --debug > /tmp/t6_macos.log 2>&1; tail -2 /tmp/t6_macos.log
```
Expected: `No issues found!`, all tests pass, `✓ Built build/macos/.../easy_onvif_server.app`.

- [ ] **Step 4: Manual smoke test (macOS + Chrome)**

1. Create `~/.easy_onvif_server/settings.yaml`:
   ```yaml
   media:
     video:
       source: display
     audio:
       enabled: true
   ```
2. `cd server && flutter run -d macos` — grant Screen Recording + Microphone.
3. `cd packages/easy_onvif/example && flutter run -d chrome` — point
   `assets/config.yaml` `host:` at the server's LAN IP:port, tap **Live Video**.
4. Verify the desktop appears with live mic audio in Chrome; tap **Snapshot** and
   confirm the session stops (server releases screen/mic).

- [ ] **Step 5: Commit docs**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/server
rtk git add README.md
rtk git commit -m "docs(server): WebRTC browser preview"
```

---

## Self-Review Notes

- **Spec coverage:** Design "Architecture/Server-side" → Tasks 2, 3, 4. "Client-side" → Task 5. "Signaling flow" → Tasks 2 (routing) + 5 (client). "Error handling & lifecycle" → Task 2 (capture-failure error message, teardown on close, session replacement), Task 3 (track/PC disposal), Task 5 (dispose ordering, error state). "Testing" → Tasks 2 & 4 (headless signaling tests) + Task 6 (manual smoke). "Dependencies" → Tasks 1 & 5. "Out of scope" items are not implemented (native WebRTC, multi-client, backchannel, TURN, H.264-pipeline reuse, test-pattern over WebRTC).
- **Type consistency:** `WebrtcSession` interface (`start`, `handleOffer(String)`, `addRemoteCandidate(String?, String?, int?)`, `dispose`) is used identically by `NativeWebrtcSession`, `WebrtcService`, and both test fakes. `WebrtcSessionFactory = WebrtcSession Function(void Function(Map<String, dynamic>) send)` matches `NativeWebrtcSession(media:, send:)` and the fakes' `FakeWebrtcSession(send)`. Signaling JSON keys (`type`, `sdp`, `candidate`, `sdpMid`, `sdpMLineIndex`, `message`) match between server (`webrtc_service.dart`/`native_webrtc_session.dart`) and client (`webrtc_player.dart`). `OnvifServer(... webrtcService:)` and `WebrtcService(media:, sessionFactory:)` signatures match their call sites in `onvif_device.dart` and the tests.
- **Verified API:** all `flutter_webrtc`/`webrtc_interface` signatures were read from the resolved packages (1.5.2 / 1.5.1) before writing this plan.
- **Known risks:** (1) `flutter_webrtc` desktop capture constraints (`{'video': true, 'audio': ...}`) are minimal — tune if a device rejects them. (2) macOS camera exclusivity between RTSP and WebRTC (documented; use `display`). (3) WebRTC media is only verifiable via the manual smoke test (headless tests cover signaling routing, not media). (4) The example's media_kit Snapshot/Live-Video toggle is a prerequisite that is currently uncommitted in the working tree.
