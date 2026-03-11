// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'configuration_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigurationSet _$ConfigurationSetFromJson(Map<String, dynamic> json) =>
    ConfigurationSet(
      videoSourceConfiguration: json['VideoSourceConfiguration'] == null
          ? null
          : VideoSourceConfiguration.fromJson(
              json['VideoSourceConfiguration'] as Map<String, dynamic>,
            ),
      audioSourceConfiguration: json['AudioSourceConfiguration'] == null
          ? null
          : AudioSourceConfiguration.fromJson(
              json['AudioSourceConfiguration'] as Map<String, dynamic>,
            ),
      videoEncoderConfiguration: json['VideoEncoderConfiguration'] == null
          ? null
          : VideoEncoderConfiguration.fromJson(
              json['VideoEncoderConfiguration'] as Map<String, dynamic>,
            ),
      audioEncoderConfiguration: json['AudioEncoderConfiguration'] == null
          ? null
          : AudioEncoderConfiguration.fromJson(
              json['AudioEncoderConfiguration'] as Map<String, dynamic>,
            ),
      videoAnalyticsConfiguration: json['VideoAnalyticsConfiguration'] == null
          ? null
          : VideoAnalyticsConfiguration.fromJson(
              json['VideoAnalyticsConfiguration'] as Map<String, dynamic>,
            ),
      ptzConfiguration: json['PTZConfiguration'] == null
          ? null
          : PtzConfiguration.fromJson(
              json['PTZConfiguration'] as Map<String, dynamic>,
            ),
      metadataConfiguration: json['MetadataConfiguration'] == null
          ? null
          : MetadataConfiguration.fromJson(
              json['MetadataConfiguration'] as Map<String, dynamic>,
            ),
      extension: json['ProfileExtension'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ConfigurationSetToJson(ConfigurationSet instance) =>
    <String, dynamic>{
      'VideoSourceConfiguration': instance.videoSourceConfiguration,
      'AudioSourceConfiguration': instance.audioSourceConfiguration,
      'VideoEncoderConfiguration': instance.videoEncoderConfiguration,
      'AudioEncoderConfiguration': instance.audioEncoderConfiguration,
      'VideoAnalyticsConfiguration': instance.videoAnalyticsConfiguration,
      'PTZConfiguration': instance.ptzConfiguration,
      'MetadataConfiguration': instance.metadataConfiguration,
      'ProfileExtension': instance.extension,
    };
