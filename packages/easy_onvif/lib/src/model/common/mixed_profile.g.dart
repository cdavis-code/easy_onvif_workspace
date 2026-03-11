// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mixed_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MixedProfile _$MixedProfileFromJson(Map<String, dynamic> json) => MixedProfile(
  token: json['@token'] as String,
  fixed: OnvifUtil.nullableStringToBool(json['@fixed'] as String?),
  name: OnvifUtil.stringMappedFromXml(json['Name'] as Map<String, dynamic>),
  configurations: json['Configurations'] == null
      ? null
      : ConfigurationSet.fromJson(
          json['Configurations'] as Map<String, dynamic>,
        ),
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
);

Map<String, dynamic> _$MixedProfileToJson(MixedProfile instance) =>
    <String, dynamic>{
      '@token': instance.token,
      '@fixed': instance.fixed,
      'Name': instance.name,
      'Configurations': instance.configurations,
      'VideoSourceConfiguration': instance.videoSourceConfiguration,
      'AudioSourceConfiguration': instance.audioSourceConfiguration,
      'VideoEncoderConfiguration': instance.videoEncoderConfiguration,
      'AudioEncoderConfiguration': instance.audioEncoderConfiguration,
      'VideoAnalyticsConfiguration': instance.videoAnalyticsConfiguration,
      'PTZConfiguration': instance.ptzConfiguration,
    };
