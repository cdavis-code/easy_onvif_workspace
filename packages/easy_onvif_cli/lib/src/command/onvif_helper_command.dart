import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:easy_onvif/credentials.dart';
import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/util.dart';

abstract class OnvifHelperCommand extends Command {
  Onvif? _onvif;

  Onvif get onvif => _onvif!;

  DeviceManagement get deviceManagement => onvif.deviceManagement;

  Imaging get imaging => onvif.imaging;

  Media get media => onvif.media;

  Ptz get ptz => onvif.ptz;

  Recordings get recordings => onvif.recordings;

  Replay get replay => onvif.replay;

  Search get search => onvif.search;

  Future<void> initializeOnvif() async {
    final timeout = int.parse(globalResults!['network-timeout']);

    // Encrypted bundle or legacy plaintext; ONVIF_HOST/USERNAME/PASSWORD win.
    final device = await CredentialStore.resolveDevice(
      globalResults!['config-file'] as String,
      deviceId: globalResults!['device'] as String?,
      keyFile: globalResults!['key-file'] as String?,
    );

    // configure device connection
    _onvif = await Onvif.connect(
      host: device.host,
      username: device.username,
      password: device.password,
      logOptions: OnvifUtil.convertToLogOptions(globalResults!['log-level']),
      dio: Dio(
        BaseOptions(
          connectTimeout: Duration(seconds: timeout),
          receiveTimeout: Duration(seconds: timeout),
        ),
      ),
    );
  }
}
