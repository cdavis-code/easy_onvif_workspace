import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

import '../recording/recording_index.dart';
import '../recording/recording_manager.dart';
import '../soap/envelope_builder.dart';
import '../soap/request_context.dart';
import 'onvif_service.dart';

/// Implements the ONVIF Recording Search service (`tse` namespace).
///
/// Searches complete immediately over the real on-disk recording indexes, so
/// every reported time range reflects actual captured footage.
class SearchService implements OnvifService {
  final RecordingManager manager;

  int _searchCounter = 0;

  /// Search token → snapshot of recording tokens taken at FindRecordings
  /// time (searches complete synchronously).
  final Map<String, List<String>> _searches = {};

  SearchService({required this.manager});

  @override
  bool handles(String namespace) => namespace == Xmlns.tse;

  @override
  bool isPreAuth(String operation) => operation == 'GetServiceCapabilities';

  @override
  Future<String> handle(RequestContext ctx, {required String host}) async {
    switch (ctx.operation) {
      case 'GetServiceCapabilities':
        return _getServiceCapabilities();
      case 'FindRecordings':
        return _findRecordings();
      case 'GetRecordingSearchResults':
        return _getRecordingSearchResults(ctx);
      case 'GetRecordingInformation':
        return _getRecordingInformation(ctx);
      case 'GetRecordingSummary':
        return _getRecordingSummary();
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
        namespace: Xmlns.tse,
        nest: () {
          b.element(
            'Capabilities',
            namespace: Xmlns.tse,
            attributes: {
              'MetadataSearch': 'false',
              'GeneralStartEvents': 'false',
            },
          );
        },
      );
    });
  }

  String _findRecordings() {
    final token = 'RecordingSearchToken_${++_searchCounter}';

    _searches[token] = [
      for (final index in manager.recordings) index.recordingToken,
    ];

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'FindRecordingsResponse',
        namespace: Xmlns.tse,
        nest: () {
          b.element('SearchToken', namespace: Xmlns.tse, nest: token);
        },
      );
    });
  }

  String _getRecordingSearchResults(RequestContext ctx) {
    final searchToken = ctx.param('SearchToken');
    final tokens = searchToken == null ? null : _searches[searchToken];

    if (tokens == null) {
      return SoapEnvelopeBuilder.fault(
        subcode: 'InvalidToken',
        reason: 'No search session exists for token "$searchToken".',
      );
    }

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetRecordingSearchResultsResponse',
        namespace: Xmlns.tse,
        nest: () {
          b.element(
            'ResultList',
            namespace: Xmlns.tse,
            nest: () {
              b.element('SearchState', namespace: Xmlns.tt, nest: 'Completed');

              for (final token in tokens) {
                final index = manager.recording(token);

                if (index == null) continue;

                b.element(
                  'RecordingInformation',
                  namespace: Xmlns.tt,
                  nest: () => _writeRecordingInformation(b, index),
                );
              }
            },
          );
        },
      );
    });
  }

  String _getRecordingInformation(RequestContext ctx) {
    final token = ctx.param('RecordingToken');
    final index = token == null ? null : manager.recording(token);

    if (index == null) {
      return SoapEnvelopeBuilder.fault(
        subcode: 'NoRecording',
        reason: 'No recording exists for token "$token".',
      );
    }

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetRecordingInformationResponse',
        namespace: Xmlns.tse,
        nest: () {
          b.element(
            'RecordingInformation',
            namespace: Xmlns.tse,
            nest: () => _writeRecordingInformation(b, index),
          );
        },
      );
    });
  }

  String _getRecordingSummary() {
    final recordings = manager.recordings;
    final now = DateTime.now().toUtc();

    DateTime? from;
    DateTime? until;

    for (final index in recordings) {
      final earliest = index.earliestUtc;
      final latest = index.latestUtc;

      if (earliest != null && (from == null || earliest.isBefore(from))) {
        from = earliest;
      }

      if (latest != null && (until == null || latest.isAfter(until))) {
        until = latest;
      }
    }

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetRecordingSummaryResponse',
        namespace: Xmlns.tse,
        nest: () {
          b.element(
            'Summary',
            namespace: Xmlns.tse,
            nest: () {
              b.element(
                'DataFrom',
                namespace: Xmlns.tt,
                nest: (from ?? now).toIso8601String(),
              );
              b.element(
                'DataUntil',
                namespace: Xmlns.tt,
                nest: (until ?? now).toIso8601String(),
              );
              b.element(
                'NumberRecordings',
                namespace: Xmlns.tt,
                nest: '${recordings.length}',
              );
            },
          );
        },
      );
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Writes the recording-information body (all `tt` children) from the real
  /// on-disk index: earliest/latest bounds come from the recorded segments.
  void _writeRecordingInformation(XmlBuilder b, RecordingIndex index) {
    final earliest = index.earliestUtc;
    final latest = index.latestUtc;

    b.element(
      'RecordingToken',
      namespace: Xmlns.tt,
      nest: index.recordingToken,
    );
    b.element(
      'Source',
      namespace: Xmlns.tt,
      nest: () {
        b.element('SourceId', namespace: Xmlns.tt, nest: index.sourceToken);
        b.element('Name', namespace: Xmlns.tt, nest: index.sourceToken);
        b.element('Location', namespace: Xmlns.tt, nest: 'Location');
        b.element('Description', namespace: Xmlns.tt, nest: 'Live capture');
        b.element(
          'Address',
          namespace: Xmlns.tt,
          nest: 'http://www.onvif.org/ver10/schema/Profile',
        );
      },
    );

    if (earliest != null) {
      b.element(
        'EarliestRecording',
        namespace: Xmlns.tt,
        nest: earliest.toIso8601String(),
      );
    }

    if (latest != null) {
      b.element(
        'LatestRecording',
        namespace: Xmlns.tt,
        nest: latest.toIso8601String(),
      );
    }

    b.element('Content', namespace: Xmlns.tt, nest: 'RecordContent');

    if (earliest != null && latest != null) {
      // The client parses `Track` directly as a TrackInformation structure.
      b.element(
        'Track',
        namespace: Xmlns.tt,
        nest: () {
          b.element(
            'TrackToken',
            namespace: Xmlns.tt,
            nest: 'videotracktoken_1',
          );
          b.element('TrackType', namespace: Xmlns.tt, nest: 'Video');
          b.element('Description', namespace: Xmlns.tt, nest: 'VideoTrack');
          b.element(
            'DataFrom',
            namespace: Xmlns.tt,
            nest: earliest.toIso8601String(),
          );
          b.element(
            'DataTo',
            namespace: Xmlns.tt,
            nest: latest.toIso8601String(),
          );
        },
      );
    }

    b.element(
      'RecordingStatus',
      namespace: Xmlns.tt,
      nest: manager.isRecordingActive(index.recordingToken)
          ? 'Recording'
          : 'Stopped',
    );
  }
}
