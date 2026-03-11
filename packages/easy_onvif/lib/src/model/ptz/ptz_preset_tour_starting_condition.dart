import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ptz_preset_tour_starting_condition.g.dart';

enum PtzPresetTourDirection {
  @JsonValue('Forward')
  forward,
  @JsonValue('Backward')
  backward,
  @JsonValue('Extended')
  extended,
}

/// Parameters to specify the detail behavior of the preset tour.
@JsonSerializable()
class PtzPresetTourStartingCondition {
  /// Execute presets in random order. If set to true and Direction is also present, Direction will be ignored and presets of the Tour will be recalled randomly.
  @JsonKey(
    name: 'RandomPresetOrder',
    fromJson: OnvifUtil.nullableBoolMappedFromXml,
  )
  final bool? randomPresetOrder;

  /// Optional parameter to specify how many times the preset tour is recurred.
  @JsonKey(name: 'RecurringTime')
  final int? recurringTime;

  /// Optional parameter to specify how long time duration the preset tour is recurred.
  @JsonKey(name: 'RecurringDuration')
  final String? recurringDuration;

  /// Optional parameter to choose which direction the preset tour goes. Forward shall be chosen in case it is omitted.
  /// - enum { 'Forward', 'Backward', 'Extended' }
  @JsonKey(name: 'Direction', fromJson: _fix)
  final PtzPresetTourDirection? direction;

  @JsonKey(name: 'Extension')
  final dynamic extension;

  PtzPresetTourStartingCondition({
    this.randomPresetOrder,
    this.recurringTime,
    this.recurringDuration,
    this.direction,
    this.extension,
  });

  factory PtzPresetTourStartingCondition.fromJson(Map<String, dynamic> json) =>
      _$PtzPresetTourStartingConditionFromJson(json);

  Map<String, dynamic> toJson() => _$PtzPresetTourStartingConditionToJson(this);

  static PtzPresetTourDirection? _fix(Map<String, dynamic>? value) =>
      value == null
      ? null
      : $enumDecode(
          _$PtzPresetTourDirectionEnumMap,
          OnvifUtil.stringMappedFromXml(value),
        );

  @override
  String toString() => jsonEncode(toJson());
}
