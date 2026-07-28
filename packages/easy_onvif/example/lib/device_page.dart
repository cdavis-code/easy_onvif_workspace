import 'package:easy_onvif/probe.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DevicePage extends StatelessWidget {
  final multicastProbe = MulticastProbe(releaseMode: kReleaseMode);

  DevicePage({super.key});

  Future<List<ProbeMatch>> fetchDevices() async {
    await multicastProbe.probe();

    return multicastProbe.onvifDevices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Center(
        child:
            kIsWeb
                ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'ONVIF discovery is not available in the browser.\n\n'
                    'Browsers cannot open the UDP sockets required for '
                    'multicast discovery. Connect to a device by its host on '
                    'the previous screen instead.',
                    textAlign: TextAlign.center,
                  ),
                )
                : Column(
                  children: [
                    const Text(kReleaseMode ? 'release' : 'debug'),
                    FutureBuilder<List<ProbeMatch>>(
                      future: fetchDevices(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(snapshot.data![index].name),
                                subtitle: Text(snapshot.data![index].xAddr),
                              );
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Text('${snapshot.error}');
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
      ),
    );
  }
}
