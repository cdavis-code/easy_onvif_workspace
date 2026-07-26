# WebRTC Browser Streaming — Design

## Goal

Make the example app's **Live Video** mode work in Chrome/web by adding a WebRTC
streaming path to the ONVIF server, using `flutter_webrtc` on both the server
(media sender) and the example client (receiver). The existing RTSP pipeline is
untouched.

Browsers cannot play the server's `rtsp://` stream (HTML5 `<video>` has no RTSP
support). WebRTC is the browser-native way to deliver low-latency live media, and
`flutter_webrtc` (1.5.2) supports every platform involved — the Flutter desktop
server (macOS/Windows/Linux) as sender and the example app on web as receiver.

## Decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Delivery technology | WebRTC via `flutter_webrtc` | Browser-native live media; user-selected |
| 2 | Server media source | Independent capture via flutter_webrtc | flutter_webrtc can't ingest the existing H.264 NAL pipeline |
| 3 | Client scope | WebRTC on **web only**; native keeps media_kit + RTSP | RTSP already works natively; YAGNI |
| 4 | Media | Video **+ audio** (microphone) | Mirrors the RTSP audio feature |
| 5 | Signaling | **WebSocket** on the existing HTTP server | Supports trickle ICE / renegotiation |
| 6 | Concurrency | One active session; new connection replaces the old | Camera capture is single-consumer |

## Architecture

A self-contained WebRTC subsystem runs **alongside** the existing RTSP pipeline
(which stays untouched). Three parts:

1. **Server capture + peer** (`server/lib/src/webrtc/`) — isolated from
   `streaming/`. Reads the existing `media:` settings and captures via
   `flutter_webrtc`, sending the tracks over an `RTCPeerConnection` (libwebrtc
   encodes H.264/Opus).
2. **Signaling** — a WebSocket endpoint on the existing `OnvifServer`
   (`WebSocketTransformer.upgrade`), carrying JSON SDP/ICE messages.
3. **Client player** (example, web-only) — `flutter_webrtc` `RTCPeerConnection`
   + `RTCVideoView`.

### Source mapping

| `media.video.source` | Server capture |
|----------------------|----------------|
| `camera` | `getUserMedia({video: true, audio: true})` (camera + mic) |
| `display` | `getDisplayMedia({video: true})` + `getUserMedia({audio: true})`, tracks combined |
| `test` | falls back to the default camera (flutter_webrtc can't synthesize a pattern) |

## Server-side design

**New files under `server/lib/src/webrtc/`:**

- **`webrtc_session.dart`** — owns one browser session:
  - `start(MediaSettings)`: build the server `RTCPeerConnection`, capture tracks
    per the source mapping, add them, wire `onIceCandidate` to forward candidates
    out through the socket.
  - `handleOffer(sdp)`: set remote description, create answer, set local, return
    the answer SDP.
  - `addRemoteCandidate(...)`: feed trickle ICE candidates from the browser.
  - `dispose()`: close the peer connection and stop all captured tracks
    (releasing camera/mic/screen).
- **`webrtc_service.dart`** — session manager. Holds at most one active
  `WebrtcSession`; a new connection disposes the current one first. Exposes
  `handleConnection(WebSocket, MediaSettings)`.

**Wiring into `OnvifServer`:** in `_handleRequest`, before the 404 fallthrough,
detect the signaling path (`/onvif/webrtc`) and upgrade via
`WebSocketTransformer.isUpgradeRequest(request)`, then hand the socket to the
service. `OnvifDevice` constructs the `WebrtcService` with the loaded
`MediaSettings` (same place it builds the stream backend) and passes it into
`OnvifServer`.

**Signaling protocol (JSON over the socket):**

- client → server: `{"type":"offer","sdp":"..."}` and
  `{"type":"candidate","candidate":"...","sdpMid":"...","sdpMLineIndex":0}`
- server → client: `{"type":"answer","sdp":"..."}` and `{"type":"candidate",...}`
- server → client (failure): `{"type":"error","message":"..."}`

**Dependencies:** `flutter_webrtc` added to `server/pubspec.yaml`; the macOS
Podfile pulls in the WebRTC framework via flutter_webrtc's podspec; existing
camera/mic/screen entitlements already cover capture.

## Client-side design (example, web-only)

**Dependencies:** add `flutter_webrtc` and `web_socket_channel` to the example's
`pubspec.yaml` (media_kit stays for native platforms).

**New file `example/lib/webrtc_player.dart`** — a self-contained widget:

- On `initState`: create an `RTCPeerConnection`, register `onTrack` to capture the
  incoming remote `MediaStream`, open a `WebSocketChannel` to
  `ws://<host>:<httpPort>/onvif/webrtc`.
- Build a recv-only offer (audio + video transceivers), send
  `{"type":"offer",...}`; on `{"type":"answer",...}` set the remote description.
  Exchange ICE candidates both directions as `{"type":"candidate",...}`.
- Render the remote stream with `RTCVideoView` inside the same 16:9 frame the
  snapshot uses.
- On `dispose`: close the socket, dispose the peer connection, release the remote
  stream — navigating away cleanly stops the server session.

**Integration in `main.dart`:** `_buildMedia()` gains a platform branch. On
`kIsWeb`, `ViewMode.video` renders `WebrtcPlayer(host: ...)` instead of the
media_kit `Video` widget; native keeps media_kit + RTSP unchanged. Snapshot path
unchanged everywhere.

**Host/port:** the player derives the WebSocket URL from the same
`config['host']` the example already reads (`192.168.1.50:8080` →
`ws://192.168.1.50:8080/onvif/webrtc`).

**Browser permissions:** the *server* prompts for its own camera/mic/screen. The
browser only receives, so it needs no media permissions — just the WebSocket.

## Signaling & data-flow sequence

```
Browser (example, web)                    Server (Flutter desktop)
──────────────────────                    ─────────────────────────
1. User taps "Live Video"
2. Open WebSocket ──────────────────────► Accept upgrade at /onvif/webrtc
                                          3. Dispose any prior session
                                          4. Capture camera/screen + mic,
                                             create RTCPeerConnection, add tracks
5. createOffer (recvonly a+v)
   send {"type":"offer", sdp} ──────────► 6. setRemoteDescription(offer)
                                          7. createAnswer → setLocalDescription
   ◄────────────────────── {"type":"answer", sdp}
8. setRemoteDescription(answer)
   ◄────────── trickle ICE candidates ──► (both directions, as gathered)
9. ICE connects → DTLS → SRTP
   ◄════════════ H.264 video + Opus audio media ════════════
10. onTrack fires → RTCVideoView renders
11. User taps "Snapshot" / navigates away
12. dispose: close socket ──────────────► 13. onDone → session.dispose()
```

- The server is the media sender; the browser is recv-only.
- Media never touches the Dart layer on either side after negotiation.
- Teardown is socket-driven, so a crashed/refreshed browser can't leak a handle.

## Error handling & lifecycle

**Server:**
- Capture failure (no device, denied, unsupported `display`) → `start()` catches,
  logs, sends `{"type":"error"}`, tears down.
- Camera contention (RTSP holds the camera on macOS) → same error path. Documented
  limitation: use `source: display` (SCK allows multiple consumers) or stop RTSP.
- New connection while active → dispose existing session first (last client wins).
- Socket close / browser crash → `WebSocket.done` → `session.dispose()`.
- Server stop → `OnvifServer.stop()` disposes the active session.

**Client:**
- Connection error / unreachable server → error state in the 16:9 frame; snapshot
  still works.
- Dispose ordering → null the rendered stream reference before disposing the peer
  connection (the existing CameraController dispose-race pattern).

**Platform guards:** WebRTC capture wired only where flutter_webrtc supports it;
`source: display` is macOS-only (SCK), elsewhere falls back to camera with a log
note.

## Testing

WebRTC media can't run in headless `flutter test` (needs native libwebrtc + real
devices), so:

**Automated (headless):**
- Signaling protocol unit tests — JSON message codec + session-manager logic
  (single active session, replacement).
- WebSocket endpoint integration test — start `OnvifServer` with a **stub**
  `WebrtcService`, connect a Dart `WebSocket` client to `/onvif/webrtc`, assert
  upgrade succeeds, offer reaches the service, answer returns, close triggers
  teardown.

**Manual smoke (documented):**
- Server on macOS (`source: display`, audio on) + example on Chrome → verify live
  desktop + mic; switching to Snapshot stops the session.

**Regression:** existing 57-test suite stays green (additive subsystem).

## Out of scope

- WebRTC on native platforms (they use RTSP).
- Multiple concurrent WebRTC clients.
- WebRTC audio backchannel.
- TURN/STUN relay (LAN host candidates only).
- Reusing the existing H.264 pipeline (flutter_webrtc captures independently).
- Test-pattern source over WebRTC (falls back to camera).
