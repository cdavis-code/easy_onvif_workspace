// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_output_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelayOutputSettings _$RelayOutputSettingsFromJson(Map<String, dynamic> json) =>
    RelayOutputSettings(
      mode: RelayOutputSettings._modeFromXml(json['Mode']),
      idleState: RelayOutputSettings._idleStateFromXml(json['IdleState']),
      delayTime: OnvifUtil.nullableStringMappedFromXml(
        json['DelayTime'] as Map<String, dynamic>?,
      ),
    );

Map<String, dynamic> _$RelayOutputSettingsToJson(
  RelayOutputSettings instance,
) => <String, dynamic>{
  'Mode': _$RelayModeEnumMap[instance.mode]!,
  'DelayTime': instance.delayTime,
  'IdleState': _$RelayIdleStateEnumMap[instance.idleState]!,
};

const _$RelayModeEnumMap = {
  RelayMode.monostable: 'Monostable',
  RelayMode.bistable: 'Bistable',
};

const _$RelayIdleStateEnumMap = {
  RelayIdleState.closed: 'closed',
  RelayIdleState.open: 'open',
};
