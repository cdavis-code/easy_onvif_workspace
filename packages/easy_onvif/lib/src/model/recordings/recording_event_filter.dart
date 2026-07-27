import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

import 'filter.dart';

part 'recording_event_filter.g.dart';

/// Optional filter defining on which event condition a recording job gets
/// active.
@JsonSerializable()
class RecordingEventFilter implements XmlSerializable {
  @JsonKey(name: 'Filter', fromJson: _fromJson)
  final List<Filter> filters;

  /// Optional time-span to record before the actual event condition became
  /// active.
  @JsonKey(name: 'Before', fromJson: OnvifUtil.nullableStringMappedFromXml)
  final String? before;

  /// Optional time-span to record after the actual event condition becomes
  /// inactive.
  @JsonKey(name: 'After', fromJson: OnvifUtil.nullableStringMappedFromXml)
  final String? after;

  RecordingEventFilter({required this.filters, this.before, this.after});

  factory RecordingEventFilter.fromJson(Map<String, dynamic> json) =>
      _$RecordingEventFilterFromJson(json);

  Map<String, dynamic> toJson() => _$RecordingEventFilterToJson(this);

  @override
  String toString() => json.encode(toJson());

  static List<Filter> _fromJson(dynamic json) => OnvifUtil.jsonList<Filter>(
    json,
    (json) => Filter.fromJson(json as Map<String, dynamic>),
  );

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'EventFilter',
    String? namespace = Xmlns.trc,
  }) => builder.element(
    tag,
    nest: () {
      builder.namespaceUri(null, namespace!);

      if (filters.isNotEmpty) {
        for (var filter in filters) {
          filter.buildXml(builder);
        }
      }
    },
  );
}
