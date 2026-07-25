# Media Source Selection & Audio Streaming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the settings file choose the streamed display/camera/audio device, and serve G.711 audio as a second RTP track through live streaming, recording, and replay.

**Architecture:** A new `AudioStreamSource` interface (20 ms G.711 A-law frames) mirrors `NalStreamSource`; the RTSP server gains an optional audio track (payload type 8, interleaved channels 2–3). Video source selection is settings-driven: camera (existing backends), display (new native ScreenCaptureKit backend on macOS, gdigrab/x11grab via ffmpeg elsewhere), or test pattern. Recordings store audio as byte-addressable `.alaw` sidecars beside the `.h264` segments.

**Tech Stack:** Dart/Flutter, ffmpeg (Windows/Linux capture + all tests via `lavfi`), AVAudioEngine + ScreenCaptureKit + VideoToolbox (macOS/iOS Swift), AudioRecord (Android Kotlin).

**Design doc:** `docs/plans/2026-07-23-media-source-audio-design.md`

---

## Environment notes (READ FIRST)

- Everything runs in `/Users/chrisdavis/projects/my/easy_onvif_workspace/server` on branch `feature/server-full-onvif-coverage`.
- **`git`, `grep`, `ls`, `cat` commands MUST be prefixed with `rtk`** (a hook blocks them otherwise): `rtk git add …`, `rtk grep -E …`.
- Test runs print huge logs; always redirect and grep the verdict:
  `flutter test <file> > /tmp/t.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t.log | tail -1`
- Existing suite: 42 tests green, `flutter analyze` clean. Ports in use by existing tests: 8091–8103 HTTP, 8560–8565 RTSP. New tests use 8104/8566 and 8105/8567.
- Audio defaults to **disabled**, so no existing test may regress.

## File structure

| File | Responsibility |
|---|---|
| `lib/src/settings.dart` (modify) | `MediaSettings` + `VideoSourceKind` parsed from `media:` |
| `lib/src/streaming/alaw.dart` (create) | Pure-Dart PCM16 → G.711 A-law |
| `lib/src/streaming/audio_source.dart` (create) | `AudioFrame`, `AudioStreamSource`, `AlawFramer` |
| `lib/src/streaming/ffmpeg_audio_source.dart` (create) | ffmpeg-process audio capture (Win/Linux + tests) |
| `lib/src/streaming/native_audio_source.dart` (create) | EventChannel PCM capture (macOS/iOS/Android) |
| `lib/src/streaming/rtp_packetizer.dart` (modify) | `packetizeRaw` for audio payloads |
| `lib/src/streaming/rtsp_server.dart` (modify) | audio SDP block, per-track SETUP, audio interleaving |
| `lib/src/streaming/stream_backend.dart` + 3 backends (modify) | `audioSource` member |
| `lib/src/streaming/screen_h264_source.dart` (create) | Dart side of ScreenCaptureKit capture |
| `lib/src/streaming/screen_capture_backend.dart` (create) | macOS display StreamBackend |
| `lib/src/recording/recording_index.dart`, `recording_store.dart`, `segment_recorder.dart`, `recording_manager.dart` (modify) | `.alaw` sidecars |
| `lib/src/streaming/file_h264_source.dart` (modify) | replay audio |
| `lib/src/services/media1_service.dart` (modify) | audio source/encoder configuration ops |
| `macos/Runner/AudioCaptureSource.swift`, `ScreenCaptureSource.swift` (create), `AppDelegate.swift` (modify) | native macOS capture |
| `ios/Runner/AudioCaptureSource.swift` (create), `AppDelegate.swift` (modify) | native iOS mic |
| `android/.../MainActivity.kt` (modify) | native Android mic |
| `lib/main.dart` (modify) | backend selection matrix, permissions, UI row |
| `assets/settings.yaml`, `README.md` (modify) | docs |

---

### Task 1: Settings — `media` section

**Files:**
- Modify: `lib/src/settings.dart`
- Test: `test/settings_test.dart` (append)

- [ ] **Step 1: Write the failing tests** — append inside `main()` of `test/settings_test.dart`:

```dart
  group('media settings', () {
    test('defaults to camera video and disabled audio', () {
      final settings = ServerSettings.parse('');

      expect(settings.media.videoSource, VideoSourceKind.camera);
      expect(settings.media.videoDevice, isEmpty);
      expect(settings.media.audioEnabled, isFalse);
      expect(settings.media.audioDevice, isEmpty);
    });

    test('parses the media section', () {
      final settings = ServerSettings.parse('''
media:
  video:
    source: display
    device: "1"
  audio:
    enabled: true
    device: BuiltInMicrophoneDevice
''');

      expect(settings.media.videoSource, VideoSourceKind.display);
      expect(settings.media.videoDevice, '1');
      expect(settings.media.audioEnabled, isTrue);
      expect(settings.media.audioDevice, 'BuiltInMicrophoneDevice');
    });

    test('rejects an unknown video source', () {
      expect(
        () => ServerSettings.parse('media:\n  video:\n    source: hologram'),
        throwsFormatException,
      );
    });
  });
```

- [ ] **Step 2: Run — verify FAIL** (`VideoSourceKind` undefined):

Run: `cd server && flutter test test/settings_test.dart > /tmp/t1.log 2>&1; rtk grep -E "(All tests passed|Some tests failed|Error)" /tmp/t1.log | tail -1`

- [ ] **Step 3: Implement** in `lib/src/settings.dart`. Add above `ServerSettings`:

```dart
/// What the video track streams: a camera, a display, or a test pattern.
enum VideoSourceKind { camera, display, test }

/// Which capture devices feed the stream, using raw platform identifiers
/// (camera name, CGDirectDisplayID, /dev/video0, dshow name, hw:1, …) passed
/// unmodified to the capture layer.
class MediaSettings {
  final VideoSourceKind videoSource;

  /// Raw platform identifier of the video device; empty = platform default.
  final String videoDevice;

  /// Audio streaming is opt-in.
  final bool audioEnabled;

  /// Raw platform identifier of the audio input; empty = default input.
  final String audioDevice;

  const MediaSettings({
    this.videoSource = VideoSourceKind.camera,
    this.videoDevice = '',
    this.audioEnabled = false,
    this.audioDevice = '',
  });
}
```

Add field to `ServerSettings`: `final MediaSettings media;` with constructor param `this.media = const MediaSettings(),`. In `parse`, after `final geo = section('geolocation');` add:

```dart
    final mediaMap = section('media');
    final videoMap = mediaMap['video'] is YamlMap
        ? mediaMap['video'] as YamlMap
        : const <Object?, Object?>{};
    final audioMap = mediaMap['audio'] is YamlMap
        ? mediaMap['audio'] as YamlMap
        : const <Object?, Object?>{};
```

Then before the `return ServerSettings(` (after the presets block) add:

```dart
    final sourceText = text(videoMap, 'source') ?? 'camera';
    final videoSource = switch (sourceText) {
      'camera' => VideoSourceKind.camera,
      'display' => VideoSourceKind.display,
      'test' => VideoSourceKind.test,
      _ => throw FormatException(
        'Settings key "source" is not one of camera|display|test: $sourceText',
      ),
    };
```

And in the returned `ServerSettings(...)`:

```dart
      media: MediaSettings(
        videoSource: videoSource,
        videoDevice: text(videoMap, 'device') ?? '',
        audioEnabled: flag(audioMap, 'enabled', orElse: false),
        audioDevice: text(audioMap, 'device') ?? '',
      ),
```

- [ ] **Step 4: Run — verify PASS**, then `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
rtk git add lib/src/settings.dart test/settings_test.dart
rtk git commit -m "feat(server): media source and audio device settings"
```

---

### Task 2: G.711 A-law encoder (pure Dart)

**Files:**
- Create: `lib/src/streaming/alaw.dart`
- Test: `test/alaw_test.dart` (create)

- [ ] **Step 1: Write the failing test** — `test/alaw_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/streaming/alaw.dart';

void main() {
  test('encodes ITU reference samples', () {
    // Classic G.711 A-law reference points (Sun g711.c behavior).
    expect(alawEncodeSample(0), 0xD5);
    expect(alawEncodeSample(-1), 0x55);
    expect(alawEncodeSample(32767), 0xAA);
    expect(alawEncodeSample(-32768), 0x2A);
  });

  test('positive and negative values differ only in the sign bit', () {
    for (final value in [8, 100, 1000, 5000, 20000]) {
      expect(
        alawEncodeSample(-value - 1),
        alawEncodeSample(value) ^ 0x80,
        reason: 'value $value',
      );
    }
  });

  test('encodes a buffer sample-for-sample', () {
    final pcm = Int16List.fromList([0, -1, 32767, -32768]);

    expect(alawEncode(pcm), Uint8List.fromList([0xD5, 0x55, 0xAA, 0x2A]));
  });
}
```

- [ ] **Step 2: Run — verify FAIL** (missing file).

- [ ] **Step 3: Implement** `lib/src/streaming/alaw.dart`:

```dart
/// G.711 A-law compression (ITU-T G.711), ported from the classic Sun
/// `g711.c` reference implementation.
///
/// The RTSP audio track and the recording sidecars both carry raw A-law
/// bytes, so this is the single encode step between native PCM capture and
/// the wire/disk formats.
library;

import 'dart:typed_data';

const _segmentEnds = [0x1F, 0x3F, 0x7F, 0xFF, 0x1FF, 0x3FF, 0x7FF, 0xFFF];

/// Encodes one signed 16-bit PCM sample to an 8-bit A-law byte.
int alawEncodeSample(int pcm) {
  var value = pcm >> 3; // 16-bit to the 13-bit range A-law is defined over.

  int mask;

  if (value >= 0) {
    mask = 0xD5; // Sign bit set (positive), with the A-law toggle pattern.
  } else {
    mask = 0x55;
    value = -value - 1;
  }

  var segment = 0;

  while (segment < 8 && value > _segmentEnds[segment]) {
    segment++;
  }

  if (segment >= 8) return 0x7F ^ mask;

  var alaw = segment << 4;

  alaw |= segment < 2 ? (value >> 1) & 0x0f : (value >> segment) & 0x0f;

  return alaw ^ mask;
}

/// Encodes a PCM16 buffer to A-law, one byte per sample.
Uint8List alawEncode(Int16List pcm) {
  final out = Uint8List(pcm.length);

  for (var i = 0; i < pcm.length; i++) {
    out[i] = alawEncodeSample(pcm[i]);
  }

  return out;
}
```

- [ ] **Step 4: Run — verify PASS.**

- [ ] **Step 5: Commit**

```bash
rtk git add lib/src/streaming/alaw.dart test/alaw_test.dart
rtk git commit -m "feat(server): pure-dart G.711 A-law encoder"
```

---

### Task 3: AudioStreamSource + FfmpegAudioSource

**Files:**
- Create: `lib/src/streaming/audio_source.dart`, `lib/src/streaming/ffmpeg_audio_source.dart`
- Test: `test/audio_source_test.dart` (create)

- [ ] **Step 1: Write the failing tests** — `test/audio_source_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/streaming/audio_source.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_audio_source.dart';

void main() {
  test('AlawFramer chunks a byte stream into timestamped 20 ms frames', () {
    final frames = <AudioFrame>[];
    final framer = AlawFramer(frames.add);

    framer.add(List.filled(100, 1)); // Not enough for a frame yet.
    expect(frames, isEmpty);

    framer.add(List.filled(300, 2)); // 400 buffered => 2 frames + 80 left.
    expect(frames, hasLength(2));
    expect(frames[0].data, hasLength(160));
    expect(frames[0].timestamp, 0);
    expect(frames[1].timestamp, 160);

    framer.add(List.filled(80, 3)); // Completes the third frame exactly.
    expect(frames, hasLength(3));
    expect(frames[2].timestamp, 320);
  });

  test('FfmpegAudioSource produces real-time A-law frames', () async {
    final source = FfmpegAudioSource(); // Default input: lavfi sine.
    final frames = <AudioFrame>[];
    final subscription = source.frames.listen(frames.add);

    await source.start();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await source.stop();
    await subscription.cancel();

    // ~75 frames in 1.5 s; accept generous margins for process spin-up.
    expect(frames.length, greaterThan(30));
    expect(frames.every((f) => f.data.length == 160), isTrue);
    expect(frames[1].timestamp - frames[0].timestamp, 160);
  });
}
```

- [ ] **Step 2: Run — verify FAIL** (missing files).

- [ ] **Step 3: Implement** `lib/src/streaming/audio_source.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

/// One 20 ms G.711 A-law audio frame: 160 bytes at 8 kHz mono.
class AudioFrame {
  /// Raw A-law payload (exactly [AlawFramer.frameBytes] bytes).
  final Uint8List data;

  /// 8 kHz RTP timestamp; advances by 160 per frame.
  final int timestamp;

  AudioFrame(this.data, this.timestamp);
}

/// A source of G.711 A-law frames that the RTSP server can serve as an audio
/// track and the segment recorder can persist. Mirrors `NalStreamSource`.
abstract interface class AudioStreamSource {
  /// The live stream of 20 ms frames (a broadcast stream).
  Stream<AudioFrame> get frames;

  Future<void> start();

  Future<void> stop();
}

/// Chunks a continuous A-law byte stream into timestamped 20 ms [AudioFrame]s.
class AlawFramer {
  /// 20 ms at 8000 samples/s, one byte per sample.
  static const frameBytes = 160;

  final void Function(AudioFrame frame) onFrame;

  final List<int> _buffer = [];

  int _timestamp = 0;

  AlawFramer(this.onFrame);

  void add(List<int> data) {
    _buffer.addAll(data);

    while (_buffer.length >= frameBytes) {
      onFrame(
        AudioFrame(
          Uint8List.fromList(_buffer.sublist(0, frameBytes)),
          _timestamp,
        ),
      );

      _buffer.removeRange(0, frameBytes);

      _timestamp = (_timestamp + frameBytes) & 0xffffffff;
    }
  }
}
```

- [ ] **Step 4: Implement** `lib/src/streaming/ffmpeg_audio_source.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:loggy/loggy.dart';

import 'audio_source.dart';

/// Captures an audio device (or a lavfi test tone) with a small dedicated
/// `ffmpeg` process emitting raw G.711 A-law at 8 kHz mono on stdout.
///
/// Runs separately from the video ffmpeg process so audio can fail (missing
/// device, permission) without disturbing the video stream.
class FfmpegAudioSource implements AudioStreamSource {
  final String ffmpegPath;
  final List<String> inputArgs;

  Process? _process;
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<String>? _stderrSubscription;

  final _controller = StreamController<AudioFrame>.broadcast();
  late final AlawFramer _framer = AlawFramer(_controller.add);

  final _log = Loggy('FfmpegAudioSource');

  FfmpegAudioSource({this.ffmpegPath = 'ffmpeg', List<String>? inputArgs})
    : inputArgs =
          inputArgs ??
          ['-f', 'lavfi', '-i', 'sine=frequency=440:sample_rate=8000'];

  @override
  Stream<AudioFrame> get frames => _controller.stream;

  @override
  Future<void> start() async {
    if (_process != null) return;

    _process = await Process.start(ffmpegPath, [
      '-hide_banner',
      '-loglevel',
      'error',
      '-re',
      ...inputArgs,
      '-ar',
      '8000',
      '-ac',
      '1',
      '-f',
      'alaw',
      'pipe:1',
    ]);

    _subscription = _process!.stdout.listen(_framer.add);

    _stderrSubscription = _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _log.warning('ffmpeg(audio): $line'));
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    await _stderrSubscription?.cancel();
    _stderrSubscription = null;

    _process?.kill(ProcessSignal.sigkill);
    _process = null;
  }
}
```

- [ ] **Step 5: Run — verify PASS**, `flutter analyze`, **commit**:

```bash
rtk git add lib/src/streaming/audio_source.dart lib/src/streaming/ffmpeg_audio_source.dart test/audio_source_test.dart
rtk git commit -m "feat(server): audio stream source with ffmpeg capture"
```

---

### Task 4: RTSP audio track (SDP, SETUP, interleaving) + backend `audioSource`

**Files:**
- Modify: `lib/src/streaming/rtp_packetizer.dart`, `lib/src/streaming/rtsp_server.dart`, `lib/src/streaming/stream_backend.dart`, `lib/src/streaming/ffmpeg_backend.dart`, `lib/src/streaming/camera_stream_backend.dart`
- Test: `test/rtsp_audio_test.dart` (create)

- [ ] **Step 1: Write the failing tests** — `test/rtsp_audio_test.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_audio_source.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_backend.dart';
import 'package:easy_onvif_server/src/streaming/h264_source.dart';
import 'package:easy_onvif_server/src/streaming/rtsp_server.dart';

/// A parameter-set-only stub so buildSdp can run without live media.
class _StubNals implements NalStreamSource {
  @override
  Stream<H264NalUnit> get nals => const Stream.empty();

  @override
  Uint8List? get sps => Uint8List.fromList([0x67, 0x42, 0xC0, 0x1E]);

  @override
  Uint8List? get pps => Uint8List.fromList([0x68, 0xCE, 0x38, 0x80]);

  @override
  Future<void> get parametersReady => Future.value();
}

void main() {
  test('SDP advertises the audio track only when audio is attached', () {
    final server = RtspServer(source: _StubNals(), port: 0);

    final without = server.buildSdp(_StubNals(), hasAudio: false);
    expect(without, isNot(contains('m=audio')));

    final withAudio = server.buildSdp(_StubNals(), hasAudio: true);
    expect(withAudio, contains('m=audio 0 RTP/AVP 8'));
    expect(withAudio, contains('a=rtpmap:8 PCMA/8000'));
    expect(withAudio, contains('a=control:trackID=1'));
  });

  test('RTSP stream carries both h264 and pcm_alaw', () async {
    const config = ServerConfig(httpPort: 8104, rtspPort: 8566);

    final backend = FfmpegBackend(
      config: config,
      frameRate: 15,
      inputArgs: ['-f', 'lavfi', '-i', 'testsrc=size=640x480:rate=15'],
      audioSource: FfmpegAudioSource(),
    );

    await backend.start('Profile_1', host: 'localhost');

    try {
      final result = await Process.run('ffprobe', [
        '-v',
        'error',
        '-rtsp_transport',
        'tcp',
        '-show_entries',
        'stream=codec_name',
        '-of',
        'csv=p=0',
        'rtsp://127.0.0.1:8566/onvif/Profile_1',
      ]);

      expect(result.stdout.toString(), contains('h264'));
      expect(result.stdout.toString(), contains('pcm_alaw'));
    } finally {
      await backend.stop();
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
```

- [ ] **Step 2: Run — verify FAIL** (`buildSdp` and `audioSource` undefined).

- [ ] **Step 3: Add `packetizeRaw`** to `RtpPacketizer` (after `packetize`):

```dart
  /// Builds a single RTP packet around an opaque [payload] (e.g. one G.711
  /// audio frame).
  Uint8List packetizeRaw(
    Uint8List payload, {
    required int timestamp,
    bool marker = true,
  }) => _buildRtp(payload, marker: marker, timestamp: timestamp);
```

- [ ] **Step 4: Add `audioSource` to the backend interface.** In `stream_backend.dart` add import `'audio_source.dart'` and interface member after `nalSource`:

```dart
  /// The live G.711 audio source served as the RTSP audio track, or `null`
  /// when audio streaming is disabled.
  AudioStreamSource? get audioSource;
```

`StubStreamBackend` gets `@override final AudioStreamSource? audioSource = null;`.

`FfmpegBackend`: add ctor param + field `final AudioStreamSource? audioSource;` (`this.audioSource` in the constructor, import `audio_source.dart`); in `start()` call `await audioSource?.start();` before creating the RTSP server and pass `audioSource: audioSource` to `RtspServer(...)`; in `stop()` add `await audioSource?.stop();` after stopping the video source.

`CameraStreamBackend`: same ctor param/field/start/stop/pass-through changes (import `audio_source.dart`).

- [ ] **Step 5: RTSP server changes** in `rtsp_server.dart`:

1. Import `audio_source.dart`.
2. `RtspServer` gains `final AudioStreamSource? audioSource;` and ctor param `this.audioSource`.
3. Rename `_buildSdp` → public `buildSdp` with a `hasAudio` flag; append the audio block (sps/pps/profileLevelId/sprop lines unchanged):

```dart
  String buildSdp(NalStreamSource source, {required bool hasAudio}) {
    // ... existing sps/pps/profileLevelId/sprop code unchanged ...
    return [
      'v=0',
      'o=- ${DateTime.now().millisecondsSinceEpoch} 1 IN IP4 0.0.0.0',
      's=ONVIF Stream',
      'c=IN IP4 0.0.0.0',
      't=0 0',
      'm=video 0 RTP/AVP 96',
      'a=rtpmap:96 H264/90000',
      'a=fmtp:96 packetization-mode=1;profile-level-id=$profileLevelId;'
          'sprop-parameter-sets=$sprop',
      'a=control:trackID=0',
      if (hasAudio) ...[
        'm=audio 0 RTP/AVP 8',
        'a=rtpmap:8 PCMA/8000',
        'a=control:trackID=1',
      ],
      '',
    ].join('\r\n');
  }
```

4. `_RtspConnection` gains fields:

```dart
  int _audioChannel = 2;

  StreamSubscription<AudioFrame>? _audioSubscription;

  /// Audio frames for this session: the live source's, or the replay file's.
  Stream<AudioFrame>? _sessionAudioFrames;

  late final RtpPacketizer _audioPacketizer = RtpPacketizer(payloadType: 8);
```

5. In `_handleDescribe`, set the session audio next to `_sessionSource` (the replay branch stays `null` for now — Task 7 wires file audio):

```dart
      _sessionSource = fileSource;
      _sessionAudioFrames = null; // Replay audio arrives in a later task.
    } else {
      _sessionSource = server.source;
      _sessionAudioFrames = server.audioSource?.frames;
    }
```

and build the SDP with `server.buildSdp(_sessionSource!, hasAudio: _sessionAudioFrames != null)`.

6. `_handleSetup` becomes track-aware — change the call site to `_handleSetup(cseq, url, headers)` and:

```dart
  void _handleSetup(int cseq, String url, Map<String, String> headers) {
    final transport = headers['transport'] ?? '';
    final interleaved =
        RegExp(r'interleaved=(\d+)-(\d+)').firstMatch(transport);
    final isAudio = url.contains('trackID=1');

    var channel = isAudio ? _audioChannel : _rtpChannel;

    if (interleaved != null) channel = int.parse(interleaved.group(1)!);

    if (isAudio) {
      _audioChannel = channel;
    } else {
      _rtpChannel = channel;
    }

    _respond(
      cseq,
      headers: {
        'Transport': 'RTP/AVP/TCP;unicast;interleaved=$channel-${channel + 1}',
        'Session': _sessionId,
      },
    );
  }
```

7. In `_handlePlay`'s response, advertise both tracks when audio is present:

```dart
        'RTP-Info':
            'url=$url/trackID=0;seq=0;rtptime=0'
            '${_sessionAudioFrames != null ? ',url=$url/trackID=1;seq=0;rtptime=0' : ''}',
```

8. In `_startStreaming`, after the video subscription add:

```dart
    final audioFrames = _sessionAudioFrames;

    if (audioFrames != null) {
      _audioSubscription = audioFrames.listen((frame) {
        if (!_playing) return;

        try {
          _sendInterleaved(
            _audioPacketizer.packetizeRaw(
              frame.data,
              timestamp: frame.timestamp,
            ),
            channel: _audioChannel,
          );
        } catch (_) {
          close();
        }
      });
    }
```

9. `_sendInterleaved` gains a channel — `void _sendInterleaved(Uint8List rtpPacket, {int? channel})` writing `..addByte(channel ?? _rtpChannel)`. `_stopStreaming` also cancels `_audioSubscription` and nulls it.

- [ ] **Step 6: Run — verify PASS** (`flutter test test/rtsp_audio_test.dart`), then `test/rtsp_integration_test.dart` (must stay green) and `flutter analyze`.

- [ ] **Step 7: Commit**

```bash
rtk git add lib/src/streaming/rtp_packetizer.dart lib/src/streaming/rtsp_server.dart lib/src/streaming/stream_backend.dart lib/src/streaming/ffmpeg_backend.dart lib/src/streaming/camera_stream_backend.dart test/rtsp_audio_test.dart
rtk git commit -m "feat(server): G.711 audio track in the RTSP server"
```

---

### Task 5: Media1 audio configuration operations

**Files:**
- Modify: `lib/src/services/media1_service.dart`, `lib/src/onvif_device.dart`
- Test: `test/coverage_integration_test.dart` (append)

- [ ] **Step 1: Write the failing test.** In `coverage_integration_test.dart` `setUpAll`, give the device audio-enabled settings (add import `package:easy_onvif_server/src/settings.dart`):

```dart
    device = OnvifDevice(
      config: config,
      hardware: StubHardwareAdapter(),
      streamBackend: StubStreamBackend(urlFor: config.rtspUrl),
      settings: ServerSettings.parse('media:\n  audio:\n    enabled: true'),
    );
```

Append a new group:

```dart
  group('audio configuration', () {
    test('advertises one G711 encoder configuration', () async {
      soap.Transport.builder.element('GetAudioEncoderConfigurations', nest: () {
        soap.Transport.builder.namespace(soap.Xmlns.trt);
      });

      final envelope = await onvif.media.media1.transport.securedRequest(
        onvif.media.media1.uri,
        soap.Body(request: soap.Transport.builder.buildFragment()),
      );

      expect(envelope.body.response.toString(), contains('G711'));
    });

    test('advertises one audio source configuration', () async {
      soap.Transport.builder.element('GetAudioSourceConfigurations', nest: () {
        soap.Transport.builder.namespace(soap.Xmlns.trt);
      });

      final envelope = await onvif.media.media1.transport.securedRequest(
        onvif.media.media1.uri,
        soap.Body(request: soap.Transport.builder.buildFragment()),
      );

      expect(envelope.body.response.toString(), contains('AudioSource_1'));
    });
  });
```

- [ ] **Step 2: Run — verify FAIL** (ActionNotSupported fault → response lacks the strings).

- [ ] **Step 3: Implement.** `Media1Service` gains ctor param/field `final bool audioEnabled;` (`this.audioEnabled = false`). New cases in `handle`:

```dart
      case 'GetAudioSourceConfigurations':
        return _getAudioSourceConfigurations();
      case 'GetAudioEncoderConfigurations':
        return _getAudioEncoderConfigurations();
```

Handlers (empty response body elements when audio is disabled):

```dart
  String _getAudioSourceConfigurations() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetAudioSourceConfigurationsResponse',
        namespace: Xmlns.trt,
        nest: () {
          if (!audioEnabled) return;

          b.element(
            'Configurations',
            namespace: Xmlns.trt,
            attributes: {'token': 'AudioSourceConfig_1'},
            nest: () {
              b.element('Name', namespace: Xmlns.tt, nest: 'Audio Source Config');
              b.element('UseCount', namespace: Xmlns.tt, nest: '1');
              b.element('SourceToken', namespace: Xmlns.tt, nest: 'AudioSource_1');
            },
          );
        },
      );
    });
  }

  String _getAudioEncoderConfigurations() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetAudioEncoderConfigurationsResponse',
        namespace: Xmlns.trt,
        nest: () {
          if (!audioEnabled) return;

          b.element(
            'Configurations',
            namespace: Xmlns.trt,
            attributes: {'token': 'AudioEncoderConfig_1'},
            nest: () {
              b.element('Name', namespace: Xmlns.tt, nest: 'G711 Encoder');
              b.element('UseCount', namespace: Xmlns.tt, nest: '1');
              b.element('Encoding', namespace: Xmlns.tt, nest: 'G711');
              b.element('Bitrate', namespace: Xmlns.tt, nest: '64');
              b.element('SampleRate', namespace: Xmlns.tt, nest: '8');
            },
          );
        },
      );
    });
  }
```

In `onvif_device.dart`, pass `audioEnabled: this.settings.media.audioEnabled,` to the `Media1Service(...)` construction.

- [ ] **Step 4: Run — verify PASS** (whole coverage file), `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
rtk git add lib/src/services/media1_service.dart lib/src/onvif_device.dart test/coverage_integration_test.dart
rtk git commit -m "feat(server): media1 audio configuration operations"
```

---

### Task 6: Recording `.alaw` sidecars

**Files:**
- Modify: `lib/src/recording/recording_index.dart`, `lib/src/recording/recording_store.dart`, `lib/src/recording/segment_recorder.dart`, `lib/src/recording/recording_manager.dart`
- Test: `test/recording_store_test.dart` (extend)

- [ ] **Step 1: Write the failing test.** Add import to `recording_store_test.dart`: `package:easy_onvif_server/src/streaming/audio_source.dart`. Add a fake audio source next to `FakeNalSource`:

```dart
class FakeAudioSource implements AudioStreamSource {
  final _controller = StreamController<AudioFrame>.broadcast();
  Timer? _timer;
  int _timestamp = 0;

  @override
  Stream<AudioFrame> get frames => _controller.stream;

  @override
  Future<void> start() async {
    _timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      _controller.add(
        AudioFrame(Uint8List.fromList(List.filled(160, 0xD5)), _timestamp),
      );
      _timestamp += 160;
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    await _controller.close();
  }
}
```

Append inside the `segment recorder` group:

```dart
    test('writes an .alaw sidecar per segment when audio is present', () async {
      final store = RecordingStore(root: tempDir);
      await store.open();

      final index = await store.create(
        recordingToken: 'RA1',
        frameRate: 15,
        sourceToken: 'VideoSource_1',
        profileToken: 'Profile_1',
      );

      final video = FakeNalSource();
      final audio = FakeAudioSource();
      final recorder = SegmentRecorder(
        index: index,
        source: video,
        store: store,
        segmentSeconds: 1,
        audioSource: audio,
      );

      await recorder.start();
      await audio.start();
      await video.emitFrames(30, const Duration(milliseconds: 100));
      await recorder.stop();
      await audio.stop();
      await video.close();

      expect(index.segments.length, greaterThanOrEqualTo(2));

      for (final segment in index.segments) {
        expect(segment.audioFile, isNotNull);

        final sidecar = index.audioFile(segment)!;
        expect(sidecar.existsSync(), isTrue);
        expect(sidecar.lengthSync(), greaterThan(0));
        expect(sidecar.lengthSync() % 160, 0);
      }

      // The sidecar reference survives an index reload.
      final store2 = RecordingStore(root: tempDir);
      await store2.open();
      expect(
        store2.byToken('RA1')!.segments.first.audioFile,
        index.segments.first.audioFile,
      );
    });
```

- [ ] **Step 2: Run — verify FAIL** (no `audioSource` param, no `audioFile`).

- [ ] **Step 3: Implement.**

`recording_index.dart` — `RecordingSegment` gains a mutable `String? audioFile;` (ctor param `this.audioFile`), serialized:

```dart
  Map<String, dynamic> toJson() => {
        'file': file,
        'startUtc': startUtc.toIso8601String(),
        'endUtc': endUtc.toIso8601String(),
        'frameCount': frameCount,
        if (audioFile != null) 'audioFile': audioFile,
      };
```

and in `fromJson`: `audioFile: json['audioFile'] as String?,`. `RecordingIndex` gains:

```dart
  /// The segment's audio sidecar, or null for video-only segments.
  File? audioFile(RecordingSegment segment) => segment.audioFile == null
      ? null
      : File('${directory.path}/${segment.audioFile}');
```

`recording_store.dart` — in `prune`, after deleting the video file:

```dart
      final audio = index.audioFile(segment);

      if (audio != null && audio.existsSync()) await audio.delete();
```

`segment_recorder.dart` — import `../streaming/audio_source.dart`; add field/ctor param `final AudioStreamSource? audioSource;`; fields `IOSink? _audioSink;` and `StreamSubscription<AudioFrame>? _audioSubscription;`. In `start()` after the video subscription: `_audioSubscription = audioSource?.frames.listen(_onAudioFrame);` with:

```dart
  void _onAudioFrame(AudioFrame frame) => _audioSink?.add(frame.data);
```

In `_openSegment`, after `index.segments.add(_segment!);`:

```dart
    if (audioSource != null) {
      final audioName = name.replaceAll('.h264', '.alaw');

      _segment!.audioFile = audioName;
      _audioSink = File('${index.directory.path}/$audioName').openWrite();
    }
```

`_rotate` closes both sinks on the save queue:

```dart
  void _rotate(DateTime now) {
    final closing = _sink;
    final closingAudio = _audioSink;

    _sink = null;
    _audioSink = null;

    _openSegment(now);

    _enqueueSave(
      before: Future.wait([
        if (closing != null) closing.close(),
        if (closingAudio != null) closingAudio.close(),
      ]),
    );
  }
```

`stop()` additionally does `await _audioSubscription?.cancel(); _audioSubscription = null; await _audioSink?.close(); _audioSink = null;` before awaiting `_pendingSave`.

`recording_manager.dart` — pass `audioSource: backend.audioSource,` in the `SegmentRecorder(...)` construction.

- [ ] **Step 4: Run — verify PASS** (whole `recording_store_test.dart` + `recording_integration_test.dart`), `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
rtk git add lib/src/recording/ test/recording_store_test.dart
rtk git commit -m "feat(server): record G.711 audio sidecars beside video segments"
```

---

### Task 7: Replay with audio

**Files:**
- Modify: `lib/src/streaming/file_h264_source.dart`, `lib/src/streaming/rtsp_server.dart`
- Test: `test/replay_audio_integration_test.dart` (create)

- [ ] **Step 1: Write the failing test** — `test/replay_audio_integration_test.dart` (ports **8105/8567**; helper builders repeated because tasks may be read out of order):

```dart
import 'dart:io';

import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/recordings.dart';
import 'package:easy_onvif/replay.dart' show StreamSetup, Transport;
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_audio_source.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_backend.dart';

RecordingConfiguration buildTestRecordingConfiguration() =>
    RecordingConfiguration(
      source: RecordingSourceInformation(
        sourceId: 'VideoSource_1',
        name: 'VideoSource_1',
        location: 'Location',
        description: 'Live capture',
        address: 'http://localhost/onvif/Media',
      ),
      content: 'Test',
      maximumRetentionTime: 'PT0S',
    );

RecordingJobConfiguration buildTestJobConfiguration(String recordingToken) =>
    RecordingJobConfiguration(
      recordingToken: recordingToken,
      mode: RecordingJobConfigurationMode.active,
      priority: 1,
    );

/// End-to-end: record live video+audio, then verify the replay RTSP stream
/// carries both h264 and pcm_alaw.
void main() {
  const httpPort = 8105;
  const rtspPort = 8567;
  const config = ServerConfig(httpPort: httpPort, rtspPort: rtspPort);

  late Directory recordingsDir;
  late OnvifDevice device;
  late Onvif onvif;

  setUpAll(() async {
    recordingsDir = await Directory.systemTemp.createTemp('onvif_replay_audio');

    device = OnvifDevice(
      config: config,
      hardware: StubHardwareAdapter(),
      streamBackend: FfmpegBackend(
        config: config,
        frameRate: 15,
        inputArgs: ['-f', 'lavfi', '-i', 'testsrc=size=640x480:rate=15'],
        audioSource: FfmpegAudioSource(),
      ),
      settings: ServerSettings.parse('''
recording:
  directory: ${recordingsDir.path}
  segmentSeconds: 2
media:
  audio:
    enabled: true
''', base: config),
    );

    await device.start();

    onvif = await Onvif.connect(
      host: 'localhost:$httpPort',
      username: 'admin',
      password: 'admin',
    );
  });

  tearDownAll(() async {
    await device.stop();

    if (recordingsDir.existsSync()) recordingsDir.deleteSync(recursive: true);
  });

  test('replay serves recorded audio alongside video', () async {
    final recordingToken = await onvif.recordings.createRecording(
      buildTestRecordingConfiguration(),
    );
    final job = await onvif.recordings.createRecordingJob(
      buildTestJobConfiguration(recordingToken),
    );

    await Future<void>.delayed(const Duration(seconds: 5));

    await onvif.recordings.setRecordingJobMode(
      jobToken: job.token,
      mode: RecordingJobConfigurationMode.idle,
    );

    // Sidecars exist on disk with a plausible byte rate (~8000 B/s).
    final index = device.recordingStore!.byToken(recordingToken)!;

    expect(index.segments, isNotEmpty);

    for (final segment in index.segments) {
      final sidecar = index.audioFile(segment)!;
      final seconds =
          segment.endUtc.difference(segment.startUtc).inMilliseconds / 1000.0;

      expect(sidecar.existsSync(), isTrue);

      if (seconds > 0.5) {
        expect(
          sidecar.lengthSync(),
          greaterThan((seconds * 8000 * 0.3).round()),
        );
        expect(sidecar.lengthSync(), lessThan((seconds * 8000 * 2.0).round()));
      }
    }

    final replayUri = await onvif.replay.getReplayUri(
      recordingToken,
      streamSetup: StreamSetup(
        stream: 'RTP-Unicast',
        transport: Transport(protocol: 'RTSP'),
      ),
    );

    final probe = await Process.run('ffprobe', [
      '-v',
      'error',
      '-rtsp_transport',
      'tcp',
      '-show_entries',
      'stream=codec_name',
      '-of',
      'csv=p=0',
      replayUri,
    ]);

    expect(probe.stdout.toString(), contains('h264'));
    expect(probe.stdout.toString(), contains('pcm_alaw'));
  }, timeout: const Timeout(Duration(seconds: 120)));
}
```

Note: `StreamSetup`/`Transport` import names must match `test/replay_integration_test.dart` — copy its exact import lines if they differ.

- [ ] **Step 2: Run — verify FAIL** (replay SDP has no audio → ffprobe output lacks pcm_alaw).

- [ ] **Step 3: Implement replay audio in `file_h264_source.dart`.** Import `audio_source.dart`. Add fields:

```dart
  final _audioController = StreamController<AudioFrame>.broadcast();
  final List<Uint8List> _audioChunks = [];
  int _audioPosition = 0;
  Timer? _audioTimer;
```

Public surface:

```dart
  /// Whether the loaded segments carried audio sidecars.
  bool get hasAudio => _audioChunks.isNotEmpty;

  /// Paced 20 ms replay audio frames (empty for video-only recordings).
  Stream<AudioFrame> get audioFrames => _audioController.stream;
```

At the end of `load()` (after the access-unit regrouping loop):

```dart
    // Load the audio sidecars; the first segment honors the seek offset
    // (A-law is byte-addressable: 8000 bytes per second).
    for (final segment in segments) {
      final sidecar = index.audioFile(segment);

      if (sidecar == null || !sidecar.existsSync()) continue;

      var bytes = await sidecar.readAsBytes();

      if (seek != null &&
          segment == segments.first &&
          seek.isAfter(segment.startUtc)) {
        final skip =
            (seek.difference(segment.startUtc).inMilliseconds * 8 ~/ 160) * 160;

        if (skip >= bytes.length) continue;

        bytes = bytes.sublist(skip);
      }

      for (var offset = 0; offset + 160 <= bytes.length; offset += 160) {
        _audioChunks.add(bytes.sublist(offset, offset + 160));
      }
    }
```

(`load()` needs `dart:io` for file checks — already imported via `recording_index.dart` usage; add `import 'dart:io';` only if the analyzer asks.)

In `play()` (after starting the video timer):

```dart
    if (_audioChunks.isNotEmpty && _audioTimer == null) {
      _audioTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
        if (_audioPosition >= _audioChunks.length) {
          _audioTimer?.cancel();

          return;
        }

        _audioController.add(
          AudioFrame(_audioChunks[_audioPosition], _audioPosition * 160),
        );

        _audioPosition++;
      });
    }
```

In `stop()`: `_audioTimer?.cancel(); _audioTimer = null; await _audioController.close();`.

- [ ] **Step 4: Wire replay audio in `rtsp_server.dart`** — in `_handleDescribe`'s replay branch replace the Task 4 placeholder line with:

```dart
      _sessionAudioFrames = fileSource.hasAudio ? fileSource.audioFrames : null;
```

- [ ] **Step 5: Run — verify PASS**, plus `test/replay_integration_test.dart` (video-only replay must still pass) and `flutter analyze`.

- [ ] **Step 6: Commit**

```bash
rtk git add lib/src/streaming/file_h264_source.dart lib/src/streaming/rtsp_server.dart test/replay_audio_integration_test.dart
rtk git commit -m "feat(server): replay serves recorded G.711 audio"
```

---

### Task 8: NativeAudioSource (Dart) + macOS AVAudioEngine capture

**Files:**
- Create: `lib/src/streaming/native_audio_source.dart`, `macos/Runner/AudioCaptureSource.swift`
- Modify: `macos/Runner/AppDelegate.swift`, `macos/Runner/Info.plist`, entitlements
- Test: `test/audio_source_test.dart` (append) + `flutter build macos --debug`

- [ ] **Step 1: Write the failing test** — append to `test/audio_source_test.dart` (add imports `dart:typed_data` and `package:easy_onvif_server/src/streaming/native_audio_source.dart`):

```dart
  test('NativeAudioSource converts PCM16 chunks into A-law frames', () async {
    final source = NativeAudioSource();
    final frames = <AudioFrame>[];
    final subscription = source.frames.listen(frames.add);

    // 320 zero samples = 640 bytes PCM16 = two 20 ms frames of A-law 0xD5.
    source.addPcmBytes(Uint8List(640));

    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(frames, hasLength(2));
    expect(frames.first.data.every((byte) => byte == 0xD5), isTrue);
    expect(frames[1].timestamp, 160);
  });
```

- [ ] **Step 2: Run — verify FAIL** (missing file).

- [ ] **Step 3: Implement** `lib/src/streaming/native_audio_source.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'alaw.dart';
import 'audio_source.dart';

/// Captures microphone PCM through platform channels (AVAudioEngine on
/// macOS/iOS, AudioRecord on Android) and converts it to G.711 A-law frames.
///
/// ## Platform-channel contract
///
/// **Method channel** `easy_onvif_server/audio_capture`:
/// - `start` `{deviceUid: String}` — begin capture; empty UID = default input
///   (the UID is honored on macOS only).
/// - `stop` — end capture.
///
/// **Event channel** `easy_onvif_server/audio_capture/events`:
/// - Emits PCM16 little-endian mono 8 kHz chunks as `Uint8List`.
class NativeAudioSource implements AudioStreamSource {
  static const _control = MethodChannel('easy_onvif_server/audio_capture');
  static const _events = EventChannel('easy_onvif_server/audio_capture/events');

  /// Raw platform identifier of the input device (macOS CoreAudio UID).
  final String deviceUid;

  final _controller = StreamController<AudioFrame>.broadcast();
  late final AlawFramer _framer = AlawFramer(_controller.add);

  StreamSubscription<Object?>? _subscription;

  NativeAudioSource({this.deviceUid = ''});

  @override
  Stream<AudioFrame> get frames => _controller.stream;

  /// Feeds PCM16LE bytes through A-law into 20 ms frames. Exposed for tests;
  /// the event channel calls this with each native chunk.
  void addPcmBytes(Uint8List bytes) {
    final samples = Int16List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.length ~/ 2,
    );

    _framer.add(alawEncode(samples));
  }

  @override
  Future<void> start() async {
    if (_subscription != null) return;

    _subscription = _events.receiveBroadcastStream().listen((event) {
      if (event is Uint8List) addPcmBytes(event);
    });

    try {
      await _control.invokeMethod('start', {'deviceUid': deviceUid});
    } on MissingPluginException {
      // No native capture on this platform; the stream stays silent.
    }
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    try {
      await _control.invokeMethod('stop');
    } on MissingPluginException {
      // Nothing to tear down.
    }
  }
}
```

- [ ] **Step 4: Run — verify the Dart test PASSES.**

- [ ] **Step 5: macOS native capture** — create `macos/Runner/AudioCaptureSource.swift`:

```swift
import AVFoundation
import CoreAudio

/// Captures the input device with AVAudioEngine, converts to PCM16 mono
/// 8 kHz, and forwards each chunk to `onPcm` (bridged to Dart, which does the
/// G.711 A-law encode).
final class AudioCaptureSource {
  private let engine = AVAudioEngine()
  private var converter: AVAudioConverter?
  private var running = false

  var onPcm: ((Data) -> Void)?

  func start(deviceUid: String) throws {
    if running { return }

    if !deviceUid.isEmpty { selectInput(uid: deviceUid) }

    let input = engine.inputNode
    let inputFormat = input.outputFormat(forBus: 0)
    guard let outFormat = AVAudioFormat(
      commonFormat: .pcmFormatInt16, sampleRate: 8000, channels: 1, interleaved: true
    ) else { return }

    converter = AVAudioConverter(from: inputFormat, to: outFormat)

    input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
      guard let self = self, let converter = self.converter else { return }

      let ratio = 8000.0 / inputFormat.sampleRate
      let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 16
      guard let out = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: capacity) else { return }

      var consumed = false
      var error: NSError?

      converter.convert(to: out, error: &error) { _, status in
        if consumed { status.pointee = .noDataNow; return nil }
        consumed = true
        status.pointee = .haveData
        return buffer
      }

      if error == nil, out.frameLength > 0, let channel = out.int16ChannelData {
        self.onPcm?(Data(bytes: channel[0], count: Int(out.frameLength) * 2))
      }
    }

    engine.prepare()
    try engine.start()
    running = true
  }

  func stop() {
    guard running else { return }
    engine.inputNode.removeTap(onBus: 0)
    engine.stop()
    running = false
  }

  /// Points the input audio unit at the CoreAudio device with the given UID.
  /// Unknown UIDs silently keep the system default input.
  private func selectInput(uid: String) {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDevices,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: AudioObjectPropertyElement(0))
    var size: UInt32 = 0

    guard AudioObjectGetPropertyDataSize(
      AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else { return }

    let count = Int(size) / MemoryLayout<AudioDeviceID>.size
    var devices = [AudioDeviceID](repeating: 0, count: count)

    guard AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &devices) == noErr else { return }

    for device in devices {
      var uidAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceUID,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: AudioObjectPropertyElement(0))
      var deviceUid: CFString = "" as CFString
      var uidSize = UInt32(MemoryLayout<CFString>.size)

      let status = withUnsafeMutablePointer(to: &deviceUid) { pointer in
        AudioObjectGetPropertyData(device, &uidAddress, 0, nil, &uidSize, pointer)
      }

      if status == noErr, (deviceUid as String) == uid {
        var deviceId = device

        if let unit = engine.inputNode.audioUnit {
          AudioUnitSetProperty(
            unit, kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global, 0, &deviceId,
            UInt32(MemoryLayout<AudioDeviceID>.size))
        }
        return
      }
    }
  }
}
```

- [ ] **Step 6: Register the channels** in `macos/Runner/AppDelegate.swift`. Add properties beside `encoder`:

```swift
  /// Microphone capture bridged to Dart's NativeAudioSource.
  private let audioCapture = AudioCaptureSource()
  private var audioEventSink: FlutterEventSink?
```

In `applicationDidFinishLaunching` add `registerAudioChannels(messenger: messenger)` beside the existing registrations, and the method:

```swift
  /// Channels backing `NativeAudioSource`: control + PCM16/8 kHz event stream.
  private func registerAudioChannels(messenger: FlutterBinaryMessenger) {
    let control = FlutterMethodChannel(
      name: "easy_onvif_server/audio_capture",
      binaryMessenger: messenger
    )

    control.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }

      switch call.method {
      case "start":
        let args = call.arguments as? [String: Any] ?? [:]
        let deviceUid = args["deviceUid"] as? String ?? ""
        do {
          try self.audioCapture.start(deviceUid: deviceUid)
          result(nil)
        } catch {
          result(FlutterError(code: "audio_start", message: error.localizedDescription, details: nil))
        }

      case "stop":
        self.audioCapture.stop()
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let events = FlutterEventChannel(
      name: "easy_onvif_server/audio_capture/events",
      binaryMessenger: messenger
    )

    events.setStreamHandler(AudioStreamHandler(capture: audioCapture) { [weak self] sink in
      self?.audioEventSink = sink
    })
  }
```

And at file scope (below `EncoderStreamHandler`):

```swift
/// Bridges microphone PCM chunks to a Flutter event stream.
private final class AudioStreamHandler: NSObject, FlutterStreamHandler {
  private let capture: AudioCaptureSource
  private let onSink: (FlutterEventSink?) -> Void

  init(capture: AudioCaptureSource, onSink: @escaping (FlutterEventSink?) -> Void) {
    self.capture = capture
    self.onSink = onSink
    super.init()
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    onSink(events)
    capture.onPcm = { data in
      DispatchQueue.main.async { events(FlutterStandardTypedData(bytes: data)) }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    capture.onPcm = nil
    onSink(nil)
    return nil
  }
}
```

New Swift files must be added to the Xcode project — check whether `macos/Runner.xcodeproj/project.pbxproj` lists `VideoToolboxEncoder.swift` and add `AudioCaptureSource.swift` the same way (four entries: PBXBuildFile, PBXFileReference, group child, Sources build phase; reuse the encoder's entries as the template with fresh 24-hex-digit IDs).

Check `macos/Runner/Info.plist` has `NSMicrophoneUsageDescription`; if missing, add:

```xml
	<key>NSMicrophoneUsageDescription</key>
	<string>Streams the selected microphone as the ONVIF audio track.</string>
```

Verify `DebugProfile.entitlements` and `Release.entitlements` contain `com.apple.security.device.audio-input` (`<true/>`); add if absent.

- [ ] **Step 7: Verify** — `flutter analyze` clean, Dart tests pass, and:

Run: `flutter build macos --debug > /tmp/t8_build.log 2>&1; tail -2 /tmp/t8_build.log`
Expected: `✓ Built build/macos/Build/Products/Debug/easy_onvif_server.app`

- [ ] **Step 8: Commit**

```bash
rtk git add lib/src/streaming/native_audio_source.dart macos/Runner/ test/audio_source_test.dart
rtk git commit -m "feat(server): native macOS microphone capture for the audio track"
```

---

### Task 9: iOS + Android microphone capture

**Files:**
- Create: `ios/Runner/AudioCaptureSource.swift`
- Modify: `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist`, `android/app/src/main/kotlin/com/faithoflifedev/easy_onvif_server/MainActivity.kt`, `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: iOS capture** — create `ios/Runner/AudioCaptureSource.swift`. Same engine/converter/tap pipeline as macOS (Task 8 Step 5) with two changes: no CoreAudio `selectInput` (delete the method and its call — iOS always uses the default mic), and activate the audio session first:

```swift
import AVFoundation

/// Captures the default microphone with AVAudioEngine, converts to PCM16 mono
/// 8 kHz, and forwards each chunk to `onPcm`.
final class AudioCaptureSource {
  private let engine = AVAudioEngine()
  private var converter: AVAudioConverter?
  private var running = false

  var onPcm: ((Data) -> Void)?

  func start(deviceUid: String) throws {
    if running { return }

    // deviceUid is ignored on iOS: the default microphone is used.
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement)
    try session.setActive(true)

    let input = engine.inputNode
    let inputFormat = input.outputFormat(forBus: 0)
    guard let outFormat = AVAudioFormat(
      commonFormat: .pcmFormatInt16, sampleRate: 8000, channels: 1, interleaved: true
    ) else { return }

    converter = AVAudioConverter(from: inputFormat, to: outFormat)

    input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
      guard let self = self, let converter = self.converter else { return }

      let ratio = 8000.0 / inputFormat.sampleRate
      let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 16
      guard let out = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: capacity) else { return }

      var consumed = false
      var error: NSError?

      converter.convert(to: out, error: &error) { _, status in
        if consumed { status.pointee = .noDataNow; return nil }
        consumed = true
        status.pointee = .haveData
        return buffer
      }

      if error == nil, out.frameLength > 0, let channel = out.int16ChannelData {
        self.onPcm?(Data(bytes: channel[0], count: Int(out.frameLength) * 2))
      }
    }

    engine.prepare()
    try engine.start()
    running = true
  }

  func stop() {
    guard running else { return }
    engine.inputNode.removeTap(onBus: 0)
    engine.stop()
    running = false
  }
}
```

Modify `ios/Runner/AppDelegate.swift` to register the same two channels as macOS (Task 8 Step 6), obtaining the messenger from `(window?.rootViewController as! FlutterViewController).binaryMessenger` inside `application(_:didFinishLaunchingWithOptions:)`, and include the `AudioStreamHandler` class verbatim. Add the new file to `ios/Runner.xcodeproj/project.pbxproj` (same four-entry pattern as macOS). Add to `ios/Runner/Info.plist`:

```xml
	<key>NSMicrophoneUsageDescription</key>
	<string>Streams the microphone as the ONVIF audio track.</string>
```

- [ ] **Step 2: Android capture** — replace `android/app/src/main/kotlin/com/faithoflifedev/easy_onvif_server/MainActivity.kt` with:

```kotlin
package com.faithoflifedev.easy_onvif_server

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var recorder: AudioRecord? = null
    private var captureThread: Thread? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "easy_onvif_server/audio_capture"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> { startCapture(); result.success(null) }
                "stop" -> { stopCapture(); result.success(null) }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "easy_onvif_server/audio_capture/events"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    @SuppressLint("MissingPermission") // RECORD_AUDIO is granted via the OS dialog.
    private fun startCapture() {
        if (recorder != null) return

        val bufferSize = maxOf(
            AudioRecord.getMinBufferSize(
                8000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
            ),
            1280
        )

        val record = AudioRecord(
            MediaRecorder.AudioSource.MIC, 8000,
            AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bufferSize
        )

        if (record.state != AudioRecord.STATE_INITIALIZED) return

        recorder = record
        record.startRecording()

        captureThread = Thread {
            val buffer = ByteArray(640) // 40 ms of PCM16 at 8 kHz.
            while (recorder != null) {
                val read = record.read(buffer, 0, buffer.size)
                if (read > 0) {
                    val chunk = buffer.copyOf(read)
                    mainHandler.post { eventSink?.success(chunk) }
                }
            }
        }.also { it.start() }
    }

    private fun stopCapture() {
        val record = recorder ?: return
        recorder = null
        captureThread?.join(500)
        captureThread = null
        record.stop()
        record.release()
    }
}
```

Add to `android/app/src/main/AndroidManifest.xml` (above `<application`):

```xml
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
```

- [ ] **Step 3: Verify** — `flutter analyze` clean; `flutter build macos --debug` still green. iOS/Android builds are optional local checks (`flutter build ios --no-codesign --debug`, `flutter build apk --debug`) — run if the toolchains are available, otherwise state that in the task report.

- [ ] **Step 4: Commit**

```bash
rtk git add ios/Runner/ android/app/src/main/
rtk git commit -m "feat(server): iOS and Android microphone capture"
```

---

### Task 10: macOS ScreenCaptureKit display backend

**Files:**
- Create: `macos/Runner/ScreenCaptureSource.swift`, `lib/src/streaming/screen_h264_source.dart`, `lib/src/streaming/screen_capture_backend.dart`
- Modify: `macos/Runner/AppDelegate.swift`

- [ ] **Step 1: Verify the encoder's Swift API** so the SCK source calls it correctly:

Run: `rtk grep -n "func start\|func encode\|func stop\|func snapshotJpeg" macos/Runner/VideoToolboxEncoder.swift`
Expected labels: `start(width:height:frameRate:)`, `encode(bytes:width:height:bytesPerRow:)`, `stop()`. Adjust the code below if labels differ.

- [ ] **Step 2: Native SCK capture** — create `macos/Runner/ScreenCaptureSource.swift`:

```swift
import CoreMedia
import ScreenCaptureKit

/// Captures a display with ScreenCaptureKit and feeds BGRA frames into the
/// existing VideoToolbox H.264 encoder, so the encoded output reaches Dart on
/// the already-registered `easy_onvif_server/h264_encoder/events` channel.
@available(macOS 12.3, *)
final class ScreenCaptureSource: NSObject, SCStreamOutput {
  private let encoder: VideoToolboxEncoder
  private let queue = DispatchQueue(label: "easy_onvif_server.screen_capture")
  private var stream: SCStream?

  init(encoder: VideoToolboxEncoder) {
    self.encoder = encoder
  }

  func start(
    displayId: UInt32, width: Int, height: Int, frameRate: Int,
    completion: @escaping (Error?) -> Void
  ) {
    SCShareableContent.getWithCompletionHandler { [weak self] content, error in
      guard let self = self else { return }

      if let error = error {
        completion(error)
        return
      }

      let displays = content?.displays ?? []
      guard let display = displays.first(where: { $0.displayID == displayId }) ?? displays.first else {
        completion(NSError(
          domain: "easy_onvif_server", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "No display available to capture"]))
        return
      }

      let filter = SCContentFilter(display: display, excludingWindows: [])
      let configuration = SCStreamConfiguration()
      configuration.width = width
      configuration.height = height
      configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(frameRate))
      configuration.pixelFormat = kCVPixelFormatType_32BGRA

      let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)

      do {
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: self.queue)
        self.encoder.start(width: width, height: height, frameRate: frameRate)
        stream.startCapture { error in completion(error) }
        self.stream = stream
      } catch {
        completion(error)
      }
    }
  }

  func stop() {
    stream?.stopCapture()
    stream = nil
    encoder.stop()
  }

  func stream(
    _ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
    of type: SCStreamOutputType
  ) {
    guard type == .screen, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

    guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let width = CVPixelBufferGetWidth(pixelBuffer)

    encoder.encode(
      bytes: Data(bytes: base, count: bytesPerRow * height),
      width: width, height: height, bytesPerRow: bytesPerRow)
  }
}
```

Add the file to `macos/Runner.xcodeproj/project.pbxproj` (same four-entry pattern as Task 8).

- [ ] **Step 3: Register the channel** in `macos/Runner/AppDelegate.swift`. Add a property (typed `Any?` so the class still loads on macOS < 12.3):

```swift
  /// ScreenCaptureKit capture (macOS 12.3+), feeding the shared encoder.
  private var screenCapture: Any?
```

Add `registerScreenCaptureChannel(messenger: messenger)` beside the other registrations, plus:

```swift
  /// Channel backing `ScreenH264Source`: starts/stops display capture. The
  /// encoded H.264 flows through the existing encoder event channel.
  private func registerScreenCaptureChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "easy_onvif_server/screen_capture",
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      guard #available(macOS 12.3, *) else {
        result(FlutterError(
          code: "unavailable", message: "ScreenCaptureKit requires macOS 12.3+", details: nil))
        return
      }

      switch call.method {
      case "start":
        let args = call.arguments as? [String: Any] ?? [:]
        let displayId = UInt32(args["displayId"] as? Int ?? 0)
        let width = args["width"] as? Int ?? 1280
        let height = args["height"] as? Int ?? 720
        let frameRate = args["frameRate"] as? Int ?? 15
        let capture = ScreenCaptureSource(encoder: self.encoder)
        self.screenCapture = capture
        capture.start(displayId: displayId, width: width, height: height, frameRate: frameRate) { error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "screen_start", message: error.localizedDescription, details: nil))
            } else {
              result(nil)
            }
          }
        }

      case "stop":
        if let capture = self.screenCapture as? ScreenCaptureSource { capture.stop() }
        self.screenCapture = nil
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
```

Also add a `requestScreenCapture` case to the permissions channel handler (`import CoreGraphics` is implied by Cocoa):

```swift
      case "requestScreenCapture":
        if CGPreflightScreenCaptureAccess() {
          result(true)
        } else {
          result(CGRequestScreenCaptureAccess())
        }
```

- [ ] **Step 4: Dart source** — create `lib/src/streaming/screen_h264_source.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:loggy/loggy.dart';

import 'h264_source.dart';

/// A [NalStreamSource] fed by native ScreenCaptureKit display capture
/// (macOS 12.3+). The native side pushes captured frames through the shared
/// VideoToolbox encoder, so encoded H.264 arrives on the existing
/// `easy_onvif_server/h264_encoder/events` channel.
class ScreenH264Source with UiLoggy implements NalStreamSource {
  static const _control = MethodChannel('easy_onvif_server/screen_capture');
  static const _events = EventChannel('easy_onvif_server/h264_encoder/events');

  /// Raw CGDirectDisplayID from settings; empty selects the main display.
  final String displayId;

  final int frameRate;

  final _splitter = AnnexBSplitter();
  late final AccessUnitFramer _framer = AccessUnitFramer(frameRate: frameRate);

  StreamSubscription<Object?>? _subscription;
  bool _running = false;

  ScreenH264Source({this.displayId = '', this.frameRate = 15});

  @override
  Stream<H264NalUnit> get nals => _framer.nals;

  @override
  Uint8List? get sps => _framer.sps;

  @override
  Uint8List? get pps => _framer.pps;

  @override
  Future<void> get parametersReady => _framer.parametersReady;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;

    _subscription = _events.receiveBroadcastStream().listen((event) {
      if (event is Uint8List) {
        for (final nal in _splitter.feed(event)) {
          _framer.addNal(nal);
        }
      }
    });

    await _control.invokeMethod('start', {
      'displayId': int.tryParse(displayId) ?? 0,
      'width': 1280,
      'height': 720,
      'frameRate': frameRate,
    });

    _running = true;

    loggy.info(
      'Screen capture source started '
      '(display ${displayId.isEmpty ? 'main' : displayId})',
    );
  }

  Future<void> stop() async {
    if (!_running) return;

    _running = false;

    try {
      await _control.invokeMethod('stop');
    } on MissingPluginException {
      // Native side absent (non-macOS): nothing to stop.
    }

    await _subscription?.cancel();
    _subscription = null;

    _framer.flush();
    _framer.reset();
  }
}
```

- [ ] **Step 5: Backend** — create `lib/src/streaming/screen_capture_backend.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../config.dart';
import 'audio_source.dart';
import 'file_h264_source.dart';
import 'h264_source.dart';
import 'rtsp_server.dart';
import 'screen_h264_source.dart';
import 'stream_backend.dart';

/// A [StreamBackend] that serves a macOS display as the live RTSP stream via
/// ScreenCaptureKit + VideoToolbox (no ffmpeg).
class ScreenCaptureStreamBackend implements StreamBackend {
  final ServerConfig config;
  final int frameRate;

  /// Raw CGDirectDisplayID from settings; empty selects the main display.
  final String displayId;

  @override
  final AudioStreamSource? audioSource;

  ScreenH264Source? _source;
  RtspServer? _rtspServer;

  /// The shared encoder's snapshot channel (same one the camera backend uses).
  static const MethodChannel _encoderControl = MethodChannel(
    'easy_onvif_server/h264_encoder',
  );

  ScreenCaptureStreamBackend({
    required this.config,
    this.frameRate = 15,
    this.displayId = '',
    this.audioSource,
  });

  @override
  NalStreamSource? get nalSource => _source;

  @override
  Future<FileH264Source?> Function(String, DateTime?)? replaySourceFor;

  @override
  bool get isRunning => _rtspServer?.isRunning ?? false;

  @override
  Future<String> start(String profileToken, {required String host}) async {
    _source ??= ScreenH264Source(displayId: displayId, frameRate: frameRate);

    await _source!.start();
    await audioSource?.start();

    _rtspServer ??= RtspServer(
      source: _source!,
      port: config.rtspPort,
      replaySourceFor: replaySourceFor,
      audioSource: audioSource,
    );

    await _rtspServer!.start();

    return config.rtspUrl(host, profileToken);
  }

  @override
  Future<Uint8List?> snapshot() async {
    // The shared encoder keeps the latest frame; ask it for a JPEG still.
    try {
      final result = await _encoderControl.invokeMethod<Object?>('snapshot');

      if (result is Uint8List && result.isNotEmpty) return result;
    } catch (_) {
      // Snapshots are best-effort.
    }

    return null;
  }

  @override
  Future<void> stop() async {
    await _rtspServer?.stop();
    _rtspServer = null;

    await audioSource?.stop();

    await _source?.stop();
    _source = null;
  }
}
```

- [ ] **Step 6: Verify** — `flutter analyze` clean; full test suite still green; `flutter build macos --debug` succeeds.

- [ ] **Step 7: Commit**

```bash
rtk git add macos/Runner/ lib/src/streaming/screen_h264_source.dart lib/src/streaming/screen_capture_backend.dart
rtk git commit -m "feat(server): native ScreenCaptureKit display streaming on macOS"
```

---

### Task 11: Selection matrix, camera choice, permissions, UI row, docs

**Files:**
- Modify: `lib/main.dart`, `lib/src/streaming/camera_stream_backend.dart`, `lib/src/streaming/camera_h264_source.dart` (no change expected — it already takes `camera`), `assets/settings.yaml`, `README.md`

- [ ] **Step 1: Camera selection in `CameraStreamBackend`.** Add field/ctor param `final String cameraDevice;` (default `''`). In `start()`, before creating the source:

```dart
    CameraDescription? camera;

    if (cameraDevice.isNotEmpty) {
      final cameras = await availableCameras();

      // Raw identifier: match the camera plugin's device name; silently fall
      // back to the default camera when no name matches.
      camera = cameras
          .where(
            (c) => c.name.toLowerCase().contains(cameraDevice.toLowerCase()),
          )
          .firstOrNull;
    }

    _source ??= CameraH264Source(
      encoder: encoder,
      frameRate: frameRate,
      camera: camera,
    );
```

(`availableCameras` comes from the existing `package:camera/camera.dart` import.)

- [ ] **Step 2: main.dart selection matrix.** Add imports:

```dart
import 'package:easy_onvif_server/src/streaming/audio_source.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_audio_source.dart';
import 'package:easy_onvif_server/src/streaming/native_audio_source.dart';
import 'package:easy_onvif_server/src/streaming/screen_capture_backend.dart';
```

Replace `_platformVideoInput()` with settings-driven builders:

```dart
  /// ffmpeg video input for Windows/Linux (and the desktop test pattern),
  /// built from the configured source kind and raw device identifier.
  List<String> _videoInputArgs(MediaSettings media) {
    switch (media.videoSource) {
      case VideoSourceKind.test:
        return ['-f', 'lavfi', '-i', 'testsrc=size=1280x720:rate=15'];

      case VideoSourceKind.display:
        if (Platform.isWindows) {
          return [
            '-f', 'gdigrab', '-framerate', '15',
            '-i', media.videoDevice.isEmpty ? 'desktop' : media.videoDevice,
          ];
        }
        return [
          '-f', 'x11grab', '-framerate', '15', '-video_size', '1280x720',
          '-i', media.videoDevice.isEmpty ? ':0.0' : media.videoDevice,
        ];

      case VideoSourceKind.camera:
        if (Platform.isWindows) {
          return [
            '-f', 'dshow', '-framerate', '15', '-video_size', '1280x720',
            '-i',
            'video=${media.videoDevice.isEmpty ? 'Integrated Camera' : media.videoDevice}',
          ];
        }
        return [
          '-f', 'v4l2', '-framerate', '15', '-video_size', '1280x720',
          '-i', media.videoDevice.isEmpty ? '/dev/video0' : media.videoDevice,
        ];
    }
  }

  /// ffmpeg audio input for Windows/Linux. ALSA ids (`hw:…`) go to ALSA;
  /// anything else goes to PulseAudio on Linux and dshow on Windows.
  List<String> _audioInputArgs(MediaSettings media) {
    if (Platform.isWindows) {
      return [
        '-f', 'dshow',
        '-i',
        'audio=${media.audioDevice.isEmpty ? 'default' : media.audioDevice}',
      ];
    }

    if (media.audioDevice.startsWith('hw:')) {
      return ['-f', 'alsa', '-i', media.audioDevice];
    }

    return [
      '-f', 'pulse',
      '-i', media.audioDevice.isEmpty ? 'default' : media.audioDevice,
    ];
  }

  AudioStreamSource? _createAudioSource(ServerSettings settings) {
    if (!settings.media.audioEnabled) return null;

    if (Platform.isWindows || Platform.isLinux) {
      return FfmpegAudioSource(
        ffmpegPath: _resolveFfmpegPath(),
        inputArgs: _audioInputArgs(settings.media),
      );
    }

    // macOS/iOS/Android capture the microphone natively.
    return NativeAudioSource(deviceUid: settings.media.audioDevice);
  }
```

Replace `_createStreamBackend(ServerConfig config)` with:

```dart
  /// Chooses the streaming backend from the platform and the configured
  /// video source. Mobile is camera-only (display/test fall back to camera);
  /// macOS uses native capture (camera plugin or ScreenCaptureKit);
  /// Windows/Linux shell out to ffmpeg for every source kind.
  StreamBackend _createStreamBackend(ServerSettings settings) {
    final media = settings.media;
    final audio = _createAudioSource(settings);

    if (Platform.isIOS || Platform.isAndroid) {
      return CameraStreamBackend(
        config: settings.config,
        frameRate: 15,
        cameraDevice: media.videoDevice,
        audioSource: audio,
      );
    }

    if (Platform.isMacOS && media.videoSource == VideoSourceKind.camera) {
      return CameraStreamBackend(
        config: settings.config,
        frameRate: 15,
        cameraDevice: media.videoDevice,
        audioSource: audio,
      );
    }

    if (Platform.isMacOS && media.videoSource == VideoSourceKind.display) {
      return ScreenCaptureStreamBackend(
        config: settings.config,
        frameRate: 15,
        displayId: media.videoDevice,
        audioSource: audio,
      );
    }

    return FfmpegBackend(
      config: settings.config,
      ffmpegPath: _resolveFfmpegPath(),
      frameRate: 15,
      inputArgs: _videoInputArgs(media),
      audioSource: audio,
    );
  }
```

- [ ] **Step 3: Permissions + start order.** In `_start()`, load settings **before** requesting permissions and pass them through:

```dart
      final bundled = await rootBundle.loadString('assets/settings.yaml');
      final settings = await ServerSettings.load(fallbackYaml: bundled);

      await _ensurePermissions(settings);

      final adapter = FlutterAdapter(enableCamera: !_useNativeCamera);
      final backend = _createStreamBackend(settings);
```

Replace `_ensureCameraPermission` with:

```dart
  /// Requests the macOS TCC grants the configured sources need (camera or
  /// screen recording, plus microphone when audio is enabled). A no-op
  /// elsewhere; mobile platforms prompt through their own capture stacks.
  Future<void> _ensurePermissions(ServerSettings settings) async {
    if (!Platform.isMacOS) return;

    try {
      if (settings.media.videoSource == VideoSourceKind.display) {
        await _permissionsChannel.invokeMethod<bool>('requestScreenCapture');
      } else {
        await _permissionsChannel.invokeMethod<bool>('requestCamera');
      }

      if (settings.media.audioEnabled) {
        await _permissionsChannel.invokeMethod<bool>('requestMicrophone');
      }
    } catch (error) {
      debugPrint('Permission request failed: $error');
    }
  }
```

Preview behavior for the display path: the `_nativeCameraController` assignment already requires `backend is CameraStreamBackend` (a `ScreenCaptureStreamBackend` yields null), so the preview falls back to the RTSP-snapshot timer that Task 14 of the previous plan made unconditional. Verify `_CameraPreviewCard` shows the snapshot path when `nativeController == null` on macOS: change its condition from the passed-in `useCameraPreview` flag to also require a controller — pass `useCameraPreview: _useNativeCamera && _nativeCameraController != null` at the call site so the display path renders `Image.memory(previewFrame)` like Windows/Linux.

- [ ] **Step 4: UI Source row.** In `_StatusCard`, add a `source` parameter (`final String source;`) rendered as `_row(context, 'Source', source)` under the RTSP row, and build it in `ServerHomePage.build`:

```dart
    final media = (_settings ?? const ServerSettings()).media;
    final source = switch (media.videoSource) {
      VideoSourceKind.camera =>
        'Camera${media.videoDevice.isEmpty ? '' : ': ${media.videoDevice}'}',
      VideoSourceKind.display =>
        'Display${media.videoDevice.isEmpty ? ' (main)' : ' ${media.videoDevice}'}',
      VideoSourceKind.test => 'Test pattern',
    }
    // ignore: dead_null_aware_expression
    ;
    final sourceLabel = media.audioEnabled ? '$source + audio' : source;
```

(pass `source: sourceLabel`). Remove the `// ignore` line if the analyzer does not require it — write it as a plain `final source = switch … ;` statement.

- [ ] **Step 5: Settings asset + README.** Append to `assets/settings.yaml`:

```yaml
#
# media:
#   video:
#     source: camera             # camera | display | test
#     device: ""                 # raw platform id, empty = default:
#                                #   camera: plugin device name (macOS/mobile),
#                                #     dshow name (Windows), /dev/video0 (Linux)
#                                #   display: CGDirectDisplayID (macOS),
#                                #     gdigrab target (Windows), :0.0 (Linux)
#   audio:
#     enabled: false             # serve G.711 audio as a second RTSP track
#     device: ""                 # raw platform id, empty = default input:
#                                #   CoreAudio device UID (macOS),
#                                #   dshow name (Windows), hw:1 / pulse (Linux)
```

Update `README.md`:
- Features list: add "**Audio streaming** — the selected input device is served as a G.711 (PCMA) track in the same RTSP stream, recorded to `.alaw` sidecars, and replayed."
- Settings schema block: insert the `media:` section exactly as in the asset (uncommented form).
- Recording storage layout: add `seg_00001.alaw      # G.711 A-law audio sidecar (8000 bytes/second)` line.
- Add a short "Choosing what to stream" subsection: source kinds per platform, raw-identifier discovery hints (`ffmpeg -f avfoundation -list_devices true -i ""`, `ffmpeg -list_devices true -f dshow -i dummy`, `v4l2-ctl --list-devices`, `system_profiler SPDisplaysDataType` / Displays settings for CGDirectDisplayID, `SwitchAudioSource -a` or Audio MIDI Setup for macOS audio UIDs), and the macOS Screen Recording permission note.

- [ ] **Step 6: Verify** — `flutter analyze`, full suite (`flutter test`), `flutter build macos --debug`. All green.

- [ ] **Step 7: Commit**

```bash
rtk git add lib/main.dart lib/src/streaming/camera_stream_backend.dart assets/settings.yaml README.md
rtk git commit -m "feat(server): settings-driven source selection with audio wiring"
```

---

### Task 12: Final verification sweep

- [ ] **Step 1: Full static + test pass**

```bash
flutter analyze          # expected: No issues found
flutter test             # expected: all suites pass (42 old + ~10 new)
flutter build macos --debug
```

- [ ] **Step 2: Regression checks against the design**

- Audio disabled (default settings): SDP has no `m=audio`; recordings have no `.alaw`; `GetAudioSourceConfigurations`/`GetAudioEncoderConfigurations` return empty responses. (Covered by existing suites staying green + Task 5 handlers.)
- Audio enabled: live RTSP, recorded sidecars, and replay all carry `pcm_alaw` (Tasks 4, 6, 7 tests).
- `media.video.source: display`/`test`/invalid parse behavior (Task 1 tests).

- [ ] **Step 3: Manual smoke (optional, macOS)**

`flutter run -d macos` with `~/.easy_onvif_server/settings.yaml`:

```yaml
media:
  video:
    source: display
  audio:
    enabled: true
```

→ grant Screen Recording + Microphone → VLC plays `rtsp://<host>:8554/onvif/Profile_1` showing the desktop with live mic audio; then a recording made via the tests/CLI replays with audio at `rtsp://<host>:8554/onvif/replay/<token>`.

- [ ] **Step 4: Commit any leftovers**, then report the branch state.

---

## Self-Review Notes

- **Spec coverage:** Design §1 → Tasks 1, 11 (schema, matrix, raw identifiers). §2 → Tasks 2–4, 8, 9 (A-law, sources, RTSP track, native capture). §3 → Tasks 10, 11 (SCK backend, gdigrab/x11grab args, permissions, preview). §4 → Tasks 6, 7 (sidecars, replay, prune, seek). §5 → Tasks 5, 11, 12 (SOAP ops, UI row, tests).
- **Type consistency:** `AudioFrame(data, timestamp)` positional; `AudioStreamSource.frames/start/stop`; `AlawFramer(onFrame)` + `add(List<int>)` + `frameBytes = 160`; `RtpPacketizer.packetizeRaw(payload, {timestamp, marker})`; `RtspServer(source:, port:, replaySourceFor:, audioSource:)` + public `buildSdp(source, {hasAudio})`; `FileH264Source.hasAudio/audioFrames`; `RecordingSegment.audioFile` (mutable `String?`); `RecordingIndex.audioFile(segment)`; backends' `audioSource` getter satisfied by a final ctor field; `NativeAudioSource.addPcmBytes`; channel names `easy_onvif_server/audio_capture[/events]`, `easy_onvif_server/screen_capture`, reused `easy_onvif_server/h264_encoder/events`.
- **Known risks called out inline:** VideoToolboxEncoder Swift argument labels (Task 10 Step 1 verifies first); pbxproj registration for new Swift files (Tasks 8–10); `StreamSetup`/`Transport` import names for the replay client call (copy from the existing replay test); iOS/Android builds optional when toolchains are absent.
- **Client-compat note:** the `easy_onvif` client facade has no `getAudioSourceConfigurations`/`getAudioEncoderConfigurations` methods, so Task 5 tests use low-level SOAP requests (same pattern as existing coverage tests).
- **Out of scope (per design):** RTCP sender reports (A/V sync is approximate), AAC, ONVIF audio backchannel, per-job audio toggle, Wayland capture.
