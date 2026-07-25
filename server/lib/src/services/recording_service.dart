import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

import '../recording/recording_index.dart';
import '../recording/recording_manager.dart';
import '../soap/envelope_builder.dart';
import '../soap/request_context.dart';
import 'onvif_service.dart';

/// Implements the ONVIF Recording Control service (`trc` namespace).
///
/// Recording jobs capture the live stream to disk for real via the
/// [RecordingManager]; nothing here is simulated except the fixed track
/// layout (a single video track per recording).
class RecordingService implements OnvifService {
  final RecordingManager manager;

  RecordingService({required this.manager});

  @override
  bool handles(String namespace) => namespace == Xmlns.trc;

  /// `SetRecordingJobMode` is listed because the `easy_onvif` client sends it
  /// without a WS-Security header (it uses the unsecured request path).
  @override
  bool isPreAuth(String operation) =>
      operation == 'GetServiceCapabilities' ||
      operation == 'SetRecordingJobMode';

  @override
  Future<String> handle(RequestContext ctx, {required String host}) async {
    switch (ctx.operation) {
      case 'GetServiceCapabilities':
        return _getServiceCapabilities();
      case 'CreateRecording':
        return _createRecording();
      case 'DeleteRecording':
        return _deleteRecording(ctx);
      case 'GetRecordings':
        return _getRecordings();
      case 'CreateRecordingJob':
        return _createRecordingJob(ctx);
      case 'DeleteRecordingJob':
        return _deleteRecordingJob(ctx);
      case 'GetRecordingJobs':
        return _getRecordingJobs();
      case 'GetRecordingJobState':
        return _getRecordingJobState(ctx);
      case 'SetRecordingJobMode':
        return _setRecordingJobMode(ctx);
      case 'GetRecordingOptions':
        return _getRecordingOptions(ctx);
      default:
        return SoapEnvelopeBuilder.fault(
          subcode: 'ActionNotSupported',
          reason: 'The requested action is not supported by this device.',
        );
    }
  }

  // ── Responses ────────────────────────────────────────────────────────────

  String _getServiceCapabilities() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetServiceCapabilitiesResponse',
        namespace: Xmlns.trc,
        nest: () {
          b.element(
            'Capabilities',
            namespace: Xmlns.trc,
            attributes: {
              'DynamicRecordings': 'true',
              'DynamicTracks': 'false',
              'Encoding': 'H264',
              'MaxRate': '2048',
              'MaxTotalRate': '2048',
              'MaxRecordings': '${RecordingManager.maxRecordings}',
              'MaxRecordingJobs': '5',
              'Options': 'true',
              'MetadataRecording': 'false',
            },
          );
        },
      );
    });
  }

  Future<String> _createRecording() async {
    final RecordingIndex index;

    try {
      index = await manager.createRecording();
    } on StateError {
      return SoapEnvelopeBuilder.fault(
        subcode: 'MaxRecordings',
        reason: 'The maximum number of recordings has been reached.',
      );
    }

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'CreateRecordingResponse',
        namespace: Xmlns.trc,
        nest: () {
          b.element(
            'RecordingToken',
            namespace: Xmlns.trc,
            nest: index.recordingToken,
          );
        },
      );
    });
  }

  Future<String> _deleteRecording(RequestContext ctx) async {
    final token = ctx.param('RecordingToken');

    if (token == null || manager.recording(token) == null) {
      return _noRecordingFault(token);
    }

    await manager.deleteRecording(token);

    return _empty('DeleteRecordingResponse');
  }

  String _getRecordings() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetRecordingsResponse',
        namespace: Xmlns.trc,
        nest: () {
          for (final index in manager.recordings) {
            _writeRecordingItem(b, index);
          }
        },
      );
    });
  }

  /// Emits one `RecordingItem` in the shape of the ENP1A14
  /// `GetRecordingsResponse.xml` fixture (single video track).
  void _writeRecordingItem(XmlBuilder b, RecordingIndex index) {
    b.element(
      'RecordingItem',
      namespace: Xmlns.trc,
      nest: () {
        b.element(
          'RecordingToken',
          namespace: Xmlns.tt,
          nest: index.recordingToken,
        );
        b.element(
          'Configuration',
          namespace: Xmlns.tt,
          nest: () {
            b.element(
              'Source',
              namespace: Xmlns.tt,
              nest: () {
                b.element(
                  'SourceId',
                  namespace: Xmlns.tt,
                  nest: index.sourceToken,
                );
                b.element('Name', namespace: Xmlns.tt, nest: index.sourceToken);
                b.element('Location', namespace: Xmlns.tt, nest: 'Location');
                b.element(
                  'Description',
                  namespace: Xmlns.tt,
                  nest: 'Live capture',
                );
                b.element(
                  'Address',
                  namespace: Xmlns.tt,
                  nest: 'http://www.onvif.org/ver10/schema/Profile',
                );
              },
            );
            b.element('Content', namespace: Xmlns.tt, nest: 'RecordContent');
            b.element(
              'MaximumRetentionTime',
              namespace: Xmlns.tt,
              nest: 'PT0S',
            );
          },
        );
        b.element(
          'Tracks',
          namespace: Xmlns.tt,
          nest: () {
            b.element(
              'Track',
              namespace: Xmlns.tt,
              nest: () {
                b.element(
                  'TrackToken',
                  namespace: Xmlns.tt,
                  nest: 'videotracktoken_1',
                );
                b.element(
                  'Configuration',
                  namespace: Xmlns.tt,
                  nest: () {
                    b.element('TrackType', namespace: Xmlns.tt, nest: 'Video');
                    b.element(
                      'Description',
                      namespace: Xmlns.tt,
                      nest: 'VideoTrack',
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<String> _createRecordingJob(RequestContext ctx) async {
    final jobConfiguration = ctx.params('JobConfiguration').firstOrNull;
    final recordingToken = jobConfiguration == null
        ? null
        : _childText(jobConfiguration, 'RecordingToken');
    final mode = jobConfiguration == null
        ? null
        : _childText(jobConfiguration, 'Mode');

    if (recordingToken == null) {
      return SoapEnvelopeBuilder.fault(
        subcode: 'InvalidArgVal',
        reason: 'The job configuration is missing a RecordingToken.',
      );
    }

    final RecordingJob job;

    try {
      job = await manager.createJob(recordingToken, mode ?? 'Idle');
    } on ArgumentError {
      return _noRecordingFault(recordingToken);
    } on StateError {
      return SoapEnvelopeBuilder.fault(
        subcode: 'NoSource',
        reason: 'No live stream source is available to record from.',
      );
    }

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'CreateRecordingJobResponse',
        namespace: Xmlns.trc,
        nest: () {
          b.element('JobToken', namespace: Xmlns.trc, nest: job.jobToken);
          _writeJobConfiguration(b, job, 'JobConfiguration', Xmlns.trc);
        },
      );
    });
  }

  Future<String> _deleteRecordingJob(RequestContext ctx) async {
    final jobToken = ctx.param('JobToken');

    if (jobToken != null) {
      if (manager.job(jobToken) == null) return _noRecordingJobFault(jobToken);

      await manager.deleteJob(jobToken);

      return _empty('DeleteRecordingJobResponse');
    }

    // The `easy_onvif` client's `deleteRecording` sends a `DeleteRecordingJob`
    // element carrying a `RecordingToken` (client wire quirk) — honor it.
    final recordingToken = ctx.param('RecordingToken');

    if (recordingToken == null || manager.recording(recordingToken) == null) {
      return _noRecordingFault(recordingToken);
    }

    await manager.deleteRecording(recordingToken);

    return _empty('DeleteRecordingJobResponse');
  }

  String _getRecordingJobs() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetRecordingJobsResponse',
        namespace: Xmlns.trc,
        nest: () {
          for (final job in manager.jobs) {
            b.element(
              'JobItem',
              namespace: Xmlns.trc,
              nest: () {
                b.element('JobToken', namespace: Xmlns.tt, nest: job.jobToken);
                _writeJobConfiguration(
                  b,
                  job,
                  'JobConfiguration',
                  Xmlns.tt,
                );
              },
            );
          }
        },
      );
    });
  }

  String _getRecordingJobState(RequestContext ctx) {
    final jobToken = ctx.param('JobToken');
    final job = jobToken == null ? null : manager.job(jobToken);

    if (job == null) return _noRecordingJobFault(jobToken);

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetRecordingJobStateResponse',
        namespace: Xmlns.trc,
        nest: () {
          b.element(
            'State',
            namespace: Xmlns.trc,
            nest: () {
              b.element(
                'RecordingToken',
                namespace: Xmlns.tt,
                nest: job.recordingToken,
              );
              b.element('State', namespace: Xmlns.tt, nest: job.mode);
            },
          );
        },
      );
    });
  }

  Future<String> _setRecordingJobMode(RequestContext ctx) async {
    final jobToken = ctx.param('JobToken');
    final mode = ctx.param('Mode');

    if (jobToken == null || mode == null) {
      return SoapEnvelopeBuilder.fault(
        subcode: 'InvalidArgVal',
        reason: 'Both JobToken and Mode are required.',
      );
    }

    try {
      await manager.setJobMode(jobToken, mode);
    } on ArgumentError {
      return _noRecordingJobFault(jobToken);
    } on StateError {
      return SoapEnvelopeBuilder.fault(
        subcode: 'NoSource',
        reason: 'No live stream source is available to record from.',
      );
    }

    return _empty('SetRecordingJobModeResponse');
  }

  String _getRecordingOptions(RequestContext ctx) {
    final token = ctx.param('RecordingToken');

    if (token == null || manager.recording(token) == null) {
      return _noRecordingFault(token);
    }

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetRecordingOptionsResponse',
        namespace: Xmlns.trc,
        nest: () {
          b.element(
            'Options',
            namespace: Xmlns.trc,
            nest: () {
              b.element(
                'Job',
                namespace: Xmlns.tt,
                attributes: {
                  'Spare': '4',
                  'CompatibleSources': 'VideoSource_1',
                },
              );
              b.element(
                'Track',
                namespace: Xmlns.tt,
                attributes: {'SpareTotal': '0'},
              );
            },
          );
        },
      );
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _writeJobConfiguration(
    XmlBuilder b,
    RecordingJob job,
    String element,
    String namespace,
  ) {
    b.element(
      element,
      namespace: namespace,
      nest: () {
        b.element(
          'RecordingToken',
          namespace: Xmlns.tt,
          nest: job.recordingToken,
        );
        b.element('Mode', namespace: Xmlns.tt, nest: job.mode);
        b.element('Priority', namespace: Xmlns.tt, nest: '${job.priority}');
      },
    );
  }

  String _noRecordingFault(String? token) => SoapEnvelopeBuilder.fault(
    subcode: 'NoRecording',
    reason: 'No recording exists for token "$token".',
  );

  String _noRecordingJobFault(String? token) => SoapEnvelopeBuilder.fault(
    subcode: 'NoRecordingJob',
    reason: 'No recording job exists for token "$token".',
  );

  String _empty(String responseName) {
    return SoapEnvelopeBuilder.response((b) {
      b.element(responseName, namespace: Xmlns.trc, nest: () {});
    });
  }

  static String? _childText(XmlElement parent, String localName) {
    for (final child in parent.childElements) {
      if (child.localName == localName) return child.innerText.trim();
    }

    return null;
  }
}
