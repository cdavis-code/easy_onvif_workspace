import 'package:easy_onvif/device_management.dart';
import 'package:easy_onvif/util.dart';
import 'package:xml/xml.dart';

import 'transport.dart';
import 'xmlns.dart';

class DeviceManagementRequest {
  static XmlBuilder get builder => Transport.builder;

  /// XML for the [createUsers]
  static XmlDocumentFragment createUsers(List<User> users) {
    builder.element(
      'CreateUsers',
      nest: () {
        builder.namespace(Xmlns.tds);

        for (var user in users) {
          user.buildXml(builder);
        }
      },
    );

    return Transport.builder.buildFragment();
  }

  /// XML for the [deleteUsers]
  static XmlDocumentFragment deleteUsers(List<String> userNames) {
    builder.element(
      'DeleteUsers',
      nest: () {
        builder.namespace(Xmlns.tds);

        for (var userName in userNames) {
          userName.buildXml(builder, tag: 'Username');
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getDynamicDns]
  static XmlDocumentFragment getDynamicDns() =>
      Transport.quickTag('GetDynamicDNS', Xmlns.tds);

  /// XML for the [getSystemDateAndTime]
  static XmlDocumentFragment getSystemDateAndTime() =>
      Transport.quickTag('GetSystemDateAndTime', Xmlns.tds);

  ///XML for the [capabilities]
  static XmlDocumentFragment capabilities(String category) {
    Transport.builder.element(
      'GetCapabilities',
      nest: () {
        Transport.builder.namespace(Xmlns.tds);
        Transport.builder.element(
          'Category',
          nest: () {
            Transport.builder.text(category);
          },
        );
      },
    );

    return Transport.builder.buildFragment();
  }

  /// XML for the [getServices]
  static XmlDocumentFragment getServices([bool includeCapability = false]) {
    Transport.builder.element(
      'GetServices',
      nest: () {
        Transport.builder.namespace(Xmlns.tds);

        Transport.builder.element(
          'IncludeCapability',
          nest: () {
            Transport.builder.text(includeCapability ? 'true' : false);
          },
        );
      },
    );

    return Transport.builder.buildFragment();
  }

  /// XML for the [getStorageConfiguration]
  static XmlDocumentFragment getStorageConfiguration(String referenceToken) {
    Transport.builder.element(
      'GetStorageConfiguration',
      nest: () {
        Transport.builder.namespace(Xmlns.tds);

        referenceToken.buildXml(builder, tag: 'Token');
      },
    );

    return Transport.builder.buildFragment();
  }

  /// XML for the [getStorageConfigurations]
  static XmlDocumentFragment getStorageConfigurations() =>
      Transport.quickTag('GetStorageConfigurations', Xmlns.tds);

  /// XML for the [getSystemLog]
  static XmlDocumentFragment getSystemLog(String logType) {
    Transport.builder.element(
      'GetSystemLog',
      nest: () {
        Transport.builder.namespace(Xmlns.tds);

        logType.buildXml(builder, tag: 'LogType', namespace: Xmlns.tds);
      },
    );

    return Transport.builder.buildFragment();
  }

  /// XML for the [getSystemSupportInformation]
  static XmlDocumentFragment getSystemSupportInformation() {
    Transport.builder.element(
      'GetSystemSupportInformation',
      nest: () {
        Transport.builder.namespace(Xmlns.tds);
      },
    );

    return Transport.builder.buildFragment();
  }

  /// XML for the [getDeviceInformation]
  static XmlDocumentFragment getDeviceInformation() =>
      Transport.quickTag('GetDeviceInformation', Xmlns.tds);

  /// XML for the [getEndpointReference]
  static XmlDocumentFragment getEndpointReference() =>
      Transport.quickTag('GetEndpointReference', Xmlns.tds);

  /// XML for the [getHostname]
  static XmlDocumentFragment getHostname() =>
      Transport.quickTag('GetHostname', Xmlns.tds);

  /// XML for the [getIPAddressFilter]
  static XmlDocumentFragment getIPAddressFilter() =>
      Transport.quickTag('GetIPAddressFilter', Xmlns.tds);

  /// XML for the [getServiceCapabilities]
  static XmlDocumentFragment getServiceCapabilities() =>
      Transport.quickTag('GetServiceCapabilities', Xmlns.tds);

  /// XML for the [getNetworkProtocols]
  static XmlDocumentFragment getNetworkProtocols() =>
      Transport.quickTag('GetNetworkProtocols', Xmlns.tds);

  /// XML for the [systemReboot]
  static XmlDocumentFragment systemReboot() =>
      Transport.quickTag('SystemReboot', Xmlns.tds);

  /// XML for the [getSystemUris]
  static XmlDocumentFragment getSystemUris() =>
      Transport.quickTag('GetSystemUris', Xmlns.tds);

  /// XML for the [getUsers]
  static XmlDocumentFragment getUsers() =>
      Transport.quickTag('GetUsers', Xmlns.tds);

  /// XML for the [getDiscoveryMode]
  static XmlDocumentFragment getDiscoveryMode() =>
      Transport.quickTag('GetDiscoveryMode', Xmlns.tds);

  /// XML for the [getDns]
  static XmlDocumentFragment getDns() =>
      Transport.quickTag('GetDNS', Xmlns.tds);

  /// XML for the [getNtp]
  static XmlDocumentFragment getNtp() =>
      Transport.quickTag('GetNTP', Xmlns.tds);

  /// XML for the [getGeoLocation]
  static XmlDocumentFragment getGeoLocation() =>
      Transport.quickTag('GetGeoLocation', Xmlns.tds);

  /// XML for the [setIpAddressFilter]
  static XmlDocumentFragment setIpAddressFilter({
    required IpAddressFilter ipAddressFilter,
  }) {
    builder.element(
      'SetIPAddressFilter',
      namespace: Xmlns.trc,
      nest: () => ipAddressFilter.buildXml(
        builder,
        tag: 'IPAddressFilter',
        namespace: Xmlns.tds,
      ),
    );

    return builder.buildFragment();
  }

  /// XML for the [getRelayOutputs]
  static XmlDocumentFragment getRelayOutputs() =>
      Transport.quickTag('GetRelayOutputs', Xmlns.tds);

  /// XML for the [setRelayOutputState]
  static XmlDocumentFragment setRelayOutputState({
    required String relayOutputToken,
    required RelayLogicalState logicalState,
  }) {
    builder.element(
      'SetRelayOutputState',
      nest: () {
        builder.namespace(Xmlns.tds);

        relayOutputToken.buildXml(builder, tag: 'RelayOutputToken');
        logicalState.value.buildXml(builder, tag: 'LogicalState');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setRelayOutputSettings]
  static XmlDocumentFragment setRelayOutputSettings({
    required String relayOutputToken,
    required RelayOutputSettings properties,
  }) {
    builder.element(
      'SetRelayOutputSettings',
      nest: () {
        builder.namespace(Xmlns.tds);

        relayOutputToken.buildXml(builder, tag: 'RelayOutputToken');
        properties.buildXml(builder, tag: 'Properties');
      },
    );

    return builder.buildFragment();
  }
}
