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
        builder.namespaceUri(null, Xmlns.tds);

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
        builder.namespaceUri(null, Xmlns.tds);

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
        Transport.builder.namespaceUri(null, Xmlns.tds);
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
        Transport.builder.namespaceUri(null, Xmlns.tds);

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
        Transport.builder.namespaceUri(null, Xmlns.tds);

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
        Transport.builder.namespaceUri(null, Xmlns.tds);

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
        Transport.builder.namespaceUri(null, Xmlns.tds);
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
  }) => _ipAddressFilter('SetIPAddressFilter', ipAddressFilter);

  /// XML for the [addIpAddressFilter]
  static XmlDocumentFragment addIpAddressFilter({
    required IpAddressFilter ipAddressFilter,
  }) => _ipAddressFilter('AddIPAddressFilter', ipAddressFilter);

  /// XML for the [removeIpAddressFilter]
  static XmlDocumentFragment removeIpAddressFilter({
    required IpAddressFilter ipAddressFilter,
  }) => _ipAddressFilter('RemoveIPAddressFilter', ipAddressFilter);

  static XmlDocumentFragment _ipAddressFilter(
    String operation,
    IpAddressFilter ipAddressFilter,
  ) {
    builder.element(
      operation,
      nest: () {
        builder.namespaceUri(null, Xmlns.tds);

        ipAddressFilter.buildXml(builder, tag: 'IPAddressFilter');
      },
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
        builder.namespaceUri(null, Xmlns.tds);

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
        builder.namespaceUri(null, Xmlns.tds);

        relayOutputToken.buildXml(builder, tag: 'RelayOutputToken');
        properties.buildXml(builder, tag: 'Properties');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setGeoLocation]
  static XmlDocumentFragment setGeoLocation(List<LocationEntity> locations) {
    builder.element(
      'SetGeoLocation',
      nest: () {
        builder.namespaceUri(null, Xmlns.tds);

        for (var location in locations) {
          location.buildXml(builder);
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [deleteGeoLocation]
  static XmlDocumentFragment deleteGeoLocation(List<LocationEntity> locations) {
    builder.element(
      'DeleteGeoLocation',
      nest: () {
        builder.namespaceUri(null, Xmlns.tds);

        for (var location in locations) {
          location.buildXml(builder);
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setHostname]
  static XmlDocumentFragment setHostname(String name) {
    builder.element(
      'SetHostname',
      nest: () {
        builder.namespaceUri(null, Xmlns.tds);

        name.buildXml(builder, tag: 'Name');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setHostnameFromDhcp]
  static XmlDocumentFragment setHostnameFromDhcp(bool fromDhcp) {
    builder.element(
      'SetHostnameFromDHCP',
      nest: () {
        builder.namespaceUri(null, Xmlns.tds);

        fromDhcp.toString().buildXml(builder, tag: 'FromDHCP');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setDns]
  static XmlDocumentFragment setDns(DnsInformation dnsInformation) {
    builder.element(
      'SetDNS',
      nest: () {
        builder.namespaceUri(null, Xmlns.tds);

        (dnsInformation.fromDhcp ?? false).toString().buildXml(
          builder,
          tag: 'FromDHCP',
        );

        for (var domain in dnsInformation.searchDomain ?? <String>[]) {
          domain.buildXml(builder, tag: 'SearchDomain');
        }

        for (var entry in dnsInformation.dnsManual ?? <DnsEntry>[]) {
          builder.element(
            'DNSManual',
            nest: () {
              entry.type.buildXml(builder, tag: 'Type');

              if (entry.ipv4Address != null) {
                entry.ipv4Address!.buildXml(builder, tag: 'IPv4Address');
              }

              if (entry.ipv6Address != null) {
                entry.ipv6Address!.buildXml(builder, tag: 'IPv6Address');
              }
            },
          );
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setNtp]
  static XmlDocumentFragment setNtp(NtpInformation ntpInformation) {
    builder.element(
      'SetNTP',
      nest: () {
        builder.namespaceUri(null, Xmlns.tds);

        ntpInformation.fromDhcp.toString().buildXml(builder, tag: 'FromDHCP');

        for (var ntp in ntpInformation.ntpManual ?? <Ntp>[]) {
          builder.element(
            'NTPManual',
            nest: () {
              ntp.type.buildXml(builder, tag: 'Type');

              if (ntp.iPv4Address != null) {
                ntp.iPv4Address!.buildXml(builder, tag: 'IPv4Address');
              }

              if (ntp.iPv6Address != null) {
                ntp.iPv6Address!.buildXml(builder, tag: 'IPv6Address');
              }

              if (ntp.dnsName != null) {
                ntp.dnsName!.buildXml(builder, tag: 'DNSname');
              }
            },
          );
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setDynamicDns]
  static XmlDocumentFragment setDynamicDns(
    DynamicDnsInformation dynamicDnsInformation,
  ) {
    builder.element(
      'SetDynamicDNS',
      nest: () {
        builder.namespaceUri(null, Xmlns.tds);

        dynamicDnsInformation.type.value.buildXml(builder, tag: 'Type');

        if (dynamicDnsInformation.name != null) {
          dynamicDnsInformation.name!.buildXml(builder, tag: 'Name');
        }

        if (dynamicDnsInformation.ttl != null) {
          dynamicDnsInformation.ttl!.buildXml(builder, tag: 'TTL');
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setNetworkProtocols]
  static XmlDocumentFragment setNetworkProtocols(
    List<NetworkProtocol> networkProtocols,
  ) {
    builder.element(
      'SetNetworkProtocols',
      nest: () {
        builder.namespaceUri(null, Xmlns.tds);

        for (var protocol in networkProtocols) {
          builder.element(
            'NetworkProtocols',
            nest: () {
              protocol.name.buildXml(builder, tag: 'Name');
              protocol.enabled.toString().buildXml(builder, tag: 'Enabled');
              protocol.port.toString().buildXml(builder, tag: 'Port');
            },
          );
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getNetworkDefaultGateway]
  static XmlDocumentFragment getNetworkDefaultGateway() =>
      Transport.quickTag('GetNetworkDefaultGateway', Xmlns.tds);

  /// XML for the [setNetworkDefaultGateway]
  static XmlDocumentFragment setNetworkDefaultGateway(
    NetworkGateway networkGateway,
  ) {
    builder.element(
      'SetNetworkDefaultGateway',
      nest: () {
        builder.namespaceUri(null, Xmlns.tds);

        for (var address in networkGateway.ipv4Addresses) {
          address.buildXml(builder, tag: 'IPv4Address');
        }

        for (var address in networkGateway.ipv6Addresses) {
          address.buildXml(builder, tag: 'IPv6Address');
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getZeroConfiguration]
  static XmlDocumentFragment getZeroConfiguration() =>
      Transport.quickTag('GetZeroConfiguration', Xmlns.tds);

  /// XML for the [setZeroConfiguration]
  static XmlDocumentFragment setZeroConfiguration({
    required String interfaceToken,
    required bool enabled,
  }) {
    builder.element(
      'SetZeroConfiguration',
      nest: () {
        builder.namespaceUri(null, Xmlns.tds);

        interfaceToken.buildXml(builder, tag: 'InterfaceToken');
        enabled.toString().buildXml(builder, tag: 'Enabled');
      },
    );

    return builder.buildFragment();
  }
}
