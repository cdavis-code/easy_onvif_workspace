// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecurityCapabilities _$SecurityCapabilitiesFromJson(
  Map<String, dynamic> json,
) => SecurityCapabilities(
  tls1_0: json['TLS1.0'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['TLS1.0']),
  tls1_1: json['TLS1.1'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['TLS1.1']),
  tls1_2: json['TLS1.2'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['TLS1.2']),
  onboardKeyGeneration: json['OnboardKeyGeneration'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['OnboardKeyGeneration']),
  accessPolicyConfig: json['AccessPolicyConfig'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['AccessPolicyConfig']),
  defaultAccessPolicy: json['DefaultAccessPolicy'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['DefaultAccessPolicy']),
  dot1x: json['Dot1X'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['Dot1X']),
  remoteUserHandling: json['RemoteUserHandling'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['RemoteUserHandling']),
  x509Token: json['X.509Token'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['X.509Token']),
  samlToken: json['SAMLToken'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['SAMLToken']),
  kerberosToken: json['KerberosToken'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['KerberosToken']),
  relToken: json['RELToken'] == null
      ? false
      : OnvifUtil.stringOrMappedToBool(json['RELToken']),
  extension: json['Extension'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SecurityCapabilitiesToJson(
  SecurityCapabilities instance,
) => <String, dynamic>{
  'TLS1.0': instance.tls1_0,
  'TLS1.1': instance.tls1_1,
  'TLS1.2': instance.tls1_2,
  'OnboardKeyGeneration': instance.onboardKeyGeneration,
  'AccessPolicyConfig': instance.accessPolicyConfig,
  'DefaultAccessPolicy': instance.defaultAccessPolicy,
  'Dot1X': instance.dot1x,
  'RemoteUserHandling': instance.remoteUserHandling,
  'X.509Token': instance.x509Token,
  'SAMLToken': instance.samlToken,
  'KerberosToken': instance.kerberosToken,
  'RELToken': instance.relToken,
  'Extension': instance.extension,
};
