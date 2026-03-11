// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imaging_status_20.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImagingStatus20 _$ImagingStatus20FromJson(Map<String, dynamic> json) =>
    ImagingStatus20(
      focusStatus20: json['FocusStatus20'] == null
          ? null
          : FocusStatus20.fromJson(
              json['FocusStatus20'] as Map<String, dynamic>,
            ),
      extension: json['Extension'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ImagingStatus20ToJson(ImagingStatus20 instance) =>
    <String, dynamic>{
      'FocusStatus20': instance.focusStatus20,
      'Extension': instance.extension,
    };
