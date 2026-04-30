import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

import 'recording_information.dart';

part 'find_recording_result.g.dart';

@JsonSerializable()
class FindRecordingResult {
  @JsonKey(name: 'SearchState', fromJson: _searchState)
  final SearchState searchState;

  @JsonKey(name: 'RecordingInformation', fromJson: _fromJson)
  final List<RecordingInformation>? recordingInformation;

  FindRecordingResult({required this.searchState, this.recordingInformation});

  factory FindRecordingResult.fromJson(Map<String, dynamic> json) =>
      _$FindRecordingResultFromJson(json);

  Map<String, dynamic> toJson() => _$FindRecordingResultToJson(this);

  @override
  String toString() => json.encode(toJson());

  static SearchState _searchState(dynamic json) => $enumDecode(
    _$SearchStateEnumMap,
    OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>),
  );

  static List<RecordingInformation> _fromJson(dynamic json) =>
      OnvifUtil.jsonList<RecordingInformation>(
        json,
        (json) => RecordingInformation.fromJson(json as Map<String, dynamic>),
      );
}

enum SearchState {
  @JsonValue('Queued')
  queued('Queued'),
  @JsonValue('Searching')
  searching('Searching'),
  @JsonValue('Completed')
  completed('Completed'),
  @JsonValue('Unknown')
  unknown('Unknown');

  const SearchState(this.value);

  final String value;
}
