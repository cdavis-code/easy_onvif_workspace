// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webrtc_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebrtcConfiguration _$WebrtcConfigurationFromJson(Map<String, dynamic> json) =>
    WebrtcConfiguration(
      signalingServer: OnvifUtil.stringMappedFromXml(
        json['SignalingServer'] as Map<String, dynamic>,
      ),
      authorizationServer: OnvifUtil.stringMappedFromXml(
        json['AuthorizationServer'] as Map<String, dynamic>,
      ),
      defaultProfile: OnvifUtil.stringMappedFromXml(
        json['DefaultProfile'] as Map<String, dynamic>,
      ),
      enabled: OnvifUtil.boolMappedFromXml(
        json['Enabled'] as Map<String, dynamic>,
      ),
      certPathValidationPolicyId: OnvifUtil.nullableStringMappedFromXml(
        json['CertPathValidationPolicyID'] as Map<String, dynamic>?,
      ),
      connected: OnvifUtil.nullableBoolMappedFromXml(
        json['Connected'] as Map<String, dynamic>?,
      ),
      error: OnvifUtil.nullableStringMappedFromXml(
        json['Error'] as Map<String, dynamic>?,
      ),
    );

Map<String, dynamic> _$WebrtcConfigurationToJson(
  WebrtcConfiguration instance,
) => <String, dynamic>{
  'SignalingServer': instance.signalingServer,
  'CertPathValidationPolicyID': instance.certPathValidationPolicyId,
  'AuthorizationServer': instance.authorizationServer,
  'DefaultProfile': instance.defaultProfile,
  'Enabled': instance.enabled,
  'Connected': instance.connected,
  'Error': instance.error,
};
