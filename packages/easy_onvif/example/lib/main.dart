import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_onvif/device_management.dart' as device;
import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:loggy/loggy.dart';
import 'package:yaml/yaml.dart';

import 'device_page.dart';

void main() {
  runApp(const MyApp());
}

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

  bool connecting = true;

  String model = '';

  String manufacturer = '';

  String firmwareVersion = '';

  String url = '';

  @override
  void initState() {
    _initialize();

    super.initState();
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
      }
    } catch (err) {
      loggy.error(err.toString());
    }
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
      }
    });
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
        child: Center(
          child:
              connecting
                  ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Connecting to camera'),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  )
                  : Column(
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Snapshot: ${snapshotUri ?? 'Not available'}',
                        ),
                      ),
                      url != ''
                          ? Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) =>
                                      CircularProgressIndicator(
                                        value: downloadProgress.progress,
                                      ),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.error),
                            ),
                          )
                          : Container(),
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
