// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_video_encoder_configurations_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetVideoEncoderConfigurationsResponse
_$GetVideoEncoderConfigurationsResponseFromJson(Map<String, dynamic> json) =>
    GetVideoEncoderConfigurationsResponse(
      configurations: (json['Configurations'] as List<dynamic>)
          .map(
            (e) =>
                VideoEncoder2Configuration.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$GetVideoEncoderConfigurationsResponseToJson(
  GetVideoEncoderConfigurationsResponse instance,
) => <String, dynamic>{'Configurations': instance.configurations};
