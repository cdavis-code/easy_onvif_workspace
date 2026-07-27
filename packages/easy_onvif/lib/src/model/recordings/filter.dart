import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'filter.g.dart';

/// Optional filter defining on which event condition a recording job gets
/// active.
@JsonSerializable()
class Filter implements XmlSerializable {
  /// Topic filter as defined in section 9.6.3 of the ONVIF Core Specification.
  @JsonKey(name: 'Topic', fromJson: OnvifUtil.stringMappedFromXml)
  final String topic;

  /// Optional message source content filter as defined in section 9.4.4 of the
  /// ONVIF Core Specification.
  @JsonKey(name: 'Source', fromJson: OnvifUtil.stringMappedFromXml)
  final String? source;

  Filter({required this.topic, this.source});

  factory Filter.fromJson(Map<String, dynamic> json) => _$FilterFromJson(json);

  Map<String, dynamic> toJson() => _$FilterToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Filter',
    String? namespace = Xmlns.tt,
  }) => builder.element(
    tag,
    nest: () {
      builder.namespaceUri(null, namespace!);

      topic.buildXml(builder, tag: 'Topic', namespace: Xmlns.tt);

      source?.buildXml(builder, tag: 'Source', namespace: Xmlns.tt);
    },
  );
}
