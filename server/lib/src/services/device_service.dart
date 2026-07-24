import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

import '../config.dart';
import '../hardware/device_state.dart';
import '../hardware/hardware_adapter.dart';
import '../soap/envelope_builder.dart';
import '../soap/request_context.dart';
import 'onvif_service.dart';

/// Implements the ONVIF device management service (`tds` namespace).
///
/// This is the entry point service the `easy_onvif` client uses during
/// `Onvif.connect()` (GetSystemDateAndTime, GetServices/GetCapabilities) and
/// for device introspection.
class DeviceService implements OnvifService {
  final ServerConfig config;
  final DeviceState state;
  final HardwareAdapter hardware;

  DeviceService({
    required this.config,
    required this.state,
    required this.hardware,
  });

  @override
  bool handles(String namespace) => namespace == Xmlns.tds;

  /// Operations that do not require WS-Security authentication.
  static const preAuthOperations = {
    'GetSystemDateAndTime',
    'GetCapabilities',
    'GetServices',
    'GetHostname',
    'GetServiceCapabilities',
  };

  @override
  bool isPreAuth(String operation) => preAuthOperations.contains(operation);

  @override
  Future<String> handle(RequestContext ctx, {required String host}) async {
    switch (ctx.operation) {
      case 'GetSystemDateAndTime':
        return _getSystemDateAndTime();
      case 'GetServices':
        return _getServices(host);
      case 'GetCapabilities':
        return _getCapabilities(host);
      case 'GetDeviceInformation':
        return _getDeviceInformation();
      case 'GetHostname':
        return _getHostname();
      case 'GetServiceCapabilities':
        return _getServiceCapabilities();
      case 'GetDiscoveryMode':
        return _getDiscoveryMode();
      case 'GetNetworkProtocols':
        return _getNetworkProtocols();
      case 'GetDNS':
        return _getDns();
      case 'GetNTP':
        return _getNtp();
      case 'GetUsers':
        return _getUsers();
      case 'GetSystemUris':
        return _getSystemUris();
      case 'GetGeoLocation':
        return _getGeoLocation();
      case 'CreateUsers':
        return _createUsers(ctx);
      case 'DeleteUsers':
        return _deleteUsers(ctx);
      case 'SystemReboot':
        return _systemReboot();
      default:
        return SoapEnvelopeBuilder.fault(
          subcode: 'ActionNotSupported',
          reason: 'The requested action is not supported by this device.',
        );
    }
  }

  // ── Responses ────────────────────────────────────────────────────────────

  String _getSystemDateAndTime() {
    final now = DateTime.now().toUtc();

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetSystemDateAndTimeResponse',
        namespace: Xmlns.tds,
        nest: () {
          b.element(
            'SystemDateAndTime',
            namespace: Xmlns.tds,
            nest: () {
              b.element('DateTimeType', namespace: Xmlns.tt, nest: 'NTP');
              b.element('DaylightSavings', namespace: Xmlns.tt, nest: 'false');
              b.element(
                'TimeZone',
                namespace: Xmlns.tt,
                nest: () {
                  b.element('TZ', namespace: Xmlns.tt, nest: 'UTC0');
                },
              );
              b.element(
                'UTCDateTime',
                namespace: Xmlns.tt,
                nest: () {
                  _writeTime(b, now);
                  _writeDate(b, now);
                },
              );
              b.element(
                'LocalDateTime',
                namespace: Xmlns.tt,
                nest: () {
                  _writeTime(b, now);
                  _writeDate(b, now);
                },
              );
            },
          );
        },
      );
    });
  }

  String _getServices(String host) {
    final services = <(String, String)>[
      (Xmlns.tds, config.deviceServiceUrl(host)),
      (Xmlns.trt, config.mediaServiceUrl(host)),
      (Xmlns.tr2, config.media2ServiceUrl(host)),
      (Xmlns.tptz, config.ptzServiceUrl(host)),
    ];

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetServicesResponse',
        namespace: Xmlns.tds,
        nest: () {
          for (final (namespace, xAddr) in services) {
            b.element(
              'Service',
              namespace: Xmlns.tds,
              nest: () {
                b.element('Namespace', namespace: Xmlns.tds, nest: namespace);
                b.element('XAddr', namespace: Xmlns.tds, nest: xAddr);
                b.element(
                  'Version',
                  namespace: Xmlns.tds,
                  nest: () {
                    _writeVersion(b);
                  },
                );
              },
            );
          }
        },
      );
    });
  }

  String _getCapabilities(String host) {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetCapabilitiesResponse',
        namespace: Xmlns.tds,
        nest: () {
          b.element(
            'Capabilities',
            namespace: Xmlns.tds,
            nest: () {
              b.element(
                'Device',
                namespace: Xmlns.tt,
                nest: () {
                  b.element(
                    'XAddr',
                    namespace: Xmlns.tt,
                    nest: config.deviceServiceUrl(host),
                  );
                },
              );
              b.element(
                'Media',
                namespace: Xmlns.tt,
                nest: () {
                  b.element(
                    'XAddr',
                    namespace: Xmlns.tt,
                    nest: config.mediaServiceUrl(host),
                  );
                  b.element(
                    'StreamingCapabilities',
                    namespace: Xmlns.tt,
                    nest: () {
                      b.element(
                        'RTPMulticast',
                        namespace: Xmlns.tt,
                        nest: 'true',
                      );
                      b.element('RTP_TCP', namespace: Xmlns.tt, nest: 'true');
                      b.element(
                        'RTP_RTSP_TCP',
                        namespace: Xmlns.tt,
                        nest: 'true',
                      );
                    },
                  );
                },
              );
              b.element(
                'PTZ',
                namespace: Xmlns.tt,
                nest: () {
                  b.element(
                    'XAddr',
                    namespace: Xmlns.tt,
                    nest: config.ptzServiceUrl(host),
                  );
                },
              );
            },
          );
        },
      );
    });
  }

  String _getDeviceInformation() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetDeviceInformationResponse',
        namespace: Xmlns.tds,
        nest: () {
          b.element(
            'Manufacturer',
            namespace: Xmlns.tds,
            nest: config.manufacturer,
          );
          b.element('Model', namespace: Xmlns.tds, nest: config.model);
          b.element(
            'FirmwareVersion',
            namespace: Xmlns.tds,
            nest: config.firmwareVersion,
          );
          b.element(
            'SerialNumber',
            namespace: Xmlns.tds,
            nest: config.serialNumber,
          );
          b.element(
            'HardwareId',
            namespace: Xmlns.tds,
            nest: config.hardwareId,
          );
        },
      );
    });
  }

  String _getHostname() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetHostnameResponse',
        namespace: Xmlns.tds,
        nest: () {
          b.element(
            'HostnameInformation',
            namespace: Xmlns.tds,
            nest: () {
              b.element('FromDHCP', namespace: Xmlns.tt, nest: 'false');
              b.element('Name', namespace: Xmlns.tt, nest: config.hostname);
            },
          );
        },
      );
    });
  }

  String _getServiceCapabilities() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetServiceCapabilitiesResponse',
        namespace: Xmlns.tds,
        nest: () {
          b.element(
            'Capabilities',
            namespace: Xmlns.tds,
            nest: () {
              b.element(
                'Network',
                namespace: Xmlns.tt,
                attributes: {
                  'IPFilter': 'false',
                  'ZeroConfiguration': 'false',
                  'IPVersion6': 'false',
                  'DynDNS': 'false',
                },
              );
              b.element(
                'Security',
                namespace: Xmlns.tt,
                attributes: {
                  'TLS1.1': 'false',
                  'TLS1.2': 'false',
                  'OnboardKeyGeneration': 'false',
                  'AccessPolicyConfig': 'false',
                  'X.509Token': 'false',
                  'SAMLToken': 'false',
                  'KerberosToken': 'false',
                  'RELToken': 'false',
                },
              );
              b.element(
                'System',
                namespace: Xmlns.tt,
                attributes: {
                  'DiscoveryResolve': 'false',
                  'DiscoveryBye': 'true',
                  'RemoteDiscovery': 'false',
                  'SystemBackup': 'false',
                  'SystemLogging': 'false',
                  'FirmwareUpgrade': 'false',
                },
              );
            },
          );
        },
      );
    });
  }

  String _getDiscoveryMode() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetDiscoveryModeResponse',
        namespace: Xmlns.tds,
        nest: () {
          b.element(
            'DiscoveryMode',
            namespace: Xmlns.tds,
            nest: 'Discoverable',
          );
        },
      );
    });
  }

  String _getNetworkProtocols() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetNetworkProtocolsResponse',
        namespace: Xmlns.tds,
        nest: () {
          b.element(
            'NetworkProtocols',
            namespace: Xmlns.tds,
            nest: () {
              b.element('Name', namespace: Xmlns.tt, nest: 'HTTP');
              b.element('Enabled', namespace: Xmlns.tt, nest: 'true');
              b.element(
                'Port',
                namespace: Xmlns.tt,
                nest: '${config.httpPort}',
              );
            },
          );
        },
      );
    });
  }

  String _getDns() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetDNSResponse',
        namespace: Xmlns.tds,
        nest: () {
          b.element(
            'DNSInformation',
            namespace: Xmlns.tds,
            nest: () {
              b.element('FromDHCP', namespace: Xmlns.tt, nest: 'false');
              b.element('SearchDomain', namespace: Xmlns.tt, nest: 'local');
            },
          );
        },
      );
    });
  }

  String _getNtp() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetNTPResponse',
        namespace: Xmlns.tds,
        nest: () {
          b.element(
            'NTPInformation',
            namespace: Xmlns.tds,
            nest: () {
              b.element('FromDHCP', namespace: Xmlns.tt, nest: 'false');
            },
          );
        },
      );
    });
  }

  String _getUsers() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetUsersResponse',
        namespace: Xmlns.tds,
        nest: () {
          for (final user in state.users) {
            b.element(
              'User',
              namespace: Xmlns.tds,
              nest: () {
                b.element('Username', namespace: Xmlns.tt, nest: user.username);
                b.element('UserLevel', namespace: Xmlns.tt, nest: user.level);
              },
            );
          }
        },
      );
    });
  }

  String _getSystemUris() {
    return SoapEnvelopeBuilder.response((b) {
      b.element('GetSystemUrisResponse', namespace: Xmlns.tds, nest: () {});
    });
  }

  Future<String> _getGeoLocation() async {
    final location = await hardware.currentLocation();

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetGeoLocationResponse',
        namespace: Xmlns.tds,
        nest: () {
          if (location != null) {
            b.element(
              'Location',
              namespace: Xmlns.tds,
              nest: () {
                b.element(
                  'Location',
                  namespace: Xmlns.tt,
                  nest: () {
                    b.element(
                      'lat',
                      namespace: Xmlns.tt,
                      nest: location.latitude.toString(),
                    );
                    b.element(
                      'lon',
                      namespace: Xmlns.tt,
                      nest: location.longitude.toString(),
                    );
                    if (location.elevation != null) {
                      b.element(
                        'elevation',
                        namespace: Xmlns.tt,
                        nest: location.elevation.toString(),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      );
    });
  }

  String _createUsers(RequestContext ctx) {
    for (final userElement in ctx.params('User')) {
      final username = _childText(userElement, 'Username');
      final password = _childText(userElement, 'Password');
      final level = _childText(userElement, 'UserLevel') ?? 'User';

      if (username != null) {
        state.users.add(
          OnvifUser(username: username, password: password ?? '', level: level),
        );
      }
    }

    return SoapEnvelopeBuilder.response((b) {
      b.element('CreateUsersResponse', namespace: Xmlns.tds, nest: () {});
    });
  }

  String _deleteUsers(RequestContext ctx) {
    final usernames = ctx
        .params('Username')
        .map((e) => e.innerText.trim())
        .toSet();

    state.users.removeWhere((user) => usernames.contains(user.username));

    return SoapEnvelopeBuilder.response((b) {
      b.element('DeleteUsersResponse', namespace: Xmlns.tds, nest: () {});
    });
  }

  String _systemReboot() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'SystemRebootResponse',
        namespace: Xmlns.tds,
        nest: () {
          b.element(
            'Message',
            namespace: Xmlns.tds,
            nest: 'Rebooting (simulated).',
          );
        },
      );
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _writeTime(XmlBuilder b, DateTime dt) {
    b.element(
      'Time',
      namespace: Xmlns.tt,
      nest: () {
        b.element('Hour', namespace: Xmlns.tt, nest: '${dt.hour}');
        b.element('Minute', namespace: Xmlns.tt, nest: '${dt.minute}');
        b.element('Second', namespace: Xmlns.tt, nest: '${dt.second}');
      },
    );
  }

  void _writeDate(XmlBuilder b, DateTime dt) {
    b.element(
      'Date',
      namespace: Xmlns.tt,
      nest: () {
        b.element('Year', namespace: Xmlns.tt, nest: '${dt.year}');
        b.element('Month', namespace: Xmlns.tt, nest: '${dt.month}');
        b.element('Day', namespace: Xmlns.tt, nest: '${dt.day}');
      },
    );
  }

  void _writeVersion(XmlBuilder b, {int major = 2, int minor = 60}) {
    b.element('Major', namespace: Xmlns.tt, nest: '$major');
    b.element('Minor', namespace: Xmlns.tt, nest: '$minor');
  }

  static String? _childText(XmlElement parent, String localName) {
    for (final child in parent.childElements) {
      if (child.localName == localName) return child.innerText.trim();
    }

    return null;
  }
}
