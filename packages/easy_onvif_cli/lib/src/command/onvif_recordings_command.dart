import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:easy_onvif/recordings.dart';
import 'package:easy_onvif/util.dart';

import 'onvif_helper_command.dart';

/// recordings
class OnvifRecordingsCommand extends Command {
  @override
  String get description => 'Recordings commands.';

  @override
  String get name => 'recordings';

  OnvifRecordingsCommand() {
    addSubcommand(OnvifCreateRecordingRecordingsCommand());
    addSubcommand(OnvifCreateRecordingJobRecordingsCommand());
    addSubcommand(OnvifDeleteRecordingRecordingsCommand());
    addSubcommand(OnvifDeleteRecordingJobRecordingsCommand());
    addSubcommand(OnvifGetRecordingOptionsRecordingsCommand());
    addSubcommand(OnvifGetRecordingsRecordingsCommand());
    addSubcommand(OnvifGetServiceCapabilitiesRecordingsCommand());
    addSubcommand(OnvifGetRecordingJobsRecordingsCommand());
    addSubcommand(OnvifGetRecordingJobStateRecordingsCommand());
    addSubcommand(OnvifSetRecordingJobModeRecordingsCommand());
  }
}

/// CreateRecording shall create a new recording. The new recording shall be
/// created with a track for each supported TrackType see Recording Control
/// Spec.
///
/// This method is optional. It shall be available if the
/// Recording/DynamicRecordings capability is TRUE.
///
/// When successfully completed, CreateRecording shall have created three tracks
/// with the following configurations:
/// - TrackToken TrackType
/// - VIDEO001 Video
/// - AUDIO001 Audio
/// - META001 Metadata
/// All TrackConfigurations shall have the MaximumRetentionTime set to 0
/// (unlimited), and the Description set to the empty string.
class OnvifCreateRecordingRecordingsCommand extends OnvifHelperCommand {
  @override
  String get description => 'create-recording shall create a new recording.';

  @override
  String get name => 'create-recording';

  OnvifCreateRecordingRecordingsCommand() {
    argParser
      ..addOption(
        'source-source-id',
        valueHelp: 'string',
        mandatory: true,
        help:
            'Identifier for the source chosen by the client that creates the structure. This identifier is opaque to the device. Clients may use any type of URI for this field. A device shall support at least 128 characters.',
      )
      ..addOption(
        'source-name',
        valueHelp: 'string',
        mandatory: true,
        help:
            'Informative user readable name of the source, e.g. "Camera23". A device shall support at least 20 characters.',
      )
      ..addOption(
        'source-location',
        valueHelp: 'string',
        mandatory: true,
        help:
            'Informative description of the physical location of the source, e.g. the coordinates on a map.',
      )
      ..addOption(
        'source-description',
        valueHelp: 'string',
        mandatory: true,
        help: 'Informative description of the source.',
      )
      ..addOption(
        'source-address',
        valueHelp: 'string',
        mandatory: true,
        help:
            'URI provided by the service supplying data to be recorded. A device shall support at least 128 characters.',
      )
      ..addOption(
        'content',
        valueHelp: 'string',
        mandatory: true,
        help: 'Informative description of the source.',
      )
      ..addOption(
        'maximum-retention-time',
        valueHelp: 'duration',
        defaultsTo: 'PT0S',
        help:
            'Specifies the maximum time that data in any track within the recording shall be stored. The device shall delete any data older than the maximum retention time. Such data shall not be accessible anymore. If the MaximumRetentionPeriod is set to 0, the device shall not limit the retention time of stored data, except by resource constraints. Whatever the value of MaximumRetentionTime, the device may automatically delete recordings to free up storage space for new recordings.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final recordingToken = await recordings.createRecording(
        RecordingConfiguration(
          source: RecordingSourceInformation(
            sourceId: argResults!['source-source-id'],
            name: argResults!['source-name'],
            location: argResults!['source-location'],
            description: argResults!['source-description'],
            address: argResults!['source-address'],
          ),
          content: argResults!['content'],
          maximumRetentionTime: argResults!['maximum-retention-time'],
        ),
      );

      print(recordingToken);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// CreateRecordingJob shall create a new recording job.
///
/// The JobConfiguration returned from CreateRecordingJob shall be identical to
/// the JobConfiguration passed into CreateRecordingJob, except for the
/// ReceiverToken and the AutoCreateReceiver. In the returned structure, the
/// ReceiverToken shall be present and valid and the AutoCreateReceiver field
/// shall be omitted.
class OnvifCreateRecordingJobRecordingsCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'create-recording-job shall create a new recording job.';

  @override
  String get name => 'create-recording-job';

  OnvifCreateRecordingJobRecordingsCommand() {
    argParser
      ..addOption(
        'job-configuration-schedule-token',
        valueHelp: 'string',
        help:
            'This attribute adds an additional requirement for activating the recording job. If this optional field is provided the job shall only record if the schedule exists and is active.',
      )
      ..addOption(
        'job-configuration-recording-token',
        valueHelp: 'string',
        mandatory: true,
        help:
            'Identifies the recording to which this job shall store the received data.',
      )
      ..addOption(
        'job-configuration-mode',
        valueHelp: 'string',
        allowed: RecordingJobConfigurationMode.values
            .map((mode) => mode.value)
            .toList(),
        help:
            '''The mode of the job. If it is idle, nothing shall happen. If it is active, the device shall try to obtain data from the receivers. A client shall use GetRecordingJobState to determine if data transfer is really taking place.

The only valid values for Mode shall be “Idle” and “Active”.''',
      )
      ..addOption(
        'job-configuration-priority',
        valueHelp: 'int',
        mandatory: true,
        help:
            'This shall be a non-negative number. If there are multiple recording jobs that store data to the same track, the device will only store the data for the recording job with the highest priority. The priority is specified per recording job, but the device shall determine the priority of each track individually. If there are two recording jobs with the same priority, the device shall record the data corresponding to the recording job that was activated the latest.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final createRecordingJobResponse = await recordings.createRecordingJob(
        RecordingJobConfiguration(
          recordingToken: argResults![''],
          mode: argResults![''],
          priority: argResults![''],
        ),
      );

      print(createRecordingJobResponse);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// DeleteRecording shall delete a recording object. Whenever a recording is
/// deleted, the device shall delete all the tracks that are part of the
/// recording, and it shall delete all the Recording Jobs that record into the
/// recording. For each deleted recording job, the device shall also delete
/// all the receiver objects associated with the recording job that are
/// automatically created using the AutoCreateReceiver field of the recording
/// job configuration structure and are not used in any other recording job.
///
/// This method is optional. It shall be available if the
/// Recording/DynamicRecordings capability is TRUE.
class OnvifDeleteRecordingRecordingsCommand extends OnvifHelperCommand {
  @override
  String get description => 'delete-recording shall delete a recording object.';

  @override
  String get name => 'delete-recordings';

  OnvifDeleteRecordingRecordingsCommand() {
    argParser.addOption(
      'recording-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help: 'The reference of the recording to be deleted.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await recordings.deleteRecording(argResults!['recording-token']);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// DeleteRecordingJob removes a recording job. It shall also implicitly delete
/// all the receiver objects associated with the recording job that are
/// automatically created using the AutoCreateReceiver field of the recording
/// job configuration structure and are not used in any other recording job.
class OnvifDeleteRecordingJobRecordingsCommand extends OnvifHelperCommand {
  @override
  String get description => 'delete-recordings removes a recording job.';

  @override
  String get name => 'delete-recording-job';

  OnvifDeleteRecordingJobRecordingsCommand() {
    argParser.addOption(
      'job-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help: 'The token of the job to be deleted.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await recordings.deleteRecording(argResults!['job-token']);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// GetRecordingOptions returns information for a recording identified by the
/// RecordingToken. The information includes the number of additional tracks as
/// well as recording jobs that can be configured.
class OnvifGetRecordingOptionsRecordingsCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'get-recording-options returns information for a recording identified by the RecordingToken.';

  @override
  String get name => 'get-recording-options';

  OnvifGetRecordingOptionsRecordingsCommand() {
    argParser.addOption(
      'recording-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help: 'Token of the recording.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final recordingOptions = await recordings.getRecordingOptions(
        argResults!['recording-token'],
      );

      print(recordingOptions);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// GetRecordings shall return a description of all the recordings in the
/// device. This description shall include a list of all the tracks for each
/// recording.
class OnvifGetRecordingsRecordingsCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'get-recordings shall return a description of all the recordings in the device.';

  @override
  String get name => 'get-recordings';

  @override
  void run() async {
    await initializeOnvif();

    try {
      final recordingItems = await recordings.getRecordings();

      print(recordingItems);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

class OnvifGetRecordingJobsRecordingsCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'get-recording-jobs shall return a description of all the recordings in the device.';

  @override
  String get name => 'get-recording-jobs';

  @override
  void run() async {
    await initializeOnvif();

    try {
      final recordingJobs = await recordings.getRecordingJobs();

      print(recordingJobs);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// GetRecordingJobState returns the state of a recording job. It includes an
/// aggregated state, and state for each track of the recording job.
class OnvifGetRecordingJobStateRecordingsCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'get-recording-job-state returns the state of a recording job. It includes an aggregated state, and state for each track of the recording job.';

  @override
  String get name => 'get-recording-job-state';

  OnvifGetRecordingJobStateRecordingsCommand() {
    argParser.addOption(
      'job-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help: 'The token of the job to be deleted.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final recordingJobState = await recordings.getRecordingJobState(
        argResults!['job-token'],
      );

      print(recordingJobState);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Returns the capabilities of the recording service. The result is returned in
/// a typed answer.
class OnvifGetServiceCapabilitiesRecordingsCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Returns the capabilities of the recording service. The result is returned in a typed answer.';

  @override
  String get name => 'get-service-capabilities';

  @override
  void run() async {
    await initializeOnvif();

    try {
      final capabilities = await recordings.getServiceCapabilities();

      print(capabilities);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

class OnvifSetRecordingJobModeRecordingsCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'set-recording-job-mode shall change the mode of the recording job.';

  @override
  String get name => 'set-recording-job-mode';

  OnvifSetRecordingJobModeRecordingsCommand() {
    argParser
      ..addOption(
        'job-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help: 'Token of the recording job.',
      )
      ..addOption(
        'mode',
        valueHelp: 'string',
        mandatory: true,
        allowed: RecordingJobConfigurationMode.values
            .map((mode) => mode.value)
            .toList(),
        help: 'The new mode for the recording job.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await recordings.setRecordingJobMode(
        jobToken: argResults!['job-token'],
        mode: RecordingJobConfigurationMode.values.firstWhere(
          (mode) => mode.value == argResults!['mode'],
        ),
      );
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}
