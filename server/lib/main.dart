import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:loggy/loggy.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/flutter_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/streaming/camera_stream_backend.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_backend.dart';
import 'package:easy_onvif_server/src/streaming/stream_backend.dart';

void main() {
  runApp(const OnvifServerApp());
}

class OnvifServerApp extends StatelessWidget {
  const OnvifServerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONVIF Server',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const ServerHomePage(),
    );
  }
}

class ServerHomePage extends StatefulWidget {
  const ServerHomePage({super.key});

  @override
  State<ServerHomePage> createState() => _ServerHomePageState();
}

class _ServerHomePageState extends State<ServerHomePage> {
  final ServerConfig _config = const ServerConfig();

  /// Settings loaded at start (runtime override file or the bundled asset);
  /// null until the server has been started at least once.
  ServerSettings? _settings;

  OnvifDevice? _device;
  FlutterAdapter? _adapter;

  bool _running = false;
  bool _busy = false;
  String _host = 'localhost';

  /// Latest JPEG frame grabbed from the RTSP stream for the ffmpeg preview path
  /// (Windows/Linux). Unused where the app owns the camera directly.
  Uint8List? _previewFrame;
  Timer? _previewTimer;
  bool _refreshing = false;

  /// The camera controller owned by the native stream backend (mobile + macOS
  /// via `camera_desktop`). The UI shows a live preview from it.
  CameraController? _nativeCameraController;

  /// True when the app captures the camera in-process for the stream (mobile,
  /// and macOS via `camera_desktop` + VideoToolbox). The preview then comes from
  /// the camera controller. False where an `ffmpeg` subprocess owns the camera
  /// (Windows/Linux), in which case the preview is grabbed from the RTSP stream.
  bool get _useNativeCamera =>
      Platform.isIOS || Platform.isAndroid || Platform.isMacOS;

  /// Native channel used to trigger the macOS camera/microphone TCC prompt.
  ///
  /// macOS attributes camera access to the host app, so the app requests the
  /// grant up front; the in-process AVFoundation capture (camera_desktop) then
  /// works without a separate prompt.
  static const MethodChannel _permissionsChannel = MethodChannel(
    'easy_onvif_server/permissions',
  );

  @override
  void initState() {
    super.initState();
    _resolveHost();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _device?.stop();
    super.dispose();
  }

  Future<void> _resolveHost() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) {
            if (mounted) setState(() => _host = address.address);
            return;
          }
        }
      }
    } catch (_) {
      // Keep the default host.
    }
  }

  /// Picks an ffmpeg video input for the current platform: the default webcam
  /// where a capture backend is known, otherwise a generated test pattern.
  List<String> _platformVideoInput() {
    if (Platform.isMacOS) {
      return [
        '-f',
        'avfoundation',
        '-framerate',
        '15',
        '-video_size',
        '1280x720',
        '-i',
        '0',
      ];
    }

    if (Platform.isLinux) {
      return [
        '-f',
        'v4l2',
        '-framerate',
        '15',
        '-video_size',
        '1280x720',
        '-i',
        '/dev/video0',
      ];
    }

    if (Platform.isWindows) {
      return [
        '-f',
        'dshow',
        '-framerate',
        '15',
        '-video_size',
        '1280x720',
        '-i',
        'video=Integrated Camera',
      ];
    }

    // Mobile / unknown: fall back to a generated test pattern. Real camera
    // frame ingestion is a follow-up (RTSP Phase 2/3).
    return ['-f', 'lavfi', '-i', 'testsrc=size=1280x720:rate=15'];
  }

  /// Locates the `ffmpeg` executable. GUI apps launched from Finder/Spotlight
  /// do not inherit the shell's PATH (so `/opt/homebrew/bin` is missing), so
  /// probe the common install locations before falling back to a bare `ffmpeg`.
  String _resolveFfmpegPath() {
    const candidates = [
      '/opt/homebrew/bin/ffmpeg',
      '/usr/local/bin/ffmpeg',
      '/usr/bin/ffmpeg',
    ];

    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }

    return 'ffmpeg';
  }

  /// Chooses the streaming backend for the current platform.
  ///
  /// On mobile (iOS/Android) and macOS the device camera is captured in-process
  /// and encoded directly via [CameraStreamBackend] (macOS uses `camera_desktop`
  /// for capture and VideoToolbox for H.264). On Windows/Linux, [FfmpegBackend]
  /// shells out to `ffmpeg` (webcam or test pattern).
  StreamBackend _createStreamBackend(ServerConfig config) {
    if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
      return CameraStreamBackend(config: config, frameRate: 15);
    }

    return FfmpegBackend(
      config: config,
      ffmpegPath: _resolveFfmpegPath(),
      frameRate: 15,
      inputArgs: _platformVideoInput(),
    );
  }

  Future<void> _start() async {
    setState(() => _busy = true);

    try {
      // macOS attributes camera access to the host app; request the grant up
      // front so the in-process AVFoundation capture works without a separate
      // prompt racing the encoder startup.
      await _ensureCameraPermission();

      // Where the stream backend owns the camera (mobile + macOS), the camera
      // plugin must not also open it (one consumer per device); the preview
      // reuses the backend's controller instead.
      final adapter = FlutterAdapter(enableCamera: !_useNativeCamera);

      // Runtime settings override the compiled-in defaults; the bundled asset
      // documents the schema and yields defaults when no override exists.
      final bundled = await rootBundle.loadString('assets/settings.yaml');
      final settings = await ServerSettings.load(fallbackYaml: bundled);

      final backend = _createStreamBackend(settings.config);

      final device = OnvifDevice(
        config: settings.config,
        hardware: adapter,
        streamBackend: backend,
        settings: settings,
        enableDiscovery: true,
        advertisedHost: _host,
      );

      await device.start(
        logOptions: const LogOptions(LogLevel.info),
        printer: const PrettyDeveloperPrinter(),
      );

      if (mounted) {
        setState(() {
          _device = device;
          _adapter = adapter;
          _settings = settings;
          _running = true;
          _nativeCameraController =
              _useNativeCamera && backend is CameraStreamBackend
              ? backend.controller
              : null;
        });

        // The ffmpeg path (Windows/Linux) has no in-app camera; drive the
        // preview by grabbing frames from the RTSP stream instead.
        if (!_useNativeCamera) _startPreviewTimer();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start server: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Ensures the macOS camera permission has been requested. On macOS the
  /// ffmpeg subprocess cannot trigger a TCC prompt itself, so the host app must
  /// obtain the grant; the child then inherits access. A no-op elsewhere.
  Future<void> _ensureCameraPermission() async {
    if (!Platform.isMacOS) return;

    try {
      await _permissionsChannel.invokeMethod<bool>('requestCamera');
    } catch (error) {
      // Best effort: if the channel is unavailable ffmpeg will surface the
      // failure via its stderr, which the backend logs.
      debugPrint('Camera permission request failed: $error');
    }
  }

  /// Periodically grabs a JPEG frame from the RTSP stream to drive the desktop
  /// preview (the camera plugin is not used on desktop).
  void _startPreviewTimer() {
    _previewTimer?.cancel();
    _refreshPreview();
    _previewTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshPreview(),
    );
  }

  Future<void> _refreshPreview() async {
    if (_refreshing) return;

    _refreshing = true;

    try {
      final frame = await _device?.streamBackend.snapshot();

      if (frame != null && mounted) {
        setState(() => _previewFrame = frame);
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _stop() async {
    setState(() {
      _busy = true;
      // Clear the controller reference BEFORE stopping the device so the
      // widget tree never tries to build CameraPreview with a controller that
      // is about to be (or has been) disposed.
      _nativeCameraController = null;
      _previewFrame = null;
    });

    _previewTimer?.cancel();
    _previewTimer = null;

    await _device?.stop();

    if (mounted) {
      setState(() {
        _device = null;
        _adapter = null;
        _running = false;
      });
    }

    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    // Before the first start, show the compiled-in defaults; afterwards show
    // the ports/credentials actually loaded from settings.
    final config = _settings?.config ?? _config;
    final deviceUrl = 'http://$_host:${config.httpPort}/onvif/device_service';
    final rtspUrl =
        'rtsp://$_host:${config.rtspPort}/onvif/'
        '${Uri.encodeComponent('Profile_1')}';

    return Scaffold(
      appBar: AppBar(title: const Text('ONVIF Server')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusCard(
                running: _running,
                host: _host,
                deviceUrl: deviceUrl,
                rtspUrl: rtspUrl,
                username: config.username,
                password: config.password,
              ),
              if (_running && _device?.recordingManager != null) ...[
                const SizedBox(height: 16),
                _RecordingStatusCard(
                  device: _device!,
                  host: _host,
                  rtspPort: config.rtspPort,
                ),
              ],
              const SizedBox(height: 16),
              _CameraPreviewCard(
                adapter: _adapter,
                running: _running,
                previewFrame: _previewFrame,
                nativeController: _nativeCameraController,
                useCameraPreview: _useNativeCamera,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : (_running ? _stop : _start),
                icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                label: Text(_running ? 'Stop Server' : 'Start Server'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool running;
  final String host;
  final String deviceUrl;
  final String rtspUrl;
  final String username;
  final String password;

  const _StatusCard({
    required this.running,
    required this.host,
    required this.deviceUrl,
    required this.rtspUrl,
    required this.username,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  running ? Icons.check_circle : Icons.pause_circle_outline,
                  color: running ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  running ? 'Running on $host' : 'Stopped',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            _row(context, 'Device service', deviceUrl),
            _row(context, 'RTSP stream', rtspUrl),
            _row(context, 'Username', username),
            _row(context, 'Password', password),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

/// Shows the recording subsystem's live state: how many recordings exist on
/// disk, whether a job is actively capturing, and the replay URL scheme.
/// Refreshed by the parent's periodic preview/setState cycle.
class _RecordingStatusCard extends StatelessWidget {
  final OnvifDevice device;
  final String host;
  final int rtspPort;

  const _RecordingStatusCard({
    required this.device,
    required this.host,
    required this.rtspPort,
  });

  @override
  Widget build(BuildContext context) {
    final manager = device.recordingManager;
    final recordings = manager?.recordings ?? const [];
    final active = manager?.jobs.any((job) => job.mode == 'Active') ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  active ? Icons.fiber_manual_record : Icons.videocam_off,
                  color: active ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recording',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            _row(context, 'Recordings', '${recordings.length}'),
            _row(context, 'Job state', active ? 'Active' : 'Idle'),
            _row(
              context,
              'Replay URL',
              'rtsp://$host:$rtspPort/onvif/replay/<recordingToken>',
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _CameraPreviewCard extends StatelessWidget {
  final FlutterAdapter? adapter;
  final bool running;
  final Uint8List? previewFrame;

  /// The camera controller owned by the native stream backend (mobile + macOS).
  /// When present and [useCameraPreview] is true, the preview shows its live
  /// feed; otherwise the preview falls back to RTSP-stream JPEG frames.
  final CameraController? nativeController;

  /// When true the preview uses an in-app camera controller; when false it
  /// shows JPEG frames grabbed from the RTSP stream (ffmpeg desktop path).
  final bool useCameraPreview;

  const _CameraPreviewCard({
    required this.adapter,
    required this.running,
    required this.previewFrame,
    required this.nativeController,
    required this.useCameraPreview,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer the stream backend's camera (mobile + macOS); fall back to the
    // hardware adapter's camera where that is used instead.
    final controller = nativeController ?? adapter?.controller;

    final Widget content;
    if (useCameraPreview &&
        running &&
        controller != null &&
        controller.value.isInitialized) {
      // The controller is already initialized by the time it is stored in state
      // (the backend's start() awaits initialization). We do NOT wrap this in
      // an AnimatedBuilder/ValueListenableBuilder because the controller's
      // dispose() fires notifyListeners(), which would trigger a rebuild on a
      // disposed controller before the parent clears the reference.
      content = CameraPreview(controller);
    } else if (!useCameraPreview && running && previewFrame != null) {
      content = Image.memory(previewFrame!, fit: BoxFit.contain);
    } else {
      content = _placeholder(
        running ? 'Waiting for stream…' : 'No camera preview',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Camera', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(String message) {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: Text(message),
    );
  }
}
