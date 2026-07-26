import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_onvif/device_management.dart' as device;
import 'package:easy_onvif/onvif.dart' hide Media;
import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:loggy/loggy.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:yaml/yaml.dart';

import 'device_page.dart';
import 'webrtc_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Required by media_kit before any Player/VideoController is created.
  MediaKit.ensureInitialized();

  runApp(const MyApp());
}

/// The two viewing modes the home page can display.
enum ViewMode { snapshot, video }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onvif Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: const MyHomePage(title: 'Onvif Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with UiLoggy {
  late final List<MixedProfile> profiles;

  late final device.GetDeviceInformationResponse deviceInfo;

  late final YamlMap config;

  String? snapshotUri;

  String? streamUri;

  bool connecting = true;

  String model = '';

  String manufacturer = '';

  String firmwareVersion = '';

  String url = '';

  /// HTTP Basic `Authorization` header for the snapshot endpoint (the server
  /// requires authentication; `CachedNetworkImage` does not derive it from the
  /// URL's embedded credentials).
  Map<String, String> _snapshotHeaders = const {};

  String videoUrl = '';

  /// The currently active viewing mode.
  ViewMode _viewMode = ViewMode.snapshot;

  /// Live-video resources, created lazily when the user switches to video
  /// mode and disposed when they switch away (or the page is disposed).
  Player? _player;

  VideoController? _videoController;

  @override
  void initState() {
    _initialize();

    super.initState();
  }

  @override
  void dispose() {
    // Drop the reference before disposing so the widget tree never rebuilds
    // against a torn-down controller.
    final player = _player;
    _player = null;
    _videoController = null;
    player?.dispose();

    super.dispose();
  }

  Future<void> _initialize() async {
    final yamlData = await services.rootBundle.loadString('assets/config.yaml');

    config = loadYaml(yamlData);

    // configure device connection
    final onvif = await Onvif.connect(
      host: config['host'],
      username: config['username'],
      password: config['password'],
      logOptions: const LogOptions(
        LogLevel.debug,
        stackTraceLevel: LogLevel.off,
      ),
      printer: const PrettyDeveloperPrinter(),
    );

    setState(() {
      connecting = false;
    });

    deviceInfo = await onvif.deviceManagement.getDeviceInformation();

    profiles = await onvif.media.getProfiles();

    try {
      if (profiles.isNotEmpty) {
        snapshotUri = await onvif.media.getSnapshotUri(profiles[0].token);
        streamUri = await onvif.media.getStreamUri(profiles[0].token);
      }
    } catch (err) {
      loggy.error(err.toString());
    }

    // Populate the displayed fields now that device info is available, so the
    // user does not have to press the floating "Get" button first.
    _update();
  }

  void _update() async {
    setState(() {
      model = deviceInfo.model ?? '';

      manufacturer = deviceInfo.manufacturer ?? '';

      firmwareVersion = deviceInfo.firmwareVersion;

      if (snapshotUri != null) {
        url = OnvifUtil.authenticatingUri(
          snapshotUri!,
          config['username']!,
          config['password']!,
        );

        final credentials = base64.encode(
          utf8.encode('${config['username']}:${config['password']}'),
        );
        _snapshotHeaders = {'Authorization': 'Basic $credentials'};
      }

      if (streamUri != null) {
        videoUrl = OnvifUtil.authenticatingUri(
          streamUri!,
          config['username']!,
          config['password']!,
        );
      }
    });
  }

  /// Switches to live video, creating the player on first use.
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
    final controller = VideoController(player);

    setState(() {
      _player = player;
      _videoController = controller;
      _viewMode = ViewMode.video;
    });

    try {
      await player.open(Media(videoUrl));
    } catch (err) {
      loggy.error('Failed to open stream: $err');
    }
  }

  /// Switches back to the still snapshot, tearing down the player.
  Future<void> _enterSnapshotMode() async {
    if (_viewMode == ViewMode.snapshot) return;

    final player = _player;

    // Null the references first so the Video widget is removed from the tree
    // before the underlying player is disposed.
    setState(() {
      _viewMode = ViewMode.snapshot;
      _player = null;
      _videoController = null;
    });

    await player?.dispose();
  }

  Future<void> _setViewMode(ViewMode mode) async {
    switch (mode) {
      case ViewMode.video:
        await _enterVideoMode();
      case ViewMode.snapshot:
        await _enterSnapshotMode();
    }
  }

  Widget _buildModeToggle() {
    return ToggleButtons(
      isSelected: [_viewMode == ViewMode.snapshot, _viewMode == ViewMode.video],
      onPressed:
          (index) =>
              _setViewMode(index == 0 ? ViewMode.snapshot : ViewMode.video),
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      selectedBorderColor: Theme.of(context).primaryColor,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.photo_camera),
              SizedBox(width: 8),
              Text('Snapshot'),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.videocam),
              SizedBox(width: 8),
              Text('Live Video'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedia() {
    final Widget media = switch (_viewMode) {
      ViewMode.snapshot =>
        url != ''
            ? CachedNetworkImage(
              imageUrl: url,
              httpHeaders: _snapshotHeaders,
              progressIndicatorBuilder:
                  (context, url, downloadProgress) => CircularProgressIndicator(
                    value: downloadProgress.progress,
                  ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            )
            : const Text('Snapshot not available'),
      ViewMode.video =>
        kIsWeb
            ? WebrtcPlayer(
              host: '${config['host']}',
              username: '${config['username']}',
              password: '${config['password']}',
            )
            : (_videoController != null
                ? Video(controller: _videoController!, controls: NoVideoControls())
                : const Text('Live video not available')),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: AspectRatio(
        key: ValueKey(_viewMode),
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ColoredBox(color: Colors.black, child: media),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.device_hub),
            onPressed:
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => DevicePage())),
          ),
        ],
      ),
      body: SafeArea(
        child:
            connecting
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Connecting to camera'),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Device Manufacturer:'),
                      ),
                      Text(
                        manufacturer,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Model:'),
                      ),
                      Text(
                        model,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Firmware Version:'),
                      ),
                      Text(
                        firmwareVersion,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildModeToggle(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                        child: _buildMedia(),
                      ),
                    ],
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _update,
        tooltip: 'Update',
        child: const Text('Get'),
      ),
    );
  }
}
