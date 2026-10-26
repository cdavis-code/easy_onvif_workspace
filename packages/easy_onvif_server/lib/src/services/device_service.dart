import 'dart:io';

import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

import '../config.dart';
import '../hardware/device_state.dart';
import '../hardware/hardware_adapter.dart';
import '../settings.dart';
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
  final ServerSettings settings;

  /// Supplies the buffered device log lines for `GetSystemLog` (wired to the
  /// device's `BufferedLoggyPrinter` by `OnvifDevice`).
  final List<String> Function() logLines;

  /// The resolved recordings directory reported by the storage configuration
  /// operations (supplied by `OnvifDevice` so it matches the recording store).
  final String? recordingDirectory;

  DeviceService({
    required this.config,
    required this.state,
    required this.hardware,
    this.settings = const ServerSettings(),
    this.logLines = _noLogLines,
    this.recordingDirectory,
  });

  static List<String> _noLogLines() => const [];

  @override
  bool handles(String namespace) => namespace == Xmlns.tds;

  /// Operations that do not require WS-Security authentication.
  ///
  /// `GetIPAddressFilter` is listed because the `easy_onvif` client sends it
  /// without a WS-Security header (it uses the unsecured request path).
  static const preAuthOperations = {
    'GetSystemDateAndTime',
    'GetCapabilities',
    'GetServices',
    'GetHostname',
    'GetServiceCapabilities',
    'GetIPAddressFilter',
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
      case 'GetSystemLog':
        return _getSystemLog(ctx);
      case 'GetSystemSupportInformation':
        return _getSystemSupportInformation();
      case 'GetEndpointReference':
        return _getEndpointReference();
      case 'GetIPAddressFilter':
        return _getIpAddressFilter();
      case 'GetStorageConfigurations':
        return _getStorageConfigurations();
      case 'GetStorageConfiguration':
        return _getStorageConfiguration(ctx);
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
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'SystemDateAndTime',
            namespaceUri: Xmlns.tds,
            nest: () {
              b.element('DateTimeType', namespaceUri: Xmlns.tt, nest: 'NTP');
              b.element('DaylightSavings', namespaceUri: Xmlns.tt, nest: 'false');
              b.element(
                'TimeZone',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element('TZ', namespaceUri: Xmlns.tt, nest: 'UTC0');
                },
              );
              b.element(
                'UTCDateTime',
                namespaceUri: Xmlns.tt,
                nest: () {
                  _writeTime(b, now);
                  _writeDate(b, now);
                },
              );
              b.element(
                'LocalDateTime',
                namespaceUri: Xmlns.tt,
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
      if (settings.services.imaging)
        (Xmlns.timg, config.imagingServiceUrl(host)),
      if (settings.services.recording)
        (Xmlns.trc, config.recordingServiceUrl(host)),
      if (settings.services.search) (Xmlns.tse, config.searchServiceUrl(host)),
      if (settings.services.replay) (Xmlns.trp, config.replayServiceUrl(host)),
    ];

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetServicesResponse',
        namespaceUri: Xmlns.tds,
        nest: () {
          for (final (namespace, xAddr) in services) {
            b.element(
              'Service',
              namespaceUri: Xmlns.tds,
              nest: () {
                b.element('Namespace', namespaceUri: Xmlns.tds, nest: namespace);
                b.element('XAddr', namespaceUri: Xmlns.tds, nest: xAddr);
                b.element(
                  'Version',
                  namespaceUri: Xmlns.tds,
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
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'Capabilities',
            namespaceUri: Xmlns.tds,
            nest: () {
              b.element(
                'Device',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element(
                    'XAddr',
                    namespaceUri: Xmlns.tt,
                    nest: config.deviceServiceUrl(host),
                  );
                },
              );
              b.element(
                'Media',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element(
                    'XAddr',
                    namespaceUri: Xmlns.tt,
                    nest: config.mediaServiceUrl(host),
                  );
                  b.element(
                    'StreamingCapabilities',
                    namespaceUri: Xmlns.tt,
                    nest: () {
                      b.element(
                        'RTPMulticast',
                        namespaceUri: Xmlns.tt,
                        nest: 'true',
                      );
                      b.element('RTP_TCP', namespaceUri: Xmlns.tt, nest: 'true');
                      b.element(
                        'RTP_RTSP_TCP',
                        namespaceUri: Xmlns.tt,
                        nest: 'true',
                      );
                    },
                  );
                },
              );
              b.element(
                'PTZ',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element(
                    'XAddr',
                    namespaceUri: Xmlns.tt,
                    nest: config.ptzServiceUrl(host),
                  );
                },
              );
              if (settings.services.imaging) {
                b.element(
                  'Imaging',
                  namespaceUri: Xmlns.tt,
                  nest: () {
                    b.element(
                      'XAddr',
                      namespaceUri: Xmlns.tt,
                      nest: config.imagingServiceUrl(host),
                    );
                  },
                );
              }
              if (settings.services.recording ||
                  settings.services.search ||
                  settings.services.replay) {
                b.element(
                  'Extension',
                  namespaceUri: Xmlns.tt,
                  nest: () => _writeCapabilityExtension(b, host),
                );
              }
            },
          );
        },
      );
    });
  }

  /// Writes the Recording/Search/Replay capability entries nested under
  /// `tt:Extension` (the shape the ENP1A14 fixture uses).
  void _writeCapabilityExtension(XmlBuilder b, String host) {
    if (settings.services.recording) {
      b.element(
        'Recording',
        namespaceUri: Xmlns.tt,
        nest: () {
          b.element(
            'XAddr',
            namespaceUri: Xmlns.tt,
            nest: config.recordingServiceUrl(host),
          );
          b.element('ReceiverSource', namespaceUri: Xmlns.tt, nest: 'false');
          b.element('MediaProfileSource', namespaceUri: Xmlns.tt, nest: 'true');
          b.element('DynamicRecordings', namespaceUri: Xmlns.tt, nest: 'true');
          b.element('DynamicTracks', namespaceUri: Xmlns.tt, nest: 'false');
          b.element('MaxStringLength', namespaceUri: Xmlns.tt, nest: '256');
        },
      );
    }
    if (settings.services.search) {
      b.element(
        'Search',
        namespaceUri: Xmlns.tt,
        nest: () {
          b.element(
            'XAddr',
            namespaceUri: Xmlns.tt,
            nest: config.searchServiceUrl(host),
          );
          b.element('MetadataSearch', namespaceUri: Xmlns.tt, nest: 'false');
        },
      );
    }
    if (settings.services.replay) {
      b.element(
        'Replay',
        namespaceUri: Xmlns.tt,
        nest: () {
          b.element(
            'XAddr',
            namespaceUri: Xmlns.tt,
            nest: config.replayServiceUrl(host),
          );
        },
      );
    }
  }

  String _getDeviceInformation() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetDeviceInformationResponse',
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'Manufacturer',
            namespaceUri: Xmlns.tds,
            nest: config.manufacturer,
          );
          b.element('Model', namespaceUri: Xmlns.tds, nest: config.model);
          b.element(
            'FirmwareVersion',
            namespaceUri: Xmlns.tds,
            nest: config.firmwareVersion,
          );
          b.element(
            'SerialNumber',
            namespaceUri: Xmlns.tds,
            nest: config.serialNumber,
          );
          b.element(
            'HardwareId',
            namespaceUri: Xmlns.tds,
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
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'HostnameInformation',
            namespaceUri: Xmlns.tds,
            nest: () {
              b.element('FromDHCP', namespaceUri: Xmlns.tt, nest: 'false');
              b.element('Name', namespaceUri: Xmlns.tt, nest: config.hostname);
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
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'Capabilities',
            namespaceUri: Xmlns.tds,
            nest: () {
              b.element(
                'Network',
                namespaceUri: Xmlns.tt,
                attributes: {
                  'IPFilter': 'false',
                  'ZeroConfiguration': 'false',
                  'IPVersion6': 'false',
                  'DynDNS': 'false',
                },
              );
              b.element(
                'Security',
                namespaceUri: Xmlns.tt,
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
                namespaceUri: Xmlns.tt,
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
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'DiscoveryMode',
            namespaceUri: Xmlns.tds,
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
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'NetworkProtocols',
            namespaceUri: Xmlns.tds,
            nest: () {
              b.element('Name', namespaceUri: Xmlns.tt, nest: 'HTTP');
              b.element('Enabled', namespaceUri: Xmlns.tt, nest: 'true');
              b.element(
                'Port',
                namespaceUri: Xmlns.tt,
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
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'DNSInformation',
            namespaceUri: Xmlns.tds,
            nest: () {
              b.element('FromDHCP', namespaceUri: Xmlns.tt, nest: 'false');
              b.element('SearchDomain', namespaceUri: Xmlns.tt, nest: 'local');
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
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'NTPInformation',
            namespaceUri: Xmlns.tds,
            nest: () {
              b.element('FromDHCP', namespaceUri: Xmlns.tt, nest: 'false');
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
        namespaceUri: Xmlns.tds,
        nest: () {
          for (final user in state.users) {
            b.element(
              'User',
              namespaceUri: Xmlns.tds,
              nest: () {
                b.element('Username', namespaceUri: Xmlns.tt, nest: user.username);
                b.element('UserLevel', namespaceUri: Xmlns.tt, nest: user.level);
              },
            );
          }
        },
      );
    });
  }

  String _getSystemUris() {
    return SoapEnvelopeBuilder.response((b) {
      b.element('GetSystemUrisResponse', namespaceUri: Xmlns.tds, nest: () {});
    });
  }

  String _getSystemLog(RequestContext ctx) {
    final logType = ctx.param('LogType') ?? 'System';
    final lines = logLines();
    final text = lines.isEmpty
        ? 'No $logType log entries recorded.'
        : '=== $logType log ===\n${lines.join('\n')}';

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetSystemLogResponse',
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'SystemLog',
            namespaceUri: Xmlns.tds,
            nest: () {
              b.element('String', namespaceUri: Xmlns.tt, nest: text);
            },
          );
        },
      );
    });
  }

  String _getSystemSupportInformation() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetSystemSupportInformationResponse',
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'SupportInformation',
            namespaceUri: Xmlns.tds,
            nest: () {
              b.element(
                'String',
                namespaceUri: Xmlns.tt,
                nest:
                    'OS: ${Platform.operatingSystemVersion}\n'
                    'Dart: ${Platform.version}',
              );
            },
          );
        },
      );
    });
  }

  String _getEndpointReference() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetEndpointReferenceResponse',
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element('GUID', namespaceUri: Xmlns.tds, nest: config.endpointUuid);
        },
      );
    });
  }

  String _getIpAddressFilter() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetIPAddressFilterResponse',
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'IPAddressFilter',
            namespaceUri: Xmlns.tds,
            nest: () {
              b.element('Type', namespaceUri: Xmlns.tt, nest: 'Allow');
            },
          );
        },
      );
    });
  }

  /// The directory recordings are (or would be) written to; reported by the
  /// storage configuration operations.
  String get _recordingDirectory =>
      recordingDirectory ??
      settings.recordingDirectory ??
      '${Directory.systemTemp.path}/easy_onvif_recordings';

  /// The token of the single (simulated) storage configuration.
  static const _storageToken = 'StorageToken_1';

  void _writeStorageConfiguration(XmlBuilder b, {required String element}) {
    b.element(
      element,
      namespaceUri: Xmlns.tds,
      attributes: {'token': _storageToken},
      nest: () {
        b.element(
          'Data',
          namespaceUri: Xmlns.tds,
          attributes: {'type': 'Local'},
          nest: () {
            b.element(
              'LocalPath',
              namespaceUri: Xmlns.tds,
              nest: _recordingDirectory,
            );
          },
        );
      },
    );
  }

  String _getStorageConfigurations() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetStorageConfigurationsResponse',
        namespaceUri: Xmlns.tds,
        nest: () =>
            _writeStorageConfiguration(b, element: 'StorageConfigurations'),
      );
    });
  }

  String _getStorageConfiguration(RequestContext ctx) {
    final token = ctx.param('Token');

    if (token != null && token != _storageToken) {
      return SoapEnvelopeBuilder.fault(
        subcode: 'NoConfig',
        reason: 'No storage configuration exists for token "$token".',
      );
    }

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetStorageConfigurationResponse',
        namespaceUri: Xmlns.tds,
        nest: () =>
            _writeStorageConfiguration(b, element: 'StorageConfiguration'),
      );
    });
  }

  Future<String> _getGeoLocation() async {
    // Prefer a real platform fix; fall back to the configured location.
    final location = await hardware.currentLocation() ?? settings.geoFallback;

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetGeoLocationResponse',
        namespaceUri: Xmlns.tds,
        nest: () {
          if (location != null) {
            b.element(
              'Location',
              namespaceUri: Xmlns.tds,
              nest: () {
                b.element(
                  'Location',
                  namespaceUri: Xmlns.tt,
                  nest: () {
                    b.element(
                      'lat',
                      namespaceUri: Xmlns.tt,
                      nest: location.latitude.toString(),
                    );
                    b.element(
                      'lon',
                      namespaceUri: Xmlns.tt,
                      nest: location.longitude.toString(),
                    );
                    if (location.elevation != null) {
                      b.element(
                        'elevation',
                        namespaceUri: Xmlns.tt,
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
      b.element('CreateUsersResponse', namespaceUri: Xmlns.tds, nest: () {});
    });
  }

  String _deleteUsers(RequestContext ctx) {
    final usernames = ctx
        .params('Username')
        .map((e) => e.innerText.trim())
        .toSet();

    state.users.removeWhere((user) => usernames.contains(user.username));

    return SoapEnvelopeBuilder.response((b) {
      b.element('DeleteUsersResponse', namespaceUri: Xmlns.tds, nest: () {});
    });
  }

  String _systemReboot() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'SystemRebootResponse',
        namespaceUri: Xmlns.tds,
        nest: () {
          b.element(
            'Message',
            namespaceUri: Xmlns.tds,
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
      namespaceUri: Xmlns.tt,
      nest: () {
        b.element('Hour', namespaceUri: Xmlns.tt, nest: '${dt.hour}');
        b.element('Minute', namespaceUri: Xmlns.tt, nest: '${dt.minute}');
        b.element('Second', namespaceUri: Xmlns.tt, nest: '${dt.second}');
      },
    );
  }

  void _writeDate(XmlBuilder b, DateTime dt) {
    b.element(
      'Date',
      namespaceUri: Xmlns.tt,
      nest: () {
        b.element('Year', namespaceUri: Xmlns.tt, nest: '${dt.year}');
        b.element('Month', namespaceUri: Xmlns.tt, nest: '${dt.month}');
        b.element('Day', namespaceUri: Xmlns.tt, nest: '${dt.day}');
      },
    );
  }

  void _writeVersion(XmlBuilder b, {int major = 2, int minor = 60}) {
    b.element('Major', namespaceUri: Xmlns.tt, nest: '$major');
    b.element('Minor', namespaceUri: Xmlns.tt, nest: '$minor');
  }

  static String? _childText(XmlElement parent, String localName) {
    for (final child in parent.childElements) {
      if (child.localName == localName) return child.innerText.trim();
    }

    return null;
  }
}
