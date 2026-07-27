import 'package:easy_onvif/recordings.dart';
import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/util.dart';
import 'package:xml/xml.dart';

import 'transport.dart';
import 'xmlns.dart';

class RecordingsRequest {
  static XmlBuilder get builder => Transport.builder;

  /// XML for the [createRecording]
  static XmlDocumentFragment createRecording(
    RecordingConfiguration recordingConfiguration,
  ) {
    builder.element(
      'CreateRecording',
      nest: () {
        builder.namespaceUri(null, Xmlns.trc);

        recordingConfiguration.buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [createRecordingJob]
  static XmlDocumentFragment createRecordingJob(
    RecordingJobConfiguration recordingJobConfiguration,
  ) {
    builder.element(
      'CreateRecordingJob',
      nest: () {
        builder.namespaceUri(null, Xmlns.trc);

        recordingJobConfiguration.buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [deleteRecording]
  static XmlDocumentFragment deleteRecording(String recordingToken) {
    builder.element(
      'DeleteRecordingJob',
      nest: () {
        builder.namespaceUri(null, Xmlns.trc);

        recordingToken.buildXml(
          builder,
          tag: 'RecordingToken',
          namespace: Xmlns.tt,
        );
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [deleteRecordingJob]
  static XmlDocumentFragment deleteRecordingJob(String jobToken) {
    builder.element(
      'DeleteRecordingJob',
      nest: () {
        builder.namespaceUri(null, Xmlns.trc);

        jobToken.buildXml(builder, tag: 'JobToken', namespace: Xmlns.tt);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getRecordingJobs]
  static XmlDocumentFragment getRecordingJobs() =>
      Transport.quickTag('GetRecordingJobs', Xmlns.trc);

  /// XML for the [getRecordingJobState]
  static XmlDocumentFragment getRecordingJobState(String jobToken) {
    builder.element(
      'GetRecordingJobState',
      nest: () {
        builder.namespaceUri(null, Xmlns.trc);

        jobToken.buildXml(builder, tag: 'JobToken', namespace: Xmlns.tt);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getRecordingOptions]
  static XmlDocumentFragment getRecordingOptions(
    ReferenceToken recordingToken,
  ) {
    builder.element(
      'GetRecordingOptions',
      nest: () {
        builder.namespaceUri(null, Xmlns.trc);

        recordingToken.buildXml(
          builder,
          tag: 'RecordingToken',
          namespace: Xmlns.tt,
        );
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getRecordings]
  static XmlDocumentFragment getRecordings() =>
      Transport.quickTag('GetRecordings', Xmlns.trc);

  /// XML for the [getServiceCapabilities]
  static XmlDocumentFragment getServiceCapabilities() =>
      Transport.quickTag('GetServiceCapabilities', Xmlns.trc);

  /// XML for the [setRecordingJobMode]
  static XmlDocumentFragment setRecordingJobMode({
    required String jobToken,
    required RecordingJobConfigurationMode mode,
  }) {
    builder.element(
      'SetRecordingJobMode',
      nest: () {
        builder.namespaceUri(null, Xmlns.trc);

        jobToken.buildXml(builder, tag: 'JobToken', namespace: Xmlns.tt);

        mode.value.buildXml(builder, tag: 'Mode', namespace: Xmlns.tt);
      },
    );

    return builder.buildFragment();
  }
}
