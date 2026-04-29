import 'package:easy_onvif/device_management.dart';
import 'package:easy_onvif/src/model/fault.dart';
import 'package:test/test.dart';

import 'envelope.dart';

void main() {
  group('Device Management', () {
    group('unknown', () {
      test('GetCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/unknown/device_management/GetCapabilitiesResponse.xml',
        );

        expect(
          GetCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.device?.xAddr,
          'http://10.201.1.11:80/onvif/Device_service',
        );
      });
    });

    group('Happytimesoft', () {
      test('CreateUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/CreateUsersResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('CreateUsersResponse'),
          true,
        );
      });

      test('DeleteUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/DeleteUsersResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('DeleteUsersResponse'),
          true,
        );
      });

      test('GetCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetCapabilitiesResponse.xml',
        );

        expect(
          GetCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.device?.xAddr,
          'http://192.168.2.119:10000/onvif/device_service',
        );
      });

      test('GetDeviceInformationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetDeviceInformationResponse.xml',
        );

        expect(
          GetDeviceInformationResponse.fromJson(envelope.body.response!).model,
          'IPCamera',
        );
      });

      test('GetDiscoveryModeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetDiscoveryModeResponse.xml',
        );

        expect(
          GetDiscoveryModeResponse.fromJson(
            envelope.body.response!,
          ).discoveryMode,
          'Discoverable',
        );
      });

      test('GetDNSResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetDNSResponse.xml',
        );

        expect(
          GetDnsResponse.fromJson(
            envelope.body.response!,
          ).dnsInformation.fromDhcp,
          false,
        );
      });

      test('GetHostnameResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetHostnameResponse.xml',
        );

        expect(
          GetHostnameResponse.fromJson(
            envelope.body.response!,
          ).hostnameInformation.name,
          'LAPTOP-3NFBA69L',
        );
      });

      test('GetNetworkProtocolsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetNetworkProtocolsResponse.xml',
        );

        expect(
          GetNetworkProtocolsResponse.fromJson(
            envelope.body.response!,
          ).networkProtocols.isNotEmpty,
          true,
        );
      });

      test('GetNTPResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetNTPResponse.xml',
        );

        expect(
          GetNtpResponse.fromJson(
            envelope.body.response!,
          ).ntpInformation.fromDhcp,
          false,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.security!.dot1x,
          true,
        );
      });

      test('GetServicesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetServicesResponse.xml',
        );

        expect(
          GetServicesResponse.fromJson(
            envelope.body.response!,
          ).services.isNotEmpty,
          true,
        );
      });

      test('GetSystemDateAndTimeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetSystemDateAndTimeResponse.xml',
        );

        expect(
          GetSystemDateAndTimeResponse.fromJson(
            envelope.body.response!,
          ).systemDateAndTime.dateTimeType,
          'NTP',
        );
      });

      test('GetSystemUrisResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetSystemUrisResponse.xml',
        );

        expect(
          GetSystemUrisResponse.fromJson(
            envelope.body.response!,
          ).supportInfoUri,
          'http://192.168.2.119:10000/SupportInfo',
        );
      });

      test('GetUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/device_management/GetUsersResponse.xml',
        );

        expect(
          GetUsersResponse.fromJson(envelope.body.response!).users.isNotEmpty,
          true,
        );
      });
    });

    group('ENP1A14-IR_25X', () {
      test('CreateUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/CreateUsersResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('CreateUsersResponse'),
          true,
        );
      });

      test('DeleteUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/DeleteUsersResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('DeleteUsersResponse'),
          true,
        );
      });

      test('GetCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetCapabilitiesResponse.xml',
        );

        expect(
          GetCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.device?.xAddr,
          'http://192.168.1.182/onvif/device_service',
        );
      });

      test('GetDeviceInformationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetDeviceInformationResponse.xml',
        );

        expect(
          GetDeviceInformationResponse.fromJson(envelope.body.response!).model,
          'ENP1A14-IR/25X',
        );
      });

      test('GetDiscoveryModeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetDiscoveryModeResponse.xml',
        );

        expect(
          GetDiscoveryModeResponse.fromJson(
            envelope.body.response!,
          ).discoveryMode,
          'Discoverable',
        );
      });

      test('GetDNSResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetDNSResponse.xml',
        );

        expect(
          GetDnsResponse.fromJson(
            envelope.body.response!,
          ).dnsInformation.fromDhcp,
          false,
        );
      });

      test('GetHostnameResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetHostnameResponse.xml',
        );

        expect(
          GetHostnameResponse.fromJson(
            envelope.body.response!,
          ).hostnameInformation.name,
          'localhost',
        );
      });

      test('GetNetworkProtocolsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetNetworkProtocolsResponse.xml',
        );

        expect(
          GetNetworkProtocolsResponse.fromJson(
            envelope.body.response!,
          ).networkProtocols.isNotEmpty,
          true,
        );
      });

      test('GetNTPResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetNTPResponse.xml',
        );

        expect(
          GetNtpResponse.fromJson(
            envelope.body.response!,
          ).ntpInformation.fromDhcp,
          false,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.security!.tls1_2,
          true,
        );
      });

      test('GetServicesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetServicesResponse.xml',
        );

        expect(
          GetServicesResponse.fromJson(
            envelope.body.response!,
          ).services.isNotEmpty,
          true,
        );
      });

      test('GetSystemDateAndTimeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetSystemDateAndTimeResponse.xml',
        );

        expect(
          GetSystemDateAndTimeResponse.fromJson(
            envelope.body.response!,
          ).systemDateAndTime.dateTimeType,
          'Manual',
        );
      });

      test('GetSystemUrisResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetSystemUrisResponse.xml',
        );

        expect(
          GetSystemUrisResponse.fromJson(
            envelope.body.response!,
          ).supportInfoUri,
          null,
        );
      });

      test('GetUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/device_management/GetUsersResponse.xml',
        );

        expect(
          GetUsersResponse.fromJson(envelope.body.response!).users.isNotEmpty,
          true,
        );
      });
    });

    group('DCS-6511', () {
      test('CreateUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/CreateUsersResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('CreateUsersResponse'),
          true,
        );
      });

      test('DeleteUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/DeleteUsersResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('DeleteUsersResponse'),
          true,
        );
      });

      test('GetCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/GetCapabilitiesResponse.xml',
        );

        expect(
          GetCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.device?.xAddr,
          'http://192.168.1.33:80/onvif/device_service',
        );
      });

      test('GetDeviceInformationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/GetDeviceInformationResponse.xml',
        );

        expect(
          GetDeviceInformationResponse.fromJson(envelope.body.response!).model,
          'DCS-6511',
        );
      });

      test('GetDiscoveryModeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/GetDiscoveryModeResponse.xml',
        );

        expect(
          GetDiscoveryModeResponse.fromJson(
            envelope.body.response!,
          ).discoveryMode,
          'Discoverable',
        );
      });

      test('GetDNSResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/GetDNSResponse.xml',
        );

        expect(
          GetDnsResponse.fromJson(
            envelope.body.response!,
          ).dnsInformation.fromDhcp,
          false,
        );
      });

      test('GetHostnameResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/GetHostnameResponse.xml',
        );

        expect(
          GetHostnameResponse.fromJson(
            envelope.body.response!,
          ).hostnameInformation.name,
          'DCS-6511',
        );
      });

      test('GetNetworkProtocolsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/GetNetworkProtocolsResponse.xml',
        );

        expect(
          GetNetworkProtocolsResponse.fromJson(
            envelope.body.response!,
          ).networkProtocols.isNotEmpty,
          true,
        );
      });

      test('GetNTPResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/GetNTPResponse.xml',
        );

        expect(
          GetNtpResponse.fromJson(
            envelope.body.response!,
          ).ntpInformation.fromDhcp,
          false,
        );
      });

      test('GetSystemDateAndTimeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/GetSystemDateAndTimeResponse.xml',
        );

        expect(
          GetSystemDateAndTimeResponse.fromJson(
            envelope.body.response!,
          ).systemDateAndTime.dateTimeType,
          'NTP',
        );
      });

      test('GetSystemUrisResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/GetSystemUrisResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('GetSystemUrisResponse'),
          true,
        );
      });

      test('GetUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/device_management/GetUsersResponse.xml',
        );

        expect(
          GetUsersResponse.fromJson(envelope.body.response!).users.isNotEmpty,
          true,
        );
      });
    });

    group('GX728MF-IR28', () {
      test('CreateUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/CreateUsersResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('CreateUsersResponse'),
          true,
        );
      });

      test('DeleteUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/DeleteUsersResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('DeleteUsersResponse'),
          true,
        );
      });

      test('GetCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/GetCapabilitiesResponse.xml',
        );

        expect(
          GetCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.device?.xAddr,
          'http://192.168.1.127:80/onvif/device_service',
        );
      });

      test('GetDeviceInformationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/GetDeviceInformationResponse.xml',
        );

        expect(
          GetDeviceInformationResponse.fromJson(envelope.body.response!).model,
          'GX728MF-IR28',
        );
      });

      test('GetDiscoveryModeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/GetDiscoveryModeResponse.xml',
        );

        expect(
          GetDiscoveryModeResponse.fromJson(
            envelope.body.response!,
          ).discoveryMode,
          'Discoverable',
        );
      });

      test('GetDNSResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/GetDNSResponse.xml',
        );

        expect(
          GetDnsResponse.fromJson(
            envelope.body.response!,
          ).dnsInformation.fromDhcp,
          false,
        );
      });

      test('GetHostnameResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/GetHostnameResponse.xml',
        );

        expect(
          GetHostnameResponse.fromJson(
            envelope.body.response!,
          ).hostnameInformation.name,
          'IPC',
        );
      });

      test('GetNetworkProtocolsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/GetNetworkProtocolsResponse.xml',
        );

        expect(
          GetNetworkProtocolsResponse.fromJson(
            envelope.body.response!,
          ).networkProtocols.isNotEmpty,
          true,
        );
      });

      test('GetNTPResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/GetNTPResponse.xml',
        );

        expect(
          GetNtpResponse.fromJson(
            envelope.body.response!,
          ).ntpInformation.fromDhcp,
          false,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.system!.discoveryBye,
          true,
        );
      });

      test('GetServicesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/GetServicesResponse.xml',
        );

        expect(
          GetServicesResponse.fromJson(
            envelope.body.response!,
          ).services.isNotEmpty,
          true,
        );
      });

      test('GetSystemDateAndTimeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/GetSystemDateAndTimeResponse.xml',
        );

        expect(
          GetSystemDateAndTimeResponse.fromJson(
            envelope.body.response!,
          ).systemDateAndTime.dateTimeType,
          'Manual',
        );
      });

      test('GetUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/device_management/GetUsersResponse.xml',
        );

        expect(
          GetUsersResponse.fromJson(envelope.body.response!).users.isNotEmpty,
          true,
        );
      });
    });

    group('IPG-8150PSS', () {
      test('CreateUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/CreateUsersResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('CreateUsersResponse'),
          true,
        );
      });

      test('DeleteUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/DeleteUsersResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('DeleteUsersResponse'),
          true,
        );
      });

      test('Fault', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/Fault.xml',
        );

        expect(
          Fault.fromJson(envelope.body.response!).reason?.note,
          'Action Not Implemented',
        );
      });

      test('GetCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetCapabilitiesResponse.xml',
        );

        expect(
          GetCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.device?.xAddr,
          'http://10.200.1.2/onvif/device_service',
        );
      });

      test('GetDeviceInformationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetDeviceInformationResponse.xml',
        );

        expect(
          GetDeviceInformationResponse.fromJson(envelope.body.response!).model,
          'IPG-8150PSS',
        );
      });

      test('GetDiscoveryModeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetDiscoveryModeResponse.xml',
        );

        expect(
          GetDiscoveryModeResponse.fromJson(
            envelope.body.response!,
          ).discoveryMode,
          'Discoverable',
        );
      });

      test('GetDNSResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetDNSResponse.xml',
        );

        expect(
          GetDnsResponse.fromJson(
            envelope.body.response!,
          ).dnsInformation.fromDhcp,
          false,
        );
      });

      test('GetHostnameResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetHostnameResponse.xml',
        );

        expect(
          GetHostnameResponse.fromJson(
            envelope.body.response!,
          ).hostnameInformation.name,
          'IPCAM',
        );
      });

      test('GetNetworkProtocolsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetNetworkProtocolsResponse.xml',
        );

        expect(
          GetNetworkProtocolsResponse.fromJson(
            envelope.body.response!,
          ).networkProtocols.isNotEmpty,
          true,
        );
      });

      test('GetNTPResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetNTPResponse.xml',
        );

        expect(
          GetNtpResponse.fromJson(
            envelope.body.response!,
          ).ntpInformation.fromDhcp,
          false,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.system!.discoveryBye,
          true,
        );
      });

      test('GetServicesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetServicesResponse.xml',
        );

        expect(
          GetServicesResponse.fromJson(
            envelope.body.response!,
          ).services.isNotEmpty,
          true,
        );
      });

      test('GetSystemDateAndTimeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetSystemDateAndTimeResponse.xml',
        );

        expect(
          GetSystemDateAndTimeResponse.fromJson(
            envelope.body.response!,
          ).systemDateAndTime.dateTimeType,
          'Manual',
        );
      });

      test('GetSystemLogResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetSystemLogResponse.xml',
        );

        expect(
          GetSystemLogResponse.fromJson(
            envelope.body.response!,
          ).systemLog.string,
          'Test System Log',
        );
      });

      test('GetSystemUrisResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetSystemUrisResponse.xml',
        );

        expect(
          envelope.body.response?.containsKey('GetSystemUrisResponse'),
          true,
        );
      });

      test('GetUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/GetUsersResponse.xml',
        );

        expect(
          GetUsersResponse.fromJson(envelope.body.response!).users.isNotEmpty,
          true,
        );
      });

      test('SystemRebootResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/device_management/SystemRebootResponse.xml',
        );

        expect(
          SystemRebootResponse.fromJson(envelope.body.response!).message,
          'Rebooting',
        );
      });
    });

    group('SUNBA', () {
      test('Fault', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/Fault.xml',
        );

        expect(
          Fault.fromJson(envelope.body.response!).reason?.note,
          'Optional Action Not Implemented',
        );
      });

      test('GetCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetCapabilitiesResponse.xml',
        );

        expect(
          GetCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.device?.xAddr,
          'http://162.191.54.181:80/onvif/device_service',
        );
      });

      test('GetDeviceInformationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetDeviceInformationResponse.xml',
        );
        expect(
          GetDeviceInformationResponse.fromJson(envelope.body.response!).model,
          'Performance-Series',
        );
      });

      test('GetDiscoveryModeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetDiscoveryModeResponse.xml',
        );

        expect(
          GetDiscoveryModeResponse.fromJson(
            envelope.body.response!,
          ).discoveryMode,
          'Discoverable',
        );
      });

      test('GetDNSResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetDNSResponse.xml',
        );

        expect(
          GetDnsResponse.fromJson(
            envelope.body.response!,
          ).dnsInformation.fromDhcp,
          false,
        );
      });

      test('GetHostnameResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetHostnameResponse.xml',
        );

        expect(
          GetHostnameResponse.fromJson(
            envelope.body.response!,
          ).hostnameInformation.name,
          'IPC',
        );
      });

      test('GetNetworkProtocolsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetNetworkProtocolsResponse.xml',
        );

        expect(
          GetNetworkProtocolsResponse.fromJson(
            envelope.body.response!,
          ).networkProtocols.isNotEmpty,
          true,
        );
      });

      test('GetNTPResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetNTPResponse.xml',
        );

        expect(
          GetNtpResponse.fromJson(
            envelope.body.response!,
          ).ntpInformation.fromDhcp,
          false,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.system!.discoveryBye,
          true,
        );
      });

      test('GetServicesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetServicesResponse.xml',
        );

        expect(
          GetServicesResponse.fromJson(
            envelope.body.response!,
          ).services.isNotEmpty,
          true,
        );
      });

      test('GetSystemDateAndTimeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetSystemDateAndTimeResponse.xml',
        );

        expect(
          GetSystemDateAndTimeResponse.fromJson(
            envelope.body.response!,
          ).systemDateAndTime.dateTimeType,
          'Manual',
        );
      });

      test('GetSystemLogResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetSystemLogResponse.xml',
        );

        expect(
          GetSystemLogResponse.fromJson(
            envelope.body.response!,
          ).systemLog.binary?.include,
          isNotNull,
        );
      });

      test('GetUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetUsersResponse.xml',
        );

        expect(
          GetUsersResponse.fromJson(envelope.body.response!).users.isNotEmpty,
          true,
        );
      });

      test('SystemSupportInformation', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/GetSystemSupportInformationResponse.xml',
        );

        expect(
          GetSystemSupportInformationResponse.fromJson(
            envelope.body.response!,
          ).supportInformation?.binary?.include?.href,
          '<http://tempuri.org/0/log.tgz>',
        );
      });

      test('SystemRebootResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/device_management/SystemRebootResponse.xml',
        );

        expect(
          SystemRebootResponse.fromJson(envelope.body.response!).message,
          'Rebooting in 2 seconds',
        );
      });
    });

    group('IPD-H4K8M05-BS', () {
      test('Fault', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/Fault.xml',
        );

        expect(
          Fault.fromJson(envelope.body.response!).reason?.note,
          'Method \'GetStorageConfigurations\' not implemented: method name or namespace not recognized',
        );
      });

      test('GetCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetCapabilitiesResponse.xml',
        );

        expect(
          GetCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.device?.xAddr,
          'http://192.168.15.40:8999/onvif/device_service',
        );
      });

      test('GetDeviceInformationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetDeviceInformationResponse.xml',
        );
        expect(
          GetDeviceInformationResponse.fromJson(envelope.body.response!).model,
          'IPD-H4K8M05-BS',
        );
      });

      test('GetDiscoveryModeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetDiscoveryModeResponse.xml',
        );

        expect(
          GetDiscoveryModeResponse.fromJson(
            envelope.body.response!,
          ).discoveryMode,
          'Discoverable',
        );
      });

      test('GetDNSResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetDNSResponse.xml',
        );

        expect(
          GetDnsResponse.fromJson(
            envelope.body.response!,
          ).dnsInformation.fromDhcp,
          false,
        );
      });

      test('GetHostnameResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetHostnameResponse.xml',
        );

        expect(
          GetHostnameResponse.fromJson(
            envelope.body.response!,
          ).hostnameInformation.name,
          null,
        );
      });

      test('GetNetworkProtocolsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetNetworkProtocolsResponse.xml',
        );

        expect(
          GetNetworkProtocolsResponse.fromJson(
            envelope.body.response!,
          ).networkProtocols.isNotEmpty,
          true,
        );
      });

      test('GetNTPResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetNTPResponse.xml',
        );

        expect(
          GetNtpResponse.fromJson(
            envelope.body.response!,
          ).ntpInformation.fromDhcp,
          false,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.system!.discoveryBye,
          true,
        );
      });

      test('GetServicesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetServicesResponse.xml',
        );

        expect(
          GetServicesResponse.fromJson(
            envelope.body.response!,
          ).services.isNotEmpty,
          true,
        );
      });

      test('GetSystemDateAndTimeResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetSystemDateAndTimeResponse.xml',
        );

        expect(
          GetSystemDateAndTimeResponse.fromJson(
            envelope.body.response!,
          ).systemDateAndTime.dateTimeType,
          'Manual',
        );
      });

      // test('GetSystemLogResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //     '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetSystemLogResponse.xml',
      //   );

      //   expect(
      //     GetSystemLogResponse.fromJson(
      //       envelope.body.response!,
      //     ).systemLog.binary?.include,
      //     isNotNull,
      //   );
      // });

      test('GetUsersResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetUsersResponse.xml',
        );

        expect(
          GetUsersResponse.fromJson(envelope.body.response!).users.isNotEmpty,
          true,
        );
      });

      test('SystemSupportInformation', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/GetSystemSupportInformationResponse.xml',
        );

        expect(
          GetSystemSupportInformationResponse.fromJson(
            envelope.body.response!,
          ).supportInformation,
          null,
        );
      });

      test('SystemRebootResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/device_management/SystemRebootResponse.xml',
        );

        expect(
          SystemRebootResponse.fromJson(envelope.body.response!).message,
          'Rebooting in 120 seconds.',
        );
      });
    });
  });
}
