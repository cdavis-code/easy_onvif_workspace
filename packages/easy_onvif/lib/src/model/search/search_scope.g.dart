// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_scope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchScope _$SearchScopeFromJson(Map<String, dynamic> json) => SearchScope(
  includedSources: (json['IncludedSources'] as List<dynamic>?)
      ?.map((e) => SourceToken.fromJson(e as Map<String, dynamic>))
      .toList(),
  includedRecordings: (json['IncludedRecordings'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  recordingInformationFilter: json['RecordingInformationFilter'] as String?,
);

Map<String, dynamic> _$SearchScopeToJson(SearchScope instance) =>
    <String, dynamic>{
      'IncludedSources': instance.includedSources,
      'IncludedRecordings': instance.includedRecordings,
      'RecordingInformationFilter': instance.recordingInformationFilter,
    };
