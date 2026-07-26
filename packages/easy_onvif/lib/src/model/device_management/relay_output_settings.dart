import 'dart:convert';

import 'package:easy_onvif/src/model/common/xml_serializable.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'relay_output_settings.g.dart';

/// Relay operating mode (tt:RelayMode): 'Monostable' or 'Bistable'.
enum RelayMode {
  @JsonValue('Monostable')
  monostable('Monostable'),
  @JsonValue('Bistable')
  bistable('Bistable');

  final String value;
  const RelayMode(this.value);
}

/// Relay idle state (tt:RelayIdleState): 'closed' or 'open'.
enum RelayIdleState {
  @JsonValue('closed')
  closed('closed'),
  @JsonValue('open')
  open('open');

  final String value;
  const RelayIdleState(this.value);
}

/// Relay logical state (tt:RelayLogicalState) for SetRelayOutputState:
/// 'active' or 'inactive'.
enum RelayLogicalState {
  @JsonValue('active')
  active('active'),
  @JsonValue('inactive')
  inactive('inactive');

  final String value;
  const RelayLogicalState(this.value);
}

/// Settings for a relay output (tt:RelayOutputSettings).
@JsonSerializable()
class RelayOutputSettings implements XmlSerializable {
  @JsonKey(name: 'Mode', fromJson: _modeFromXml)
  final RelayMode mode;

  /// Time after which the relay returns to its idle state (monostable mode);
  /// an xs:duration string such as `PT1S`.
  @JsonKey(name: 'DelayTime', fromJson: OnvifUtil.nullableStringMappedFromXml)
  final String? delayTime;

  @JsonKey(name: 'IdleState', fromJson: _idleStateFromXml)
  final RelayIdleState idleState;

  RelayOutputSettings({
    required this.mode,
    required this.idleState,
    this.delayTime,
  });

  factory RelayOutputSettings.fromJson(Map<String, dynamic> json) =>
      _$RelayOutputSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$RelayOutputSettingsToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Properties',
    String? namespace,
  }) => builder.element(
    tag,
    nest: () {
      if (namespace != null) builder.namespace(namespace);

      mode.value.buildXml(builder, tag: 'Mode');
      (delayTime ?? 'PT0S').buildXml(builder, tag: 'DelayTime');
      idleState.value.buildXml(builder, tag: 'IdleState');
    },
  );

  static RelayMode _modeFromXml(dynamic value) => RelayMode.values.firstWhere(
    (e) =>
        e.value == OnvifUtil.stringMappedFromXml(value as Map<String, dynamic>),
  );

  static RelayIdleState _idleStateFromXml(dynamic value) =>
      RelayIdleState.values.firstWhere(
        (e) =>
            e.value ==
            OnvifUtil.stringMappedFromXml(value as Map<String, dynamic>),
      );
}
