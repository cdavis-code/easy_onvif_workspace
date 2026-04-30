import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'time.g.dart';

@JsonSerializable()
class Time {
  @JsonKey(name: 'Hour', fromJson: OnvifUtil.intMappedFromXml)
  final int hour;

  @JsonKey(name: 'Minute', fromJson: OnvifUtil.intMappedFromXml)
  final int minute;

  @JsonKey(name: 'Second', fromJson: OnvifUtil.intMappedFromXml)
  final int second;

  Time({required this.hour, required this.minute, required this.second});

  factory Time.fromJson(Map<String, dynamic> json) => _$TimeFromJson(json);

  Map<String, dynamic> toJson() => _$TimeToJson(this);

  @override
  String toString() => json.encode(toJson());
}
