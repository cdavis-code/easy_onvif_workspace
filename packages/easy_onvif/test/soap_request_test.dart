import 'package:dio/dio.dart';
import 'package:easy_onvif/device_management.dart';
import 'package:easy_onvif/media1.dart';
import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/ptz.dart';
import 'package:easy_onvif/recordings.dart';
import 'package:easy_onvif/replay.dart';
import 'package:easy_onvif/search.dart';
import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' as soap;
import 'package:test/test.dart';

typedef DeviceManagementRequest = soap.DeviceManagementRequest;
typedef ImagingRequest = soap.ImagingRequest;
typedef MediaRequest = soap.MediaRequest;
typedef Media2Request = soap.Media2Request;
typedef PtzRequest = soap.PtzRequest;
typedef ReplayRequest = soap.ReplayRequest;
typedef SearchRequest = soap.SearchRequest;

void main() {
  soap.Transport(
    dio: Dio(),
    authInfo: AuthInfo(host: '', password: '', username: ''),
  );

  final builder = soap.Transport.builder;
  group('Device Management SOAP Requests', () {
    test('createUsers', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.createUsers([
          User(username: 'test', userLevel: UserLevel.user, password: 'test'),
        ]),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><CreateUsers xmlns="http://www.onvif.org/ver10/device/wsdl"><User><Username>test</Username><Password>test</Password><UserLevel>User</UserLevel></User></CreateUsers></Test>',
      );
    });

    test('deleteUsers', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.deleteUsers(['test']),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><DeleteUsers xmlns="http://www.onvif.org/ver10/device/wsdl"><Username>test</Username></DeleteUsers></Test>',
      );
    });

    test('getSystemDateAndTime', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.getSystemDateAndTime(),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetSystemDateAndTime xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getServices', () {
      builder.element('Test', nest: DeviceManagementRequest.getServices());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetServices xmlns="http://www.onvif.org/ver10/device/wsdl"><IncludeCapability>false</IncludeCapability></GetServices></Test>',
      );
    });

    test('getStorageConfiguration', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.getStorageConfiguration('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetStorageConfiguration xmlns="http://www.onvif.org/ver10/device/wsdl"><Token>testToken</Token></GetStorageConfiguration></Test>',
      );
    });

    test('getStorageConfigurations', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.getStorageConfigurations(),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetStorageConfigurations xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getDeviceInformation', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.getDeviceInformation(),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetDeviceInformation xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getHostname', () {
      builder.element('Test', nest: DeviceManagementRequest.getHostname());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetHostname xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getEndpointReference', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.getEndpointReference(),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetEndpointReference xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getServiceCapabilities', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.getServiceCapabilities(),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetServiceCapabilities xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getNetworkProtocols', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.getNetworkProtocols(),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetNetworkProtocols xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('systemReboot', () {
      builder.element('Test', nest: DeviceManagementRequest.systemReboot());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SystemReboot xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getSystemUris', () {
      builder.element('Test', nest: DeviceManagementRequest.getSystemUris());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetSystemUris xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getUsers', () {
      builder.element('Test', nest: DeviceManagementRequest.getUsers());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetUsers xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getDiscoveryMode', () {
      builder.element('Test', nest: DeviceManagementRequest.getDiscoveryMode());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetDiscoveryMode xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getDns', () {
      builder.element('Test', nest: DeviceManagementRequest.getDns());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetDNS xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getNtp', () {
      builder.element('Test', nest: DeviceManagementRequest.getNtp());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetNTP xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getGeoLocation', () {
      builder.element('Test', nest: DeviceManagementRequest.getGeoLocation());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetGeoLocation xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('getRelayOutputs', () {
      builder.element('Test', nest: DeviceManagementRequest.getRelayOutputs());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetRelayOutputs xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('setRelayOutputState', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setRelayOutputState(
          relayOutputToken: 'relay1',
          logicalState: RelayLogicalState.active,
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetRelayOutputState xmlns="http://www.onvif.org/ver10/device/wsdl"><RelayOutputToken>relay1</RelayOutputToken><LogicalState>active</LogicalState></SetRelayOutputState></Test>',
      );
    });

    test('setRelayOutputSettings', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setRelayOutputSettings(
          relayOutputToken: 'relay1',
          properties: RelayOutputSettings(
            mode: RelayMode.monostable,
            delayTime: 'PT1S',
            idleState: RelayIdleState.open,
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetRelayOutputSettings xmlns="http://www.onvif.org/ver10/device/wsdl"><RelayOutputToken>relay1</RelayOutputToken><Properties><Mode>Monostable</Mode><DelayTime>PT1S</DelayTime><IdleState>open</IdleState></Properties></SetRelayOutputSettings></Test>',
      );
    });

    test('setGeoLocation', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setGeoLocation([
          LocationEntity(geoLocation: GeoLocation(lat: 34.0, lon: 12.0)),
        ]),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetGeoLocation xmlns="http://www.onvif.org/ver10/device/wsdl"><Location><GeoLocation lon="12.0" lat="34.0"/></Location></SetGeoLocation></Test>',
      );
    });

    test('deleteGeoLocation', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.deleteGeoLocation([
          LocationEntity(geoLocation: GeoLocation(lat: 34.0, lon: 12.0)),
        ]),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><DeleteGeoLocation xmlns="http://www.onvif.org/ver10/device/wsdl"><Location><GeoLocation lon="12.0" lat="34.0"/></Location></DeleteGeoLocation></Test>',
      );
    });

    test('setHostname', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setHostname('camera1'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetHostname xmlns="http://www.onvif.org/ver10/device/wsdl"><Name>camera1</Name></SetHostname></Test>',
      );
    });

    test('setHostnameFromDhcp', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setHostnameFromDhcp(true),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetHostnameFromDHCP xmlns="http://www.onvif.org/ver10/device/wsdl"><FromDHCP>true</FromDHCP></SetHostnameFromDHCP></Test>',
      );
    });

    test('setDns', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setDns(
          DnsInformation(
            fromDhcp: false,
            searchDomain: ['example.com'],
            dnsManual: [
              DnsEntry(type: 'IPv4', ipv4Address: '8.8.8.8', ipv6Address: null),
            ],
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetDNS xmlns="http://www.onvif.org/ver10/device/wsdl"><FromDHCP>false</FromDHCP><SearchDomain>example.com</SearchDomain><DNSManual><Type>IPv4</Type><IPv4Address>8.8.8.8</IPv4Address></DNSManual></SetDNS></Test>',
      );
    });

    test('setNtp', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setNtp(
          NtpInformation(
            fromDhcp: false,
            ntpManual: [Ntp(type: 'IPv4', iPv4Address: '129.6.15.28')],
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetNTP xmlns="http://www.onvif.org/ver10/device/wsdl"><FromDHCP>false</FromDHCP><NTPManual><Type>IPv4</Type><IPv4Address>129.6.15.28</IPv4Address></NTPManual></SetNTP></Test>',
      );
    });

    test('setDynamicDns', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setDynamicDns(
          DynamicDnsInformation(
            type: DynamicDnsType.clientUpdates,
            name: 'host.example.com',
            ttl: 'PT1H',
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetDynamicDNS xmlns="http://www.onvif.org/ver10/device/wsdl"><Type>ClientUpdates</Type><Name>host.example.com</Name><TTL>PT1H</TTL></SetDynamicDNS></Test>',
      );
    });

    test('setNetworkProtocols', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setNetworkProtocols([
          NetworkProtocol(name: 'HTTP', enabled: true, port: 80),
        ]),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetNetworkProtocols xmlns="http://www.onvif.org/ver10/device/wsdl"><NetworkProtocols><Name>HTTP</Name><Enabled>true</Enabled><Port>80</Port></NetworkProtocols></SetNetworkProtocols></Test>',
      );
    });

    test('getNetworkDefaultGateway', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.getNetworkDefaultGateway(),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetNetworkDefaultGateway xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('setNetworkDefaultGateway', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setNetworkDefaultGateway(
          NetworkGateway(ipv4Addresses: ['192.168.0.1']),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetNetworkDefaultGateway xmlns="http://www.onvif.org/ver10/device/wsdl"><IPv4Address>192.168.0.1</IPv4Address></SetNetworkDefaultGateway></Test>',
      );
    });

    test('getZeroConfiguration', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.getZeroConfiguration(),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetZeroConfiguration xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('setZeroConfiguration', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setZeroConfiguration(
          interfaceToken: 'eth0',
          enabled: true,
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetZeroConfiguration xmlns="http://www.onvif.org/ver10/device/wsdl"><InterfaceToken>eth0</InterfaceToken><Enabled>true</Enabled></SetZeroConfiguration></Test>',
      );
    });

    test('setIpAddressFilter', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setIpAddressFilter(
          ipAddressFilter: IpAddressFilter(
            type: Type.allow,
            prefixedIpv4Addresses: [
              PrefixedIpv4Address(address: '192.168.0.10', prefixLength: 24),
            ],
            prefixedIpv6Addresses: [],
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetIPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><IPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><Type>Allow</Type><IPv4Address xmlns="http://www.onvif.org/ver10/device/wsdl"><Address>192.168.0.10</Address><PrefixLength>24</PrefixLength></IPv4Address></IPAddressFilter></SetIPAddressFilter></Test>',
      );
    });

    test('addIpAddressFilter', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.addIpAddressFilter(
          ipAddressFilter: IpAddressFilter(
            type: Type.deny,
            prefixedIpv4Addresses: [
              PrefixedIpv4Address(address: '10.0.0.5', prefixLength: 32),
            ],
            prefixedIpv6Addresses: [],
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><AddIPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><IPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><Type>Deny</Type><IPv4Address xmlns="http://www.onvif.org/ver10/device/wsdl"><Address>10.0.0.5</Address><PrefixLength>32</PrefixLength></IPv4Address></IPAddressFilter></AddIPAddressFilter></Test>',
      );
    });

    test('removeIpAddressFilter', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.removeIpAddressFilter(
          ipAddressFilter: IpAddressFilter(
            type: Type.allow,
            prefixedIpv4Addresses: [
              PrefixedIpv4Address(address: '192.168.0.10', prefixLength: 24),
            ],
            prefixedIpv6Addresses: [],
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><RemoveIPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><IPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><Type>Allow</Type><IPv4Address xmlns="http://www.onvif.org/ver10/device/wsdl"><Address>192.168.0.10</Address><PrefixLength>24</PrefixLength></IPv4Address></IPAddressFilter></RemoveIPAddressFilter></Test>',
      );
    });
  });

  group('Imaging SOAP Requests', () {
    test('getCurrentPreset', () {
      builder.element(
        'Test',
        nest: ImagingRequest.getCurrentPreset('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetCurrentPreset xmlns="http://www.onvif.org/ver20/imaging/wsdl"><VideoSourceToken>testToken</VideoSourceToken></GetCurrentPreset></Test>',
      );
    });

    test('getPresets', () {
      builder.element('Test', nest: ImagingRequest.getPresets('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetPresets xmlns="http://www.onvif.org/ver20/imaging/wsdl"><VideoSourceToken>testToken</VideoSourceToken></GetPresets></Test>',
      );
    });

    test('getServiceCapabilities', () {
      builder.element('Test', nest: ImagingRequest.getServiceCapabilities());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetServiceCapabilities xmlns="http://www.onvif.org/ver20/imaging/wsdl"/></Test>',
      );
    });

    test('getStatus', () {
      builder.element('Test', nest: ImagingRequest.getStatus('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetStatus xmlns="http://www.onvif.org/ver20/imaging/wsdl"><VideoSourceToken>testToken</VideoSourceToken></GetStatus></Test>',
      );
    });

    test('setCurrentPreset', () {
      builder.element(
        'Test',
        nest: ImagingRequest.setCurrentPreset(
          videoSourceToken: 'testToken',
          presetToken: 'testToken',
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetPreset xmlns="http://www.onvif.org/ver20/imaging/wsdl"><VideoSourceToken>testToken</VideoSourceToken><PresetToken>testToken</PresetToken></SetPreset></Test>',
      );
    });
  });

  group('Media1 SOAP Requests', () {
    test('getAudioSources', () {
      builder.element('Test', nest: MediaRequest.getAudioSources());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetAudioSources xmlns="http://www.onvif.org/ver10/media/wsdl"/></Test>',
      );
    });

    test('getMetadataConfiguration', () {
      builder.element(
        'Test',
        nest: MediaRequest.getMetadataConfiguration('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetMetadataConfiguration xmlns="http://www.onvif.org/ver10/media/wsdl"><ConfigurationToken>testToken</ConfigurationToken></GetMetadataConfiguration></Test>',
      );
    });

    test('getMetadataConfigurations', () {
      builder.element(
        'Test',
        nest: MediaRequest.getMetadataConfigurations(
          configurationToken: 'testToken',
          profileToken: 'testToken',
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetMetadataConfigurations xmlns="http://www.onvif.org/ver10/media/wsdl"><ConfigurationToken>testToken</ConfigurationToken><ProfileToken>testToken</ProfileToken></GetMetadataConfigurations></Test>',
      );
    });

    test('getProfile', () {
      builder.element('Test', nest: MediaRequest.getProfile('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetProfile xmlns="http://www.onvif.org/ver10/media/wsdl"><ProfileToken>testToken</ProfileToken></GetProfile></Test>',
      );
    });

    test('getProfiles', () {
      builder.element('Test', nest: MediaRequest.getProfiles());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetProfiles xmlns="http://www.onvif.org/ver10/media/wsdl"/></Test>',
      );
    });

    test('getServiceCapabilities', () {
      builder.element('Test', nest: MediaRequest.getServiceCapabilities());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetServiceCapabilities xmlns="http://www.onvif.org/ver10/media/wsdl"/></Test>',
      );
    });

    test('getSnapshotUri', () {
      builder.element('Test', nest: MediaRequest.getSnapshotUri('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetSnapshotUri xmlns="http://www.onvif.org/ver10/media/wsdl"><ProfileToken>testToken</ProfileToken></GetSnapshotUri></Test>',
      );
    });

    test('getStreamUri', () {
      builder.element(
        'Test',
        nest: MediaRequest.getStreamUri(
          'testToken',
          streamSetup: StreamSetup(
            stream: 'RTP-Multicast',
            transport: Transport(protocol: 'HTTP'),
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetStreamUri xmlns="http://www.onvif.org/ver10/media/wsdl"><StreamSetup xmlns="http://www.onvif.org/ver10/media/wsdl"><Stream xmlns="http://www.onvif.org/ver10/schema">RTP-Multicast</Stream><Transport xmlns="http://www.onvif.org/ver10/schema"><Protocol xmlns="http://www.onvif.org/ver10/schema">HTTP</Protocol></Transport></StreamSetup><ProfileToken>testToken</ProfileToken></GetStreamUri></Test>',
      );
    });

    test('getVideoSources', () {
      builder.element('Test', nest: MediaRequest.getVideoSources());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetVideoSources xmlns="http://www.onvif.org/ver10/media/wsdl"/></Test>',
      );
    });

    test('startMulticastStreaming', () {
      builder.element(
        'Test',
        nest: MediaRequest.startMulticastStreaming('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><StartMulticastStreaming xmlns="http://www.onvif.org/ver10/media/wsdl"><ProfileToken>testToken</ProfileToken></StartMulticastStreaming></Test>',
      );
    });

    test('stopMulticastStreaming', () {
      builder.element(
        'Test',
        nest: MediaRequest.stopMulticastStreaming('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><StopMulticastStreaming xmlns="http://www.onvif.org/ver10/media/wsdl"><ProfileToken>testToken</ProfileToken></StopMulticastStreaming></Test>',
      );
    });
  });

  group('Media2 SOAP Requests', () {
    test('deleteProfile', () {
      builder.element('Test', nest: Media2Request.deleteProfile('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><DeleteProfile xmlns="http://www.onvif.org/ver20/media/wsdl"><Token>testToken</Token></DeleteProfile></Test>',
      );
    });

    test('getMetadataConfigurationOptions', () {
      builder.element(
        'Test',
        nest: Media2Request.getMetadataConfigurationOptions(
          configurationToken: 'testToken',
          profileToken: 'testToken',
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetMetadataConfigurationOptions xmlns="http://www.onvif.org/ver20/media/wsdl"><ConfigurationToken>testToken</ConfigurationToken><ProfileToken>testToken</ProfileToken></GetMetadataConfigurationOptions></Test>',
      );
    });

    test('getMetadataConfigurations', () {
      builder.element(
        'Test',
        nest: Media2Request.getMetadataConfigurations(
          configurationToken: 'testToken',
          profileToken: 'testToken',
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetMetadataConfigurations xmlns="http://www.onvif.org/ver20/media/wsdl"><ConfigurationToken>testToken</ConfigurationToken><ProfileToken>testToken</ProfileToken></GetMetadataConfigurations></Test>',
      );
    });

    test('getProfiles', () {
      builder.element('Test', nest: Media2Request.getProfiles());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetProfiles xmlns="http://www.onvif.org/ver20/media/wsdl"/></Test>',
      );
    });

    test('getServiceCapabilities', () {
      builder.element('Test', nest: Media2Request.getServiceCapabilities());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetServiceCapabilities xmlns="http://www.onvif.org/ver20/media/wsdl"/></Test>',
      );
    });

    test('getSnapshotUri', () {
      builder.element('Test', nest: Media2Request.getSnapshotUri('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetSnapshotUri xmlns="http://www.onvif.org/ver20/media/wsdl"><ProfileToken>testToken</ProfileToken></GetSnapshotUri></Test>',
      );
    });

    test('getStreamUri', () {
      builder.element(
        'Test',
        nest: Media2Request.getStreamUri('testToken', protocol: 'HTTP'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetStreamUri xmlns="http://www.onvif.org/ver20/media/wsdl"><Protocol>HTTP</Protocol><Protocol xmlns="http://www.onvif.org/ver10/schema">HTTP</Protocol><ProfileToken>testToken</ProfileToken></GetStreamUri></Test>',
      );
    });

    test('getVideoEncoderInstances', () {
      builder.element(
        'Test',
        nest: Media2Request.getVideoEncoderInstances('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetVideoEncoderInstances xmlns="http://www.onvif.org/ver20/media/wsdl"><ConfigurationToken>testToken</ConfigurationToken></GetVideoEncoderInstances></Test>',
      );
    });

    test('getVideoSourceConfigurationOptions', () {
      builder.element(
        'Test',
        nest: Media2Request.getVideoSourceConfigurationOptions(
          configurationToken: 'testToken',
          profileToken: 'testToken',
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetVideoSourceConfigurationOptions xmlns="http://www.onvif.org/ver20/media/wsdl"><ConfigurationToken>testToken</ConfigurationToken><ProfileToken>testToken</ProfileToken></GetVideoSourceConfigurationOptions></Test>',
      );
    });

    test('startMulticastStreaming', () {
      builder.element(
        'Test',
        nest: Media2Request.startMulticastStreaming('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><StartMulticastStreaming xmlns="http://www.onvif.org/ver20/media/wsdl"><ProfileToken>testToken</ProfileToken></StartMulticastStreaming></Test>',
      );
    });

    test('stopMulticastStreaming', () {
      builder.element(
        'Test',
        nest: Media2Request.stopMulticastStreaming('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><StopMulticastStreaming xmlns="http://www.onvif.org/ver20/media/wsdl"><ProfileToken>testToken</ProfileToken></StopMulticastStreaming></Test>',
      );
    });
  });

  group('PTZ SOAP Requests', () {
    test('absoluteMove', () {
      builder.element(
        'Test',
        nest: PtzRequest.absoluteMove(
          'testToken',
          position: PtzVector(
            panTilt: Vector2D(x: 0, y: 0),
            zoom: Vector1D(x: 0),
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><AbsoluteMove xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken><Position xmlns="http://www.onvif.org/ver20/ptz/wsdl"><PanTilt xmlns="http://www.onvif.org/ver10/schema" x="0.0" y="0.0"/><Zoom xmlns="http://www.onvif.org/ver10/schema" x="0.0"/></Position></AbsoluteMove></Test>',
      );
    });

    test('continuousMove', () {
      builder.element(
        'Test',
        nest: PtzRequest.continuousMove(
          'testToken',
          velocity: PtzSpeed(
            panTilt: Vector2D(x: 0, y: 0),
            zoom: Vector1D(x: 0),
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><ContinuousMove xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken><Velocity xmlns="http://www.onvif.org/ver20/ptz/wsdl"><PanTilt xmlns="http://www.onvif.org/ver10/schema" x="0.0" y="0.0"/><Zoom xmlns="http://www.onvif.org/ver10/schema" x="0.0"/></Velocity></ContinuousMove></Test>',
      );
    });

    test('getCompatibleConfigurations', () {
      builder.element(
        'Test',
        nest: PtzRequest.getCompatibleConfigurations('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetCompatibleConfigurations xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken></GetCompatibleConfigurations></Test>',
      );
    });

    test('getConfiguration', () {
      builder.element('Test', nest: PtzRequest.getConfiguration('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetConfiguration xmlns="http://www.onvif.org/ver20/ptz/wsdl"><PTZConfigurationToken>testToken</PTZConfigurationToken></GetConfiguration></Test>',
      );
    });

    test('getConfigurationOptions', () {
      builder.element(
        'Test',
        nest: PtzRequest.getConfigurationOptions('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetConfigurationOptions xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ConfigurationToken>testToken</ConfigurationToken></GetConfigurationOptions></Test>',
      );
    });

    test('getConfigurations', () {
      builder.element('Test', nest: PtzRequest.getConfigurations());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetConfigurations xmlns="http://www.onvif.org/ver20/ptz/wsdl"/></Test>',
      );
    });

    test('getPresets', () {
      builder.element('Test', nest: PtzRequest.getPresets('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetPresets xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken></GetPresets></Test>',
      );
    });

    test('getPresetTour', () {
      builder.element(
        'Test',
        nest: PtzRequest.getPresetTour(
          'testToken',
          presetTourToken: 'testToken',
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetPresetTour xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken><PresetTourToken>testToken</PresetTourToken></GetPresetTour></Test>',
      );
    });

    test('getPresetTours', () {
      builder.element('Test', nest: PtzRequest.getPresetTours('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetPresetTours xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken></GetPresetTours></Test>',
      );
    });

    test('getServiceCapabilities', () {
      builder.element('Test', nest: PtzRequest.getServiceCapabilities());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetServiceCapabilities xmlns="http://www.onvif.org/ver20/ptz/wsdl"/></Test>',
      );
    });

    test('getStatus', () {
      builder.element('Test', nest: PtzRequest.getStatus('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetStatus xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken></GetStatus></Test>',
      );
    });

    test('gotoHomePosition', () {
      builder.element('Test', nest: PtzRequest.gotoHomePosition('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GotoHomePosition xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken></GotoHomePosition></Test>',
      );
    });

    test('gotoPreset', () {
      builder.element(
        'Test',
        nest: PtzRequest.gotoPreset('testToken', presetToken: 'testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GotoPreset xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken><PresetToken>testToken</PresetToken></GotoPreset></Test>',
      );
    });

    test('relativeMove', () {
      builder.element(
        'Test',
        nest: PtzRequest.relativeMove(
          'testToken',
          translation: PtzVector(panTilt: Vector2D(x: 0, y: 0)),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><RelativeMove xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken xmlns="http://www.onvif.org/ver20/ptz/wsdl">testToken</ProfileToken><Translation xmlns="http://www.onvif.org/ver20/ptz/wsdl"><PanTilt xmlns="http://www.onvif.org/ver10/schema" x="0.0" y="0.0"/></Translation></RelativeMove></Test>',
      );
    });

    test('removePreset', () {
      builder.element(
        'Test',
        nest: PtzRequest.removePreset(
          'testToken',
          preset: Preset.fromToken('testToken'),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><RemovePreset xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken><PresetToken>testToken</PresetToken></RemovePreset></Test>',
      );
    });

    test('removePresetTour', () {
      builder.element(
        'Test',
        nest: PtzRequest.removePresetTour(
          'testToken',
          presetTour: PresetTour(
            token: 'testToken',
            status: PtzPresetTourStatus(state: PtzPresetTourState.idle),
            autoStart: true,
            startingCondition: PtzPresetTourStartingCondition(),
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><RemovePresetTour xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken><PresetTourToken>testToken</PresetTourToken></RemovePresetTour></Test>',
      );
    });

    test('setHomePosition', () {
      builder.element('Test', nest: PtzRequest.setHomePosition('testToken'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetHomePosition xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken></SetHomePosition></Test>',
      );
    });

    test('setPreset', () {
      builder.element(
        'Test',
        nest: PtzRequest.setPreset(
          'testToken',
          presetName: 'name',
          presetToken: 'testToken',
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetPreset xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken><PresetName xmlns="http://www.onvif.org/ver20/ptz/wsdl">name</PresetName><PresetToken xmlns="http://www.onvif.org/ver20/ptz/wsdl">testToken</PresetToken></SetPreset></Test>',
      );
    });

    test('stop', () {
      builder.element(
        'Test',
        nest: PtzRequest.stop('testToken', panTilt: true, zoom: true),
      );

      // As of v3.1.3 the Stop operation is issued as a zero-velocity
      // ContinuousMove (broader device compatibility), not a Stop element.
      expect(
        builder.buildDocument().toXmlString(),
        '<Test><ContinuousMove xmlns="http://www.onvif.org/ver20/ptz/wsdl"><ProfileToken>testToken</ProfileToken><Velocity xmlns="http://www.onvif.org/ver20/ptz/wsdl"><PanTilt xmlns="http://www.onvif.org/ver10/schema" x="0.0" y="0.0"/><Zoom xmlns="http://www.onvif.org/ver10/schema" x="0.0"/></Velocity></ContinuousMove></Test>',
      );
    });
  });

  group('Recordings SOAP Requests', () {
    test('createRecording', () {
      builder.element(
        'Test',
        nest: RecordingsRequest.createRecording(
          RecordingConfiguration(
            source: RecordingSourceInformation(
              sourceId: 'testId',
              name: 'name',
              location: 'location',
              description: 'description',
              address: 'http://test.com',
            ),
            content: 'content',
            maximumRetentionTime: 'PT0S',
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><CreateRecording xmlns="http://www.onvif.org/ver10/recording/wsdl"><RecordingConfiguration xmlns="http://www.onvif.org/ver10/schema"><Source xmlns="http://www.onvif.org/ver10/schema"><SourceId>testId</SourceId><Name>name</Name><Location>location</Location><Description>description</Description><Address>http://test.com</Address></Source><Content>content</Content><MaximumRetentionTime>PT0S</MaximumRetentionTime></RecordingConfiguration></CreateRecording></Test>',
      );
    });

    test('createRecordingJob', () {
      builder.element(
        'Test',
        nest: RecordingsRequest.createRecordingJob(
          RecordingJobConfiguration(
            recordingToken: 'testToken',
            mode: RecordingJobConfigurationMode.idle,
            priority: 1,
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><CreateRecordingJob xmlns="http://www.onvif.org/ver10/recording/wsdl"><JobConfiguration xmlns="http://www.onvif.org/ver10/recording/wsdl"><RecordingToken xmlns="http://www.onvif.org/ver10/recording/wsdl">testToken</RecordingToken><Mode xmlns="http://www.onvif.org/ver10/recording/wsdl">Idle</Mode><Priority xmlns="http://www.onvif.org/ver10/recording/wsdl">1</Priority></JobConfiguration></CreateRecordingJob></Test>',
      );
    });

    test('deleteRecording', () {
      builder.element(
        'Test',
        nest: RecordingsRequest.deleteRecording('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><DeleteRecordingJob xmlns="http://www.onvif.org/ver10/recording/wsdl"><RecordingToken xmlns="http://www.onvif.org/ver10/schema">testToken</RecordingToken></DeleteRecordingJob></Test>',
      );
    });

    test('deleteRecordingJob', () {
      builder.element(
        'Test',
        nest: RecordingsRequest.deleteRecordingJob('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><DeleteRecordingJob xmlns="http://www.onvif.org/ver10/recording/wsdl"><JobToken xmlns="http://www.onvif.org/ver10/schema">testToken</JobToken></DeleteRecordingJob></Test>',
      );
    });

    test('getRecordingOptions', () {
      builder.element(
        'Test',
        nest: RecordingsRequest.getRecordingOptions(
          ReferenceToken('testToken'),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetRecordingOptions xmlns="http://www.onvif.org/ver10/recording/wsdl"><RecordingToken xmlns="http://www.onvif.org/ver10/schema">testToken</RecordingToken></GetRecordingOptions></Test>',
      );
    });

    test('getRecordings', () {
      builder.element('Test', nest: RecordingsRequest.getRecordings());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetRecordings xmlns="http://www.onvif.org/ver10/recording/wsdl"/></Test>',
      );
    });

    test('getRecordingJobs', () {
      builder.element('Test', nest: RecordingsRequest.getRecordingJobs());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetRecordingJobs xmlns="http://www.onvif.org/ver10/recording/wsdl"/></Test>',
      );
    });

    test('getRecordingJobState', () {
      builder.element(
        'Test',
        nest: RecordingsRequest.getRecordingJobState('testToken'),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetRecordingJobState xmlns="http://www.onvif.org/ver10/recording/wsdl"><JobToken xmlns="http://www.onvif.org/ver10/schema">testToken</JobToken></GetRecordingJobState></Test>',
      );
    });

    test('getServiceCapabilities', () {
      builder.element('Test', nest: RecordingsRequest.getServiceCapabilities());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetServiceCapabilities xmlns="http://www.onvif.org/ver10/recording/wsdl"/></Test>',
      );
    });

    test('setRecordingJobMode', () {
      builder.element(
        'Test',
        nest: RecordingsRequest.setRecordingJobMode(
          jobToken: 'testToken',
          mode: RecordingJobConfigurationMode.idle,
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetRecordingJobMode xmlns="http://www.onvif.org/ver10/recording/wsdl"><JobToken xmlns="http://www.onvif.org/ver10/schema">testToken</JobToken><Mode xmlns="http://www.onvif.org/ver10/schema">Idle</Mode></SetRecordingJobMode></Test>',
      );
    });
  });

  group('Replay SOAP Requests', () {
    test('getReplayConfiguration', () {
      builder.element('Test', nest: ReplayRequest.getReplayConfiguration());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetReplayConfiguration xmlns="http://www.onvif.org/ver10/replay/wsdl"/></Test>',
      );
    });

    test('getReplayUri', () {
      builder.element(
        'Test',
        nest: ReplayRequest.getReplayUri(
          'testToken',
          streamSetup: StreamSetup(
            stream: 'RTP-Multicast',
            transport: Transport(protocol: 'HTTP'),
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetReplayUri xmlns="http://www.onvif.org/ver10/replay/wsdl"><StreamSetup xmlns="http://www.onvif.org/ver10/media/wsdl"><Stream xmlns="http://www.onvif.org/ver10/schema">RTP-Multicast</Stream><Transport xmlns="http://www.onvif.org/ver10/schema"><Protocol xmlns="http://www.onvif.org/ver10/schema">HTTP</Protocol></Transport></StreamSetup><RecordingToken>testToken</RecordingToken></GetReplayUri></Test>',
      );
    });

    test('getServiceCapabilities', () {
      builder.element('Test', nest: ReplayRequest.getServiceCapabilities());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetServiceCapabilities xmlns="http://www.onvif.org/ver10/replay/wsdl"/></Test>',
      );
    });

    test('setReplayConfiguration', () {
      builder.element(
        'Test',
        nest: ReplayRequest.setReplayConfiguration(
          ReplayConfiguration(sessionTimeout: 'PT0S'),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetReplayConfiguration xmlns="http://www.onvif.org/ver10/replay/wsdl"><Configuration><SessionTimeout xmlns="http://www.onvif.org/ver10/schema">PT0S</SessionTimeout></Configuration></SetReplayConfiguration></Test>',
      );
    });
  });

  group('Device Management SOAP Requests', () {
    test('findRecordings', () {
      builder.element(
        'Test',
        nest: SearchRequest.findRecordings(
          searchScope: SearchScope(
            includedSources: [SourceToken(token: 'testToken')],
          ),
          keepAliveTime: 0,
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><FindRecordings xmlns="http://www.onvif.org/ver10/search/wsdl"><Scope xmlns="http://www.onvif.org/ver10/search/wsdl"><IncludedSources><SourceToken xmlns="http://www.onvif.org/ver10/schema"><Token xmlns="http://www.onvif.org/ver10/schema">testToken</Token></SourceToken></IncludedSources></Scope><KeepAliveTime>0</KeepAliveTime></FindRecordings></Test>',
      );
    });

    test('getRecordingSummary', () {
      builder.element('Test', nest: SearchRequest.getRecordingSummary());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetRecordingSummary xmlns="http://www.onvif.org/ver10/search/wsdl"/></Test>',
      );
    });

    test('getRecordingSearchResults', () {
      builder.element(
        'Test',
        nest: SearchRequest.getRecordingSearchResults(
          'testToken',
          maxResults: 5,
          minResults: 1,
          waitTime: 'PT0S',
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetRecordingSearchResults xmlns="http://www.onvif.org/ver10/search/wsdl"><SearchToken>testToken</SearchToken><MinResults>1</MinResults><MaxResults>5</MaxResults><WaitTime>PT0S</WaitTime></GetRecordingSearchResults></Test>',
      );
    });
  });
}
