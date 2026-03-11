import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/recordings.dart';
import 'package:loggy/loggy.dart';
import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  // get connection information from the config.yaml file
  final config = loadYaml(File('example/config.yaml').readAsStringSync());

  // configure device connection
  final onvif = await Onvif.connect(
    host: config['host'],
    username: config['username'],
    password: config['password'],
    logOptions: const LogOptions(LogLevel.debug, stackTraceLevel: LogLevel.off),
    printer: const PrettyPrinter(showColors: true),
  );

  final recordingJobConfiguration = RecordingJobConfiguration(
    recordingToken: 'OnvifRecordingToken_1',
    mode: RecordingJobConfigurationMode.active,
    priority: 1,
    source: RecordingJobSource(
      sourceToken: SourceToken(
        // type: 'http://www.onvif.org/ver10/schema/Profile',
        token: 'Profile_1',
      ),
      // autoCreateReceiver: true,
    ),
  );

  var createRecordingJobResponse = await onvif.recordings.createRecordingJob(
    recordingJobConfiguration,
  );

  print(createRecordingJobResponse.jobConfiguration);

  // var recordingToken = await onvif.recordings.createRecording(
  //     RecordingConfiguration(
  //         source: RecordingSourceInformation(
  //             sourceId: 'SourceId_1',
  //             name: 'IpCamera_1',
  //             location: 'Location',
  //             description: 'Description of source',
  //             address: 'http://www.onvif.org/ver10/schema/Profile'),
  //         content: 'Test Recording',
  //         maximumRetentionTime: 'PT0S'));

  // print(recordingToken);
}
