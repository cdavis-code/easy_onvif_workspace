// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_time_streaming_capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RealTimeStreamingCapabilities _$RealTimeStreamingCapabilitiesFromJson(
  Map<String, dynamic> json,
) => RealTimeStreamingCapabilities(
  rtpMulticast: OnvifUtil.nullableBoolMappedFromXml(
    json['RTPMulticast'] as Map<String, dynamic>?,
  ),
  rtp_tcp: OnvifUtil.nullableBoolMappedFromXml(
    json['RTP_TCP'] as Map<String, dynamic>?,
  ),
  rtp_rtsp_tcp: OnvifUtil.nullableBoolMappedFromXml(
    json['RTP_RTSP_TCP'] as Map<String, dynamic>?,
  ),
  extension: json['extension'] == null
      ? null
      : MediaCapabilitiesExtension.fromJson(
          json['extension'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$RealTimeStreamingCapabilitiesToJson(
  RealTimeStreamingCapabilities instance,
) => <String, dynamic>{
  'RTPMulticast': instance.rtpMulticast,
  'RTP_TCP': instance.rtp_tcp,
  'RTP_RTSP_TCP': instance.rtp_rtsp_tcp,
  'extension': instance.extension,
};
