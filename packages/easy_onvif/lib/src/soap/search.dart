import 'package:easy_onvif/search.dart' show SearchScope;
import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/src/util/extra.dart';
import 'package:xml/xml.dart';

import 'transport.dart';
import 'xmlns.dart';

class SearchRequest {
  static XmlBuilder get builder => Transport.builder;

  /// XML for the [findRecordings]
  static XmlDocumentFragment findRecordings({
    SearchScope? searchScope,
    int? maxMatches,
    required int keepAliveTime,
  }) {
    builder.element(
      'FindRecordings',
      nest: () {
        builder.namespaceUri(null, Xmlns.tse);

        searchScope?.buildXml(builder);

        maxMatches?.toString().buildXml(builder, tag: 'MaxMatches');

        keepAliveTime.toString().buildXml(builder, tag: 'KeepAliveTime');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getRecordingSummary]
  static XmlDocumentFragment getRecordingSummary() =>
      Transport.quickTag('GetRecordingSummary', Xmlns.tse);

  /// XML for the [getRecordingInformation]
  static XmlDocumentFragment getRecordingInformation(String recordingToken) {
    builder.element(
      'GetRecordingInformation',
      nest: () {
        builder.namespaceUri(null, Xmlns.tse);

        ReferenceToken(recordingToken).buildXml(builder, tag: 'RecordingToken');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getRecordingSearchResults]
  static XmlDocumentFragment getRecordingSearchResults(
    String searchToken, {
    int? minResults,
    int? maxResults,
    String? waitTime,
  }) {
    builder.element(
      'GetRecordingSearchResults',
      nest: () {
        builder.namespaceUri(null, Xmlns.tse);

        ReferenceToken(searchToken).buildXml(builder, tag: 'SearchToken');

        minResults?.toString().buildXml(builder, tag: 'MinResults');

        maxResults?.toString().buildXml(builder, tag: 'MaxResults');

        waitTime?.buildXml(builder, tag: 'WaitTime');
      },
    );

    return builder.buildFragment();
  }
}
