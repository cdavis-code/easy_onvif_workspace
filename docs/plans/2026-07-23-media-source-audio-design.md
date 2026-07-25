# Media Source Selection & Audio Streaming — Design

**Date:** 2026-07-23
**Status:** Validated with user (brainstorming session)
**Scope decisions (user-confirmed):**

1. Full audio streaming — G.711 PCMA served as a second RTP track
2. Desktop (macOS/Windows/Linux) gets the full feature set; iOS/Android additionally get microphone streaming (default mic)
3. Config uses **raw platform identifiers**, passed unmodified to the capture layer
4. macOS display capture is **native ScreenCaptureKit** (macOS stays ffmpeg-free)
5. Recording **and replay** carry the audio track

## Problem

The `server/` app streams one hard-coded video source per platform (first camera / hard-coded ffmpeg device) with no audio. Users need to choose, via the settings file loaded at app start:

- which **display** to stream (when multiple displays exist), or
- which **camera** to stream (when multiple cameras exist), and
- which **audio device** to stream.

## §1 Settings schema & source selection

New top-level `media` section, parsed by `ServerSettings.parse`:

```yaml
media:
  video:
    source: camera            # camera | display | test
    device: ""                # raw platform identifier, empty = platform default
  audio:
    enabled: false            # audio streaming is opt-in
    device: ""                # raw platform identifier, empty = default input
```

Raw identifiers by platform (documented in `assets/settings.yaml`, passed through unmodified):

| Platform | camera | display | audio |
|---|---|---|---|
| macOS | camera-plugin device name | `CGDirectDisplayID` (e.g. `1`) | AVAudioEngine input-device UID |
| Windows | dshow name (`USB Camera`) | `desktop` (gdigrab) | dshow name (`Microphone (Realtek)`) |
| Linux | `/dev/video0` | `:0.0` (x11grab; region syntax allowed, e.g. `:0.0+1920,0`) | ALSA/Pulse id (`hw:1`, `default`) |
| iOS/Android | camera-plugin device name | *(ignored)* | *(default mic; `device` ignored)* |

Backend selection matrix (replaces the pure platform switch in `main.dart`):

- macOS + `camera` → `CameraStreamBackend` (existing; honors device — `CameraH264Source` already accepts a `CameraDescription`)
- macOS + `display` → new **`ScreenCaptureStreamBackend`** (ScreenCaptureKit → existing VideoToolbox encoder → same `RtspServer`)
- Windows/Linux (any source) → `FfmpegBackend`, `inputArgs` built from settings instead of hard-coded
- Mobile → `CameraStreamBackend` with the selected camera; `display` falls back to camera with a warning
- `test` → current testsrc/stub behavior, unchanged

Invalid `source` values fail at parse time (`FormatException`), consistent with existing settings validation.

## §2 Audio pipeline (capture → G.711 → RTP)

New interface mirroring the video side's `NalStreamSource`:

```
AudioStreamSource
  Stream<AudioFrame> frames   // 20 ms G.711 A-law frames: 160 bytes + timestamp
  Future<void> start() / stop()
```

Everything downstream speaks **G.711 PCMA, 8 kHz mono** (RTP static payload type 8 — ONVIF baseline; no fmtp negotiation). A-law encoding from PCM16 is pure Dart (~20 lines); native code only delivers PCM.

Implementations:

1. **`FfmpegAudioSource`** (Windows/Linux) — a *separate* small ffmpeg process:
   `-f dshow/alsa -i <device> -ar 8000 -ac 1 -f alaw pipe:1`; Dart chunks stdout into
   160-byte frames. A separate process keeps `H264Source` untouched and lets audio fail
   independently of video.
2. **`NativeAudioSource`** (macOS/iOS) — Swift: AVAudioEngine input tap + AVAudioConverter
   to PCM16/8 kHz mono, pushed over an `EventChannel`; Dart does the A-law step. macOS
   honors the configured input-device UID; iOS uses the default mic.
3. **Android** — `AudioRecord` at 8 kHz mono on a background thread → same `EventChannel`
   contract.

RTSP/RTP changes (`rtsp_server.dart`, `rtp_packetizer.dart`):

- SDP gains `m=audio 0 RTP/AVP 8` + `a=control:trackID=1` when an audio source is attached
- Second `SETUP` maps audio to interleaved channels 2–3
- Audio RTP: one packet per 20 ms frame, timestamp advances 160/packet (8 kHz clock), separate SSRC

`StreamBackend` gains `AudioStreamSource? audioSource`, constructed by the backends when
`media.audio.enabled` and passed to the `RtspServer`.

**Known limitation:** no RTCP sender reports, so A/V sync in players is approximate —
same class of behavior as today's video-only stream.

## §3 Display capture

**macOS — new `ScreenCaptureStreamBackend`** (native, no ffmpeg):

- New Swift module `ScreenCaptureSource.swift` beside `VideoToolboxEncoder.swift`: an
  `SCStream` for the display whose `CGDirectDisplayID` matches `media.video.device`
  (empty → main display), delivering BGRA `CMSampleBuffer`s at the configured frame rate,
  scaled to 1280×720.
- Frames feed the **existing** VideoToolbox H.264 encoder via the same method/event
  channel contract `CameraH264Source` uses, so the Dart side is a sibling class
  `ScreenH264Source` reusing `AccessUnitFramer` and the unchanged `RtspServer`.
- Requires macOS 12.3+ and the **Screen Recording** TCC permission, requested at start via
  the existing permissions method channel. Denied permission → backend start fails cleanly;
  the SOAP device still comes up (existing best-effort behavior in `OnvifDevice.start`).
- Snapshots work unchanged: screen frames flow through the same encoder `snapshot` channel.

**Windows/Linux** — no new backend: `FfmpegBackend.inputArgs` built from settings —
`gdigrab -i desktop` (Windows) or `x11grab -i <id>` (Linux), raw identifier passed straight
through.

**Preview UI**: display sources use the RTSP-frame-grab path (Windows/Linux) or the encoder
snapshot channel (macOS); no `CameraController`, placeholder reads "Streaming display N".

## §4 Recording & replay with audio

Video segments stay raw Annex-B `.h264`. Audio is a **sidecar file per segment**: raw
G.711 A-law bytes (8000 bytes/second, mono) — byte-addressable by time
(`offset = seconds × 8000`), zero muxing code.

```
OnvifRecordingToken_1/
  index.json
  seg_00001.h264
  seg_00001.alaw
```

Rejected alternative: MPEG-TS/MP4 segments — a Dart muxer is ~10× the work for no
functional gain here.

- **Write path** — `SegmentRecorder` gains an optional `AudioStreamSource` tap; both files
  rotate together at the video keyframe boundary (sub-20 ms alignment error, inaudible).
  `RecordingSegment` gains nullable `audioFile`; old recordings and audio-disabled jobs
  remain valid (loader falls back to video-only).
- **Replay path** — `FileH264Source` reads the sidecar when present; replay SDP advertises
  the audio track; `play()` paces 20 ms audio frames off the same timer as video access
  units. `Range: clock=` seek computes the audio byte offset from the seek time.
- **Retention** — `RecordingStore.prune` deletes the sidecar alongside its segment.
- **Simplification (YAGNI)** — audio records only while the live audio source runs; no
  per-job audio toggle. Audio disabled ⇒ jobs record video-only.

## §5 ONVIF surface, UI, testing

SOAP (additive):

- `Media1Service`: `GetAudioSources` stays; add `GetAudioSourceConfigurations` /
  `GetAudioEncoderConfigurations` returning one G.711 config (`G711`, 8000 Hz, 64 kbps).
  Empty lists when audio is disabled.
- `GetStreamUri` unchanged — audio rides the same RTSP URL as a second track.

UI (`main.dart`): status card gains a read-only "Source" row (e.g. `Display 1 + audio`,
`Camera: FaceTime HD`) driven by the loaded settings.

Testing (ffmpeg backend + `lavfi` synthetic inputs; CI needs no real devices):

1. Settings tests — `media` section parse, defaults, invalid `source` rejection
2. Audio RTSP test — `FfmpegAudioSource` fed by `lavfi sine=frequency=440`; ffprobe the
   RTSP URL, assert `h264` + `pcm_alaw` streams
3. A-law encoder unit test — PCM→A-law against reference values
4. Recording+replay audio test — record ~4 s with sine audio; assert `.alaw` sidecars
   (~8000 B/s), ffprobe the replay URI for both tracks
5. SDP unit test — `m=audio` present with source, absent without
6. Existing 42 tests stay green (audio defaults to disabled)

## Out of scope

RTCP-based A/V sync, AAC, ONVIF audio backchannel (`SendAudio`), per-job audio toggle,
Wayland screen capture.
