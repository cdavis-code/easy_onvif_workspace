# ONVIF Server Full Operation Coverage — Design

Date: 2026-07-23
Status: Validated with user

## Goal

Bring the simulated ONVIF device in `server/` to full coverage of the
"Supported Onvif Operations" documented in `packages/easy_onvif/README.md`,
using the client's `test/xml/` fixtures as the source of truth for response
shapes. Real device data takes priority over simulated data wherever it can be
obtained from the host (recordings, logs, storage paths, platform info,
geolocation). A YAML settings file configures the device.

## Decisions (user-confirmed)

1. **Recording/Replay/Search are real, not simulated**: recording jobs capture
   the live H.264 stream to disk; Replay serves recorded footage over RTSP;
   Search queries the on-disk index.
2. **Recording format**: raw Annex-B `.h264` segment files rotated on
   keyframes + a JSON index per recording. No ffmpeg dependency reintroduced,
   pure Dart, replay reuses the existing RTP path.
3. **Replay fidelity**: playback from start at recorded speed; `Range:
   clock=...` seeks to the nearest keyframe segment. No rate control, reverse
   playback, or ONVIF RTP extension header (can be added later).
4. **Settings**: YAML file with per-service enable/disable flags.

## Section 1 — Architecture overview & YAML settings

New pieces:

1. **`ServerSettings` loader** (`lib/src/settings.dart`) — loads YAML from, in
   priority order: explicit path (CLI arg / constructor),
   `~/.easy_onvif_server/settings.yaml`, bundled `assets/settings.yaml`.
   Missing file/keys → current hard-coded defaults. Produces the existing
   `ServerConfig` (extended).

2. **Settings schema**:

   ```yaml
   device:        # manufacturer, model, firmware, serial, hardwareId, hostname
   network:       # httpPort, rtspPort
   auth:          # username, password
   services:      # recording/replay/search/imaging: true|false
   recording:     # directory (default: app support dir /recordings),
                  # segmentSeconds (default 10), maxRetentionMinutes (optional)
   imaging:       # presets list (token, name, type)
   geolocation:   # fallback lat/lon/elevation when the platform has no fix
   ```

3. **Settings-driven service registry**: `OnvifDevice` builds the service list
   from the flags; `GetServices`/`GetCapabilities` only advertise enabled
   services (adding `timg`, `trc`, `tse`, `trp` XAddrs when enabled). Disabled
   namespace → existing `ActionNotSupported` fault path.

4. **"Real device data first"**: recordings = real captured video;
   `GetSystemLog` = real recent log lines (loggy ring buffer);
   `GetStorageConfiguration(s)` = actual recording directory as `Local`
   storage; geolocation hardware-first with YAML fallback. Imaging and
   remaining Device/Media2 gaps are simulated fixture-shaped responses.

The `yaml` package is already in the workspace dependency graph.

## Section 2 — Recording engine

New module `lib/src/recording/`:

1. **`RecordingStore`** — owns the recordings directory:

   ```
   <recordings dir>/<recordingToken>/
     index.json          # source info, created time, track config, segments
     seg_00001.h264      # Annex-B, starts with SPS/PPS + keyframe
     seg_00002.h264 ...
   ```

   `index.json`: per-segment `{file, startUtc, endUtc, frameCount}` plus
   recording metadata (resolution, frameRate, profile/source tokens). Existing
   recordings load at startup (persist across restarts). Retention: with
   `maxRetentionMinutes` set, oldest segments pruned on rotation.

2. **`SegmentRecorder`** — one active recording job. Subscribes to the live
   `NalStreamSource.nals` broadcast stream (no second camera consumer, no
   re-encode). Buffers until first keyframe, writes SPS/PPS + start codes,
   appends access units. Rotates on first keyframe after `segmentSeconds`,
   updating `index.json` per rotation (crash-safe partial last segment).

3. **`RecordingManager`** — SOAP-facing state. Tracks `RecordingItem`s and
   `RecordingJob`s (fixture-shaped tokens: `OnvifRecordingToken_1`,
   `videotracktoken_1`; job states `Active`/`Idle`). `CreateRecordingJob`
   (Active) starts a `SegmentRecorder`; `SetRecordingJobMode(Idle)` /
   `DeleteRecordingJob` stops it. `DeleteRecording` stops the job and removes
   the directory. One active job per recording; `CreateRecording` beyond a
   configurable max faults `MaxRecordings`.

Stream backends expose `NalStreamSource? get nalSource` so the recorder taps
the live feed (exposure only, no restructuring).

## Section 3 — Replay over RTSP & Search

Replay (`trp` + streaming changes):

1. **`RtspServer` path routing**: resolver mapping `/onvif/Profile_1` → live
   source (unchanged), `/onvif/replay/<recordingToken>` → per-session
   file-backed source, disposed on TEARDOWN. `DESCRIBE` builds the SDP from
   the session source (SPS/PPS read from the first segment — available
   immediately).

2. **`FileH264Source`** (implements `NalStreamSource`) — reads segments from
   `index.json` through existing `AnnexBSplitter` + `AccessUnitFramer`, paced
   by timer at the recorded frame rate. `PLAY` with
   `Range: clock=YYYYMMDDTHHMMSSZ-` starts at the first segment whose
   `endUtc` is after the requested time (segment = keyframe boundary). No
   Range → play from start. End of last segment → stream ends; connection
   stays open until TEARDOWN.

3. **`ReplayService`** — `GetReplayUri` →
   `rtsp://host:rtspPort/onvif/replay/<token>` (fault `NoRecording` for
   unknown tokens); `Get/SetReplayConfiguration` hold session timeout in
   state; `GetServiceCapabilities`: `RTP_RTSP_TCP=true`,
   `ReverseReplay=false`.

Search (`tse`) — real data from the index:

- `FindRecordings` creates a search session token; search completes
  immediately over `RecordingManager`'s list.
- `GetRecordingSearchResults` returns fixture-shaped `FindRecordingResult`s.
- `GetRecordingInformation` reports actual `EarliestRecording` /
  `LatestRecording` from segment timestamps, `RecordingStatus`
  (`Recording`/`Stopped`), track details.
- `GetRecordingSummary` aggregates real `DataFrom`/`DataUntil` /
  `NumberRecordings`.

## Section 4 — Imaging, remaining gaps, UI & tests

Imaging (`timg`, new `imaging_service.dart`) — simulated, stateful,
fixture-shaped: `GetStatus`, `GetServiceCapabilities`, `GetPresets` (seeded
from YAML with defaults), `GetCurrentPreset` / `SetCurrentPreset` mutate
`DeviceState`.

Device Management gaps (existing `DeviceService`):

- `GetSystemLog` — real: last ~200 lines from a loggy ring-buffer printer
- `GetSystemSupportInformation` — real platform info
  (`Platform.operatingSystemVersion`, Dart version)
- `GetStorageConfiguration(s)` — real recording directory, `Local` type
- `GetEndpointReference` — device UUID (reused from WS-Discovery)
- `GetIPAddressFilter` — empty Allow/Deny filter, fixture-shaped

Media gaps:

- Media1 `GetMetadataConfiguration` (singular) — same body as plural stub
- Media2 `GetVideoEncoderConfigurations`, `GetVideoEncoderInstances`,
  `GetVideoSourceConfigurationOptions`, `GetMetadataConfigurationOptions` —
  real values where known (actual resolution/frame rate/H.264 from the active
  backend config)

UI (`main.dart`): "Recording" row on the status card — active job indicator,
recording count, disk usage, replay URI. No new screens.

Tests (integration style, real `easy_onvif` client):

1. `recording_integration_test.dart` — create recording + job → wait → verify
   segments on disk + `GetRecordings`/`GetRecordingJobState`
2. `replay_integration_test.dart` — record ~4s, `GetReplayUri`,
   ffprobe/ffmpeg re-encode proves the replay endpoint serves decodable H.264
3. `search_integration_test.dart` — FindRecordings round-trip with real time
   ranges
4. `settings_test.dart` — YAML parsing, defaults, service-disable behavior

## Out of scope (explicit)

- MP4/MPEG-TS containers, rate control, reverse playback, ONVIF replay RTP
  extension header, Events (`tev`) service, audio tracks in recordings.
