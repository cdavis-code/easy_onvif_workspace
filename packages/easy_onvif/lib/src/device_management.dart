import 'dart:async';
import 'dart:convert';

import 'package:easy_onvif/device_management.dart';
import 'package:easy_onvif/soap.dart' as soap;
import 'package:easy_onvif/soap.dart' show Envelope;
import 'package:loggy/loggy.dart';

import 'operation.dart';

typedef DeviceManagementRequest = soap.DeviceManagementRequest;

/// Device management functions are handled through the device service. The
/// device service is the entry point to all other services provided by a
/// device.
///
/// Default Access Policy Definition
/// | | Administrator | Operator | User | Anonymous |
/// | PRE_AUTH | X | X | X | X |
/// | READ_SYSTEM | X | X | X | |
/// | READ_SYSTEM_SENSITIVE | X | X | | |
/// | READ_SYSTEM_SECRET | X | | | |
/// | WRITE_SYSTEM | X | | | |
/// | UNRECOVERABLE | X | | | |
/// | READ_MEDIA | X | X | X | |
/// | ACTUATE | X | X | | |
class DeviceManagement extends Operation with UiLoggy {
  DeviceManagement({required super.transport, required super.uri});

  Function get requestFunction => transport.overrideSpecificationAuthentication
      ? transport.securedRequest
      : transport.request;

  /// This operation creates new device users and corresponding credentials on a
  /// device for authentication purposes. The device shall support creation of
  /// device users and their credentials through the CreateUsers command. Either
  /// all users are created successfully or a fault message shall be returned
  /// without creating any user.
  ///
  /// ONVIF compliant devices are recommended to support password length of at
  /// least 28 bytes, as clients may follow the password derivation mechanism
  /// which results in 'password equivalent' of length 28 bytes, as described in
  /// section 3.1.2 of the ONVIF security white paper.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> createUsers(List<User> users) async {
    loggy.debug('createUsers');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.createUsers(users)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation deletes users on a device. The device shall support deletion
  /// of device users and their credentials through the DeleteUsers command. A
  /// device may have one or more fixed users that cannot be deleted to ensure
  /// access to the unit. Either all users are deleted successfully or a fault
  /// message shall be returned and no users be deleted.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> deleteUsers(List<String> users) async {
    loggy.debug('deleteUsers');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.deleteUsers(users)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation creates new device users and corresponding credentials on a
  /// device for authentication purposes. The device shall support creation of
  /// device users and their credentials through the CreateUsers command. Either
  /// all users are created successfully or a fault message shall be returned
  /// without creating any user.
  ///
  /// ONVIF compliant devices are recommended to support password length of at
  /// least 28 bytes, as clients may follow the password derivation mechanism
  /// which results in 'password equivalent' of length 28 bytes, as described in
  /// section 3.1.2 of the ONVIF security white paper.
  ///
  /// This method has been replaced by the more generic [getServices] method.
  /// For capabilities of individual services refer to the
  /// [getServiceCapabilities] methods.
  ///  @Deprecated('Use [getServices]')
  ///
  /// Access Class: PRE_AUTH
  Future<Capabilities> getCapabilities({
    CapabilityCategory capabilityCategory = CapabilityCategory.all,
  }) async {
    loggy.debug('getCapabilities');

    final responseEnvelope =
        await requestFunction(
              uri,
              soap.Body(
                request: DeviceManagementRequest.capabilities(
                  capabilityCategory.value,
                ),
              ),
            )
            as Envelope;

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetCapabilitiesResponse.fromJson(
      responseEnvelope.body.response!,
    ).capabilities;
  }

  /// This operation gets the dynamic DNS settings from a device. If the device
  /// supports dynamic DNS as specified in [RFC 2136\] and [RFC 4702\], it shall
  /// be possible to get the type, name and TTL through the GetDynamicDNS
  /// command.
  ///
  /// ACCESS CLASS: READ_SYSTEM
  Future<DynamicDnsInformation> getDynamicDns() async {
    loggy.debug('getDynamicDNS');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getDynamicDns()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetDynamicDnsResponse.fromJson(
      responseEnvelope.body.response!,
    ).dynamicDnsInformation;
  }

  /// This operation gets basic device information from the device.
  ///
  /// Access Class: READ_SYSTEM
  Future<GetDeviceInformationResponse> getDeviceInformation() async {
    loggy.debug('getDeviceInformation');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getDeviceInformation()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetDeviceInformationResponse.fromJson(
      responseEnvelope.body.response!,
    );
  }

  /// This operation gets the discovery mode of a device. See Section 7.2 for
  /// the definition of the different device discovery modes. The device shall
  /// support retrieval of the discovery mode setting through the
  /// GetDiscoveryMode command.
  ///
  /// Access Class: READ_SYSTEM
  Future<String> getDiscoveryMode() async {
    loggy.debug('getDiscoveryMode');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getDiscoveryMode()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetDiscoveryModeResponse.fromJson(
      responseEnvelope.body.response!,
    ).discoveryMode;
  }

  /// This operation gets the DNS settings from a device. The device shall
  /// return its DNS configurations through the GetDNS command.
  ///
  /// Access Class: READ_SYSTEM
  Future<DnsInformation> getDns() async {
    loggy.debug('getDns');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getDns()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetDnsResponse.fromJson(
      responseEnvelope.body.response!,
    ).dnsInformation;
  }

  /// This operation lists all existing geo location configurations for the device.
  ///
  /// Access Class: READ_SYSTEM
  Future<dynamic> getGeoLocation() async {
    loggy.debug('getGeoLocation');

    final responseEnvelope = await transport.request(
      uri,
      soap.Body(request: DeviceManagementRequest.getGeoLocation()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetGeoLocationResponse.fromJson(
      responseEnvelope.body.response!,
    ).location;
  }

  /// This operation is used by an endpoint to get the hostname from a device.
  /// The device shall return its hostname configurations through the
  /// [getHostname]
  ///
  /// Access Class: PRE_AUTH
  Future<HostnameInformation> getHostname() async {
    loggy.debug('getHostname');

    final responseEnvelope = await transport.request(
      uri,
      soap.Body(request: DeviceManagementRequest.getHostname()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetHostnameResponse.fromJson(
      responseEnvelope.body.response!,
    ).hostnameInformation;
  }

  /// This operation gets the IP address filter settings from a device. If the
  /// device supports device access control based on IP filtering rules (denied
  /// or accepted ranges of IP addresses), the device shall support the
  /// GetIPAddressFilter command.
  Future<IpAddressFilter> getIPAddressFilter() async {
    loggy.debug('GetIPAddressFilter');

    final responseEnvelope = await transport.request(
      uri,
      soap.Body(request: DeviceManagementRequest.getIPAddressFilter()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetIpAddressFilterResponse.fromJson(
      responseEnvelope.body.response!,
    ).ipAddressFilter;
  }

  /// This operation gets defined network protocols from a device. The device
  /// shall support the [getNetworkProtocols] command returning configured
  /// network protocols.
  ///
  /// Access Class: READ_SYSTEM
  Future<List<NetworkProtocol>> getNetworkProtocols() async {
    loggy.debug('getNetworkProtocols');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getNetworkProtocols()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetNetworkProtocolsResponse.fromJson(
      responseEnvelope.body.response!,
    ).networkProtocols;
  }

  /// This operation gets the NTP settings from a device. If the device supports
  /// NTP, it shall be possible to get the NTP server settings through the
  /// [getNtp] command.
  ///
  /// Access Class: READ_SYSTEM
  Future<NtpInformation> getNtp() async {
    loggy.debug('getNtp');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getNtp()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetNtpResponse.fromJson(
      responseEnvelope.body.response!,
    ).ntpInformation;
  }

  /// Returns the capabilities of the device service. The result is returned in
  /// a typed answer.
  ///
  /// Access Class: PRE_AUTH
  Future<DeviceServiceCapabilities> getServiceCapabilities() async {
    loggy.debug('getServiceCapabilities');

    final responseEnvelope = await transport.request(
      uri,
      soap.Body(request: DeviceManagementRequest.getServiceCapabilities()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetServiceCapabilitiesResponse.fromJson(
      responseEnvelope.body.response!,
    ).capabilities;
  }

  /// Returns information about services on the device.
  ///
  /// Access Class: PRE_AUTH
  Future<List<Service>> getServices({bool includeCapability = false}) async {
    loggy.debug('getServices');

    final responseEnvelope =
        await requestFunction(
              uri,
              soap.Body(
                request: DeviceManagementRequest.getServices(includeCapability),
              ),
            )
            as Envelope;

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetServicesResponse.fromJson(
      responseEnvelope.body.response!,
    ).services;
  }

  /// This operation retrieves the Storage configuration associated with the
  /// given storage configuration token
  ///
  /// Access Class: READ_MEDIA
  Future<StorageConfiguration> getStorageConfiguration(
    String referenceToken,
  ) async {
    loggy.debug('getStorageConfigurations');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.getStorageConfiguration(
          referenceToken,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetStorageConfigurationResponse.fromJson(
      responseEnvelope.body.response!,
    ).storageConfiguration;
  }

  /// This operation lists all existing storage configurations for the device.
  ///
  /// Access Class: READ_MEDIA
  Future<List<StorageConfiguration>> getStorageConfigurations() async {
    loggy.debug('getStorageConfigurations');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getStorageConfigurations()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetStorageConfigurationsResponse.fromJson(
      responseEnvelope.body.response!,
    ).storageConfigurations;
  }

  /// This operation gets the device system date and time. The device shall
  /// support the return of the daylight saving setting and of the manual system
  /// date and time (if applicable) or indication of NTP time (if applicable)
  /// through the [getSystemDateAndTime] command.
  ///
  /// A device shall provide the UTC [DateTime] information.
  ///
  /// Access Class: PRE_AUTH
  Future<SystemDateAndTime> getSystemDateAndTime() async {
    loggy.debug('getSystemDateAndTime');

    final responseEnvelope = await transport.request(
      uri,
      soap.Body(request: DeviceManagementRequest.getSystemDateAndTime()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetSystemDateAndTimeResponse.fromJson(
      responseEnvelope.body.response!,
    ).systemDateAndTime;
  }

  /// This operation gets a system log from the device. The exact format of the
  /// system logs is outside the scope of this standard however a common format
  /// for the system log response is [SOAP Message Transmission Optimization Mechanism (MTOM)](https://www.ibm.com/docs/en/integration-bus/10.0?topic=services-what-is-soap-mtom)
  /// which is the use of MIME to optimize the bit stream transmission of SOAP
  /// messages that contain significantly large base64Binary elements.
  ///
  /// Access Class: READ_SYSTEM_SECRET
  Future<SystemInformation> getSystemLog(
    String logType, {
    String? writeLogToFolder,
  }) async {
    loggy.debug('getSystemLog');

    final securedXml = transport
        .getSecuredEnvelope(
          soap.Body(request: DeviceManagementRequest.getSystemLog(logType)),
        )
        .toXml(soap.Transport.builder);

    final response = await transport.sendLogRequest(uri, securedXml);

    String xmlString = parseMtom(response, writeLogToFolder: writeLogToFolder);

    loggy.debug('\ngetSystemLog - RESPONSE:\n$xmlString');

    final responseEnvelope = soap.Envelope.fromXmlString(xmlString);

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetSystemLogResponse.fromJson(
      responseEnvelope.body.response!,
    ).systemLog;
  }

  /// This operation gets arbitrary device diagnostics information from the
  /// device.
  ///
  /// Access Class: READ_SYSTEM_SECRET
  Future<SystemInformation?> getSystemSupportInformation({
    String? writeLogToFolder,
  }) async {
    loggy.debug('getSystemSupportInformation');

    String? xmlString;

    final securedXml = transport
        .getSecuredEnvelope(
          soap.Body(
            request: DeviceManagementRequest.getSystemSupportInformation(),
          ),
        )
        .toXml(soap.Transport.builder);

    final response = await transport.sendLogRequest(uri, securedXml);

    try {
      xmlString = parseMtom(response, writeLogToFolder: writeLogToFolder);

      loggy.debug('\ngetSystemSupportInformation - RESPONSE:\n$xmlString');
    } catch (e) {
      loggy.debug('Error parsing MTOM: $e');
    }

    final responseEnvelope = soap.Envelope.fromXmlString(
      utf8.decode(response.data!, allowMalformed: true),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetSystemSupportInformationResponse.fromJson(
      responseEnvelope.body.response!,
    ).supportInformation;
  }

  /// This operation is used to retrieve URIs from which system information may
  /// be downloaded using HTTP. URIs may be returned for the following system
  /// information:
  ///
  /// System Logs. Multiple system logs may be returned, of different types. The
  /// exact format of the system logs is outside the scope of this
  /// specification.
  ///
  /// Support Information. This consists of arbitrary device diagnostics
  /// information from a device. The exact format of the diagnostic information
  /// is outside the scope of this specification.
  ///
  /// System Backup. The received file is a backup file that can be used to
  /// restore the current device configuration at a later date. The exact format
  /// of the backup configuration file is outside the scope of this
  /// specification.
  ///
  /// If the device allows retrieval of system logs, support information or
  /// system backup data, it should make them available via HTTP GET. If it
  /// does, it shall support the GetSystemUris command.
  ///
  /// Access Class: READ_SYSTEM
  Future<GetSystemUrisResponse?> getSystemUris() async {
    loggy.debug('getSystemUris');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getSystemUris()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetSystemUrisResponse.fromJson(responseEnvelope.body.response!);
  }

  /// This operation lists the registered users and corresponding credentials on
  /// a device. The device shall support retrieval of registered device users
  /// and their credentials for the user token through the [getUsers] (GetUsers)
  /// command.
  ///
  /// Access Class: READ_SYSTEM_SECRET
  Future<List<User>> getUsers() async {
    loggy.debug('getUsers');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getUsers()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetUsersResponse.fromJson(responseEnvelope.body.response!).users;
  }

  /// This operation reboots the device.
  ///
  /// Access Class: UNRECOVERABLE
  Future<String> systemReboot() async {
    loggy.debug('systemReboot');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.systemReboot()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return SystemRebootResponse.fromJson(
      responseEnvelope.body.response!,
    ).message;
  }

  /// Access Class: READ_SYSTEM
  // Future<GetGeoLocationResponse> getGeoLocation() async {
  //   loggy.debug('getGeoLocation');

  //   final envelope = await transport.sendRequest(
  //       uri,
  //       transport
  //           .securedEnvelope(DeviceManagementRequest.getGeoLocation()));

  //   if (envelope.body.hasFault) {
  //     throw Exception(envelope.body.fault.toString());
  //   }

  //   // return SystemRebootResponse.fromJson(envelope.body.response!).message;
  //   return envelope.body.response!;
  // }

  /// A client can ask for the device service endpoint reference address
  /// property that can be used to derive the password equivalent for remote
  /// user operation. The device shall support the GetEndpointReference command
  /// returning the address property of the device service endpoint reference.
  ///
  /// Access Class: PRE_AUTH
  Future<Map<String, dynamic>> getEndpointReference() async {
    loggy.debug('getEndpointReference');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getEndpointReference()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return responseEnvelope.body.response!;
  }

  /// This operation gets a list of all available relay outputs and their
  /// settings.
  ///
  /// Access Class: READ_SYSTEM
  Future<List<RelayOutput>> getRelayOutputs() async {
    loggy.debug('getRelayOutputs');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getRelayOutputs()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetRelayOutputsResponse.fromJson(
      responseEnvelope.body.response!,
    ).relayOutputs;
  }

  /// This operation sets the state of a relay output.
  ///
  /// Access Class: ACTUATE
  Future<bool> setRelayOutputState({
    required String relayOutputToken,
    required RelayLogicalState logicalState,
  }) async {
    loggy.debug('setRelayOutputState');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.setRelayOutputState(
          relayOutputToken: relayOutputToken,
          logicalState: logicalState,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation sets the settings of a relay output.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setRelayOutputSettings({
    required String relayOutputToken,
    required RelayOutputSettings properties,
  }) async {
    loggy.debug('setRelayOutputSettings');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.setRelayOutputSettings(
          relayOutputToken: relayOutputToken,
          properties: properties,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation sets the geo location on the device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setGeoLocation(List<LocationEntity> locations) async {
    loggy.debug('setGeoLocation');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.setGeoLocation(locations)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation deletes the geo location on the device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> deleteGeoLocation(List<LocationEntity> locations) async {
    loggy.debug('deleteGeoLocation');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.deleteGeoLocation(locations)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation sets the hostname on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setHostname(String name) async {
    loggy.debug('setHostname');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.setHostname(name)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation controls whether the hostname shall be obtained via DHCP.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setHostnameFromDhcp(bool fromDhcp) async {
    loggy.debug('setHostnameFromDhcp');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.setHostnameFromDhcp(fromDhcp)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation sets the DNS settings on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setDns(DnsInformation dnsInformation) async {
    loggy.debug('setDns');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.setDns(dnsInformation)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation sets the NTP settings on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setNtp(NtpInformation ntpInformation) async {
    loggy.debug('setNtp');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.setNtp(ntpInformation)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation sets the dynamic DNS settings on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setDynamicDns(DynamicDnsInformation dynamicDnsInformation) async {
    loggy.debug('setDynamicDns');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.setDynamicDns(dynamicDnsInformation),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation configures one or more defined network protocols supported
  /// by the device (HTTP, HTTPS, RTSP).
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setNetworkProtocols(
    List<NetworkProtocol> networkProtocols,
  ) async {
    loggy.debug('setNetworkProtocols');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.setNetworkProtocols(networkProtocols),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  // Future<bool> setIpAddressFilter({
  //   required IpAddressFilter ipAddressFilter,
  // }) async {
  //       loggy.debug('setIpAddressFilter');

  //   final responseEnvelope = await transport.request(
  //     uri,
  //     soap.Body(
  //       request: ipAddressFilter
  //       ),
  //     ),
  //   );

  //   if (responseEnvelope.body.hasFault) {
  //     throw Exception(responseEnvelope.body.fault.toString());
  //   }

  //   return true;
  // }

  // Future<void> getLogOutput() async {
  //  Future<GetEndpointReferenceResponse> getEndpointReference() async {
  //   final envelope = await Soap.retrieveEnvelope(
  //       uri, onvif.secureRequest(Transport.endpointReference()),
  //       postProcess: (String xmlBody, dynamic jsonMap, Envelope envelope) {
  //     print(xmlBody);
  //     print('\n\n');
  //     print(jsonMap);
  //   });

  //   if (envelope.body.endpointReferenceResponse == null) throw Exception();

  //   return envelope.body.deviceInformationResponse!;
  // }
}
