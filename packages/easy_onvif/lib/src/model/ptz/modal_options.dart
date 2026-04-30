import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'modal_options.g.dart';

/// Supported options for PTZ Direction Control.
@JsonSerializable()
class ModalOptions {
  /// Options of EFlip mode parameter.
  /// - enum { 'OFF', 'ON', 'Extended' }
  @JsonKey(name: 'Mode', fromJson: _oneOrMore)
  final List<String>? mode;

  ModalOptions({this.mode});

  factory ModalOptions.fromJson(Map<String, dynamic> json) =>
      _$ModalOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$ModalOptionsToJson(this);

  @override
  String toString() => jsonEncode(toJson());

  static List<String>? _oneOrMore(dynamic json) {
    if (json == null) {
      return [];
    }

    if (json is List) {
      // json from XML
      return OnvifUtil.nullableStringMappedFromXmlList(json);
    } else {
      // json from serialized object
      return [OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>)];
    }
  }
}
