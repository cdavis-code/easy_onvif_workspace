import '../settings.dart';
import '../streaming/stream_backend.dart';
import 'recording_index.dart';
import 'recording_store.dart';
import 'segment_recorder.dart';

/// A recording job binding a recording to the live stream.
class RecordingJob {
  final String jobToken;
  final String recordingToken;

  /// `Active` (capturing) or `Idle`.
  String mode;

  final int priority;

  RecordingJob({
    required this.jobToken,
    required this.recordingToken,
    required this.mode,
    this.priority = 1,
  });
}

/// The SOAP-facing recording state machine: recordings, jobs, and the
/// [SegmentRecorder]s that do the actual disk capture.
class RecordingManager {
  static const maxRecordings = 5;
  static const maxRecordingJobs = 5;

  final RecordingStore store;
  final StreamBackend backend;
  final ServerSettings settings;

  final Map<String, RecordingJob> _jobs = {};
  final Map<String, SegmentRecorder> _recorders = {};

  int _recordingCounter = 0;
  int _jobCounter = 0;

  RecordingManager({
    required this.store,
    required this.backend,
    required this.settings,
  });

  List<RecordingIndex> get recordings => store.recordings;

  List<RecordingJob> get jobs => _jobs.values.toList();

  RecordingIndex? recording(String token) => store.byToken(token);

  RecordingJob? job(String token) => _jobs[token];

  bool isRecordingActive(String recordingToken) => _jobs.values.any(
    (j) => j.recordingToken == recordingToken && j.mode == 'Active',
  );

  /// Creates a recording; throws [StateError] beyond [maxRecordings].
  Future<RecordingIndex> createRecording() async {
    if (store.recordings.length >= maxRecordings) {
      throw StateError('MaxRecordings');
    }

    // Tokens continue past any recordings reloaded from disk.
    while (store.byToken('OnvifRecordingToken_${++_recordingCounter}') !=
        null) {}

    return store.create(
      recordingToken: 'OnvifRecordingToken_$_recordingCounter',
      frameRate: 15,
      sourceToken: 'VideoSource_1',
      profileToken: 'Profile_1',
    );
  }

  Future<void> deleteRecording(String recordingToken) async {
    final jobTokens = _jobs.values
        .where((j) => j.recordingToken == recordingToken)
        .map((j) => j.jobToken)
        .toList();

    for (final token in jobTokens) {
      await deleteJob(token);
    }

    await store.delete(recordingToken);
  }

  /// Creates a job; mode `Active` starts capture immediately.
  ///
  /// Throws [ArgumentError] for an unknown recording or invalid mode, and
  /// [StateError] (`MaxRecordingJobs`, `RecordingActive`, `NoSource`) when
  /// the job cannot be created or started.
  Future<RecordingJob> createJob(String recordingToken, String mode) async {
    final index = store.byToken(recordingToken);

    if (index == null) throw ArgumentError('NoRecording');
    if (mode != 'Active' && mode != 'Idle') throw ArgumentError('InvalidMode');
    if (_jobs.length >= maxRecordingJobs) throw StateError('MaxRecordingJobs');

    final job = RecordingJob(
      jobToken: 'RecordingJobToken_${++_jobCounter}',
      recordingToken: recordingToken,
      mode: 'Idle',
    );

    _jobs[job.jobToken] = job;

    if (mode == 'Active') {
      try {
        await setJobMode(job.jobToken, 'Active');
      } catch (_) {
        // Do not leave an orphan Idle job behind when activation fails.
        _jobs.remove(job.jobToken);
        rethrow;
      }
    }

    return job;
  }

  Future<void> setJobMode(String jobToken, String mode) async {
    final job = _jobs[jobToken];

    if (job == null) throw ArgumentError('NoRecordingJob');
    if (mode != 'Active' && mode != 'Idle') throw ArgumentError('InvalidMode');
    if (job.mode == mode) return;

    if (mode == 'Active') {
      // Two recorders on one recording would clobber each other's segments.
      if (isRecordingActive(job.recordingToken)) {
        throw StateError('RecordingActive');
      }

      final source = backend.nalSource;

      if (source == null) throw StateError('NoSource');

      final recorder = SegmentRecorder(
        index: store.byToken(job.recordingToken)!,
        source: source,
        store: store,
        segmentSeconds: settings.segmentSeconds,
      );

      await recorder.start();

      _recorders[jobToken] = recorder;
    } else {
      await _recorders.remove(jobToken)?.stop();
    }

    job.mode = mode;
  }

  Future<void> deleteJob(String jobToken) async {
    await _recorders.remove(jobToken)?.stop();
    _jobs.remove(jobToken);
  }

  Future<void> dispose() async {
    for (final recorder in _recorders.values) {
      await recorder.stop();
    }

    _recorders.clear();
    _jobs.clear();
  }
}
