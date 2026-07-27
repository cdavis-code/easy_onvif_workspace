# ONVIF WebRTC Configuration (Phase 1) — Design

## Goal

Add the standardized ONVIF **Media2 WebRTC configuration** surface
(`GetWebRTCConfigurations` / `SetWebRTCConfigurations` + the
`WebRTCConfiguration` model) to both the `easy_onvif` client and the
`easy_onvif_server`, grounded in the ONVIF WebRTC Specification (v2412) and the
Media2 WSDL. The server's configuration *reflects its existing self-contained
`/onvif/webrtc` signaling endpoint* — no external signaling infrastructure is
introduced.

## Background: what the ONVIF WebRTC spec defines

The ONVIF WebRTC work is two distinct parts:

1. **Media2 WebRTC configuration (§5.11 of the Media2 Service Spec)** — two SOAP
   operations, `GetWebRTCConfigurations` / `SetWebRTCConfigurations`, and a
   `tr2:WebRTCConfiguration` type with: `SignalingServer` (anyURI, required),
   `CertPathValidationPolicyID` (string, optional), `AuthorizationServer`
   (ReferenceToken, required), `DefaultProfile` (ReferenceToken, required),
   `Enabled` (boolean, required), and read-only `Connected` (boolean) / `Error`
   (string).
2. **The WebRTC Signaling Protocol** (the separate WebRTC spec) — the SDP
   offer/answer + ICE candidate exchange used to establish the peer connection.

In the **standard model**, the device connects to an *external signaling server*
(configured via `SignalingServer`) and authenticates to it via an **OAuth2
authorization server** (per the ONVIF Security Service spec); the viewer
connects to that same signaling server. It is a mediated, infrastructure-
dependent design — not a direct device↔browser link.

This project already has a **self-contained** WebRTC feature: the server itself
hosts the signaling endpoint (`/onvif/webrtc`, WebSocket) and the browser
connects directly (flutter_webrtc capture + recv-only web player). Phase 1 adds
the standardized *configuration surface* that describes this endpoint, without
changing the streaming behavior.

## Scope

**In scope (Phase 1):**
- Client: `WebRTCConfiguration` model + `getWebRTCConfigurations()` /
  `setWebRTCConfigurations()` on the Media2 service.
- Server: handle both operations in `Media2Service`, reflecting the built-in
  `/onvif/webrtc` endpoint.
- Request-construction tests (client) + a server integration test; README updates.

**Out of scope (deferred "Phase 2", documented below):** the full signaling
model — external signaling server, OAuth2 authorization, and the spec's SDP/ICE
signaling protocol.

## Architecture

The WebRTC configuration is a thin layer that *describes* the existing endpoint
rather than adding new streaming behavior:

- `GetWebRTCConfigurations` → returns one `WebRTCConfiguration` whose
  `SignalingServer` is the server's own `ws://<host>:<httpPort>/onvif/webrtc`,
  `DefaultProfile` = `Profile_1`, and `Enabled`/`Connected` reflect live state.
- `SetWebRTCConfigurations` → stores the provided config in memory (applies
  `Enabled`/`DefaultProfile`), acknowledges; never initiates an external
  connection.

## Client design (`easy_onvif`)

### Model: `WebRTCConfiguration` (`lib/src/model/media2/webrtc_configuration.dart`)

| Field | Type | JSON key / parse |
|-------|------|------------------|
| `signalingServer` | `String` (req) | `SignalingServer` / `stringMappedFromXml` |
| `certPathValidationPolicyId` | `String?` | `CertPathValidationPolicyID` / nullable |
| `authorizationServer` | `String` (req) | `AuthorizationServer` / `stringMappedFromXml` |
| `defaultProfile` | `String` (req) | `DefaultProfile` / `stringMappedFromXml` |
| `enabled` | `bool` (req) | `Enabled` / `boolMappedFromXml` |
| `connected` | `bool?` (read-only) | `Connected` / nullable |
| `error` | `String?` (read-only) | `Error` / nullable |

Implements `XmlSerializable.buildXml` (for the Set request), emitting
`SignalingServer`, `CertPathValidationPolicyID` (if present),
`AuthorizationServer`, `DefaultProfile`, `Enabled`. The read-only
`Connected`/`Error` are never serialized.

### Operations
- **Response wrapper:** `GetWebRTCConfigurationsResponse` →
  `List<WebRTCConfiguration>` (unbounded, via `OnvifUtil.jsonList`).
  `SetWebRTCConfigurationsResponse` is empty → method returns `Future<bool>`.
- **Builders** (`lib/src/soap/media2.dart`, `Xmlns.tr2`):
  `getWebRTCConfigurations()` → `Transport.quickTag('GetWebRTCConfigurations',
  Xmlns.tr2)`; `setWebRTCConfigurations(List<WebRTCConfiguration>)` → a
  `SetWebRTCConfigurations` element wrapping each config's `buildXml`.
- **Public methods** (`lib/src/media2.dart`):
  `Future<List<WebRTCConfiguration>> getWebRTCConfigurations()` and
  `Future<bool> setWebRTCConfigurations(List<WebRTCConfiguration>)`.
- **Barrel export** in `lib/media2.dart`.

## Server design (`easy_onvif_server`)

### Wiring
- **`WebrtcService`:** add `bool get hasActiveSession => _active != null;`.
- **`OnvifDevice`:** capture the existing `webrtcService` and pass it into
  `Media2Service` (new optional `webrtcService` param).

### `Media2Service`
- **In-memory state:** `bool _webRtcEnabled = true;` and
  `String _webRtcDefaultProfile = DeviceState.profileToken;`.
- **New switch cases:** `GetWebRTCConfigurations` →
  `_getWebRTCConfigurations(host)`; `SetWebRTCConfigurations` →
  `_setWebRTCConfigurations(ctx)`.
- **`_getWebRTCConfigurations(host)`** returns one `WebRTCConfiguration`:
  - `SignalingServer` = `ws://$host:${config.httpPort}/onvif/webrtc`
  - `AuthorizationServer` = `AuthorizationServer_1` (placeholder; the field is
    schema-required, OAuth2 is out of scope)
  - `DefaultProfile` = `_webRtcDefaultProfile`, `Enabled` = `_webRtcEnabled`
  - `Connected` = `webrtcService?.hasActiveSession ?? false`
- **`_setWebRTCConfigurations(ctx)`** reads the `WebRTCConfiguration` child(ren)
  via `ctx.params(...)`, applies `Enabled`/`DefaultProfile` to the in-memory
  state (empty list → reset to defaults), and returns an empty
  `SetWebRTCConfigurationsResponse`. It never initiates an external connection.

## Testing strategy

- **Client:** request-construction tests in `test/soap_request_test.dart`
  asserting the exact XML for `getWebRTCConfigurations` and
  `setWebRTCConfigurations` (no device needed).
- **Server:** an integration test driving the real client —
  `getWebRTCConfigurations()` returns a config whose `SignalingServer` equals
  the built-in `ws://<host>:<port>/onvif/webrtc`, and
  `setWebRTCConfigurations([...])` round-trips `Enabled`/`DefaultProfile`.

## Implementation tasks

1. **Client model + operations** — models, builders, `media2.dart` methods,
   barrel export, request-construction tests.
2. **Server** — `WebrtcService.hasActiveSession`; `Media2Service` state +
   operations; `OnvifDevice` wiring; server integration test.
3. **Docs** — client README Media2 matrix rows + a server README note.

## Deferred "Phase 2" (future work, not built here)

The full ONVIF WebRTC signaling model:
- The device connects to an **external signaling server** (the `SignalingServer`
  URI) rather than hosting signaling itself.
- **OAuth2 authorization** via the ONVIF Security Service spec (the
  `AuthorizationServer` reference) to obtain access tokens for the signaling
  server.
- The spec's **SDP/ICE signaling protocol** over that server.

This requires external infrastructure (a signaling server such as LiveKit or
Janus, plus an authorization server). Phase 1's Media2 configuration surface is
the foundation it builds on; at that point the existing self-contained
`/onvif/webrtc` would be augmented or replaced by standard signaling.
