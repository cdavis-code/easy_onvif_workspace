import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'webrtc_configuration.g.dart';

/// WebRTC signaling configuration (tr2:WebRTCConfiguration).
///
/// Describes the signaling server a device uses for WebRTC streaming. The
/// `easy_onvif_server` reflects its own built-in `/onvif/webrtc` endpoint here.
@JsonSerializable()
class WebrtcConfiguration implements XmlSerializable {
  /// The signaling server URI.
  @JsonKey(name: 'SignalingServer', fromJson: OnvifUtil.stringMappedFromXml)
  final String signalingServer;

  /// Identifier of the policy used to validate the signaling server
  /// certificate (optional).
  @JsonKey(
    name: 'CertPathValidationPolicyID',
    fromJson: OnvifUtil.nullableStringMappedFromXml,
  )
  final String? certPathValidationPolicyId;

  /// The Authorization Server used for obtaining access tokens.
  @JsonKey(name: 'AuthorizationServer', fromJson: OnvifUtil.stringMappedFromXml)
  final String authorizationServer;

  /// The default media profile used for streaming.
  @JsonKey(name: 'DefaultProfile', fromJson: OnvifUtil.stringMappedFromXml)
  final String defaultProfile;

  /// Enables/disables the configuration.
  @JsonKey(name: 'Enabled', fromJson: OnvifUtil.boolMappedFromXml)
  final bool enabled;

  /// Whether the device is connected to the signaling server (read-only).
  @JsonKey(name: 'Connected', fromJson: OnvifUtil.nullableBoolMappedFromXml)
  final bool? connected;

  /// Optional user readable error information (read-only).
  @JsonKey(name: 'Error', fromJson: OnvifUtil.nullableStringMappedFromXml)
  final String? error;

  WebrtcConfiguration({
    required this.signalingServer,
    required this.authorizationServer,
    required this.defaultProfile,
    required this.enabled,
    this.certPathValidationPolicyId,
    this.connected,
    this.error,
  });

  factory WebrtcConfiguration.fromJson(Map<String, dynamic> json) =>
      _$WebrtcConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$WebrtcConfigurationToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'WebRTCConfiguration',
    String? namespace = Xmlns.tr2,
  }) => builder.element(
    tag,
    nest: () {
      if (namespace != null) builder.namespaceUri(null, namespace);

      signalingServer.buildXml(builder, tag: 'SignalingServer');

      if (certPathValidationPolicyId != null) {
        certPathValidationPolicyId!.buildXml(
          builder,
          tag: 'CertPathValidationPolicyID',
        );
      }

      authorizationServer.buildXml(builder, tag: 'AuthorizationServer');
      defaultProfile.buildXml(builder, tag: 'DefaultProfile');
      enabled.toString().buildXml(builder, tag: 'Enabled');
    },
  );
}
