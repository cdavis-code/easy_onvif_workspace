import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/ptz.dart';
import 'package:loggy/loggy.dart';
import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  // get connection information from the config.yaml file
  final config = loadYaml(File('config.yaml').readAsStringSync());

  // configure device connection
  final onvif = await Onvif.connect(
    host: config['host'],
    username: config['username'],
    password: config['password'],
    logOptions: const LogOptions(
      LogLevel.debug,
      stackTraceLevel: LogLevel.error,
    ),
    printer: const PrettyPrinter(showColors: true),
  );

  var profiles = await onvif.media.getProfiles(); // Access Class: READ_MEDIA

  for (var element in profiles) {
    print('${element.name}  ${element.token}');
  }

  var profileToken = profiles.first.token;

  var presets = await onvif.ptz.getPresets(profileToken);

  var preset = presets[0];

  print(preset);

  //print the preset values
  print(
    'preset: ${preset.token} - ${preset.name} ${preset.position?.panTilt?.x}  ${preset.position?.panTilt?.y}  ${preset.position?.zoom?.x}',
  );

  var serialized = preset.toJson();

  print(Preset.fromJson(serialized));
}
