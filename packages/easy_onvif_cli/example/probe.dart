import 'package:easy_onvif/probe.dart';

void main(List<String> arguments) async {
  final multicastProbe = MulticastProbe();

  await multicastProbe.probe();

  for (var device in multicastProbe.onvifDevices) {
    print(
      '${device.name} ${device.location} ${device.hardware} ${device.xAddr}',
    );
  }
}
