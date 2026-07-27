import 'dart:convert';

import 'package:easy_onvif/recordings.dart';
import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'search_scope.g.dart';

/// Scope defines the dataset to consider for this search.
@JsonSerializable()
class SearchScope implements XmlSerializable {
  /// A list of sources that are included in the scope. If this list is
  /// included, only data from one of these sources shall be searched.
  @JsonKey(name: 'IncludedSources')
  final List<SourceToken>? includedSources;

  /// A list of recordings that are included in the scope. If this list is
  /// included, only data from one of these recordings shall be searched.
  @JsonKey(name: 'IncludedRecordings')
  final List<String>? includedRecordings;

  /// An xpath expression used to specify what recordings to search. Only those
  /// recordings with an RecordingInformation structure that matches the filter
  /// shall be searched.
  @JsonKey(name: 'RecordingInformationFilter')
  final String? recordingInformationFilter;

  SearchScope({
    this.includedSources,
    this.includedRecordings,
    this.recordingInformationFilter,
  });

  factory SearchScope.fromJson(Map<String, dynamic> json) =>
      _$SearchScopeFromJson(json);

  Map<String, dynamic> toJson() => _$SearchScopeToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Scope',
    String? namespace = Xmlns.tse,
  }) => builder.element(
    tag,
    nest: () {
      builder.namespaceUri(null, namespace!);

      if (includedSources != null) {
        builder.element(
          'IncludedSources',
          nest: () {
            for (var sourceToken in includedSources!) {
              sourceToken.buildXml(builder);
            }
          },
        );
      }

      if (includedRecordings != null) {
        builder.element(
          'IncludedRecordings',
          nest: () {
            builder.text(includedRecordings!.join(','));
          },
        );
      }

      recordingInformationFilter?.buildXml(
        builder,
        tag: 'RecordingInformationFilter',
      );
    },
  );
}
