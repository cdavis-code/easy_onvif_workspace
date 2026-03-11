// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoSource _$VideoSourceFromJson(Map<String, dynamic> json) => VideoSource(
  token: json['@token'] as String,
  frameRate: OnvifUtil.stringMappedFromXml(
    json['Framerate'] as Map<String, dynamic>,
  ),
  resolution: VideoResolution.fromJson(
    json['Resolution'] as Map<String, dynamic>,
  ),
  imaging: json['Imaging'] == null
      ? null
      : Imaging.fromJson(json['Imaging'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VideoSourceToJson(VideoSource instance) =>
    <String, dynamic>{
      '@token': instance.token,
      'Framerate': instance.frameRate,
      'Resolution': instance.resolution,
      'Imaging': instance.imaging,
    };
