import 'dart:async';
import 'dart:io';

import 'package:loggy/loggy.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../config.dart';

/// A WS-Discovery (ONVIF device discovery) responder.
///
/// Joins the WS-Discovery multicast group (`239.255.255.250:3702`) and answers
/// `Probe` messages with a unicast `ProbeMatches` that advertises the device's
/// `device_service` endpoint, so the `easy_onvif` client's `probe()` can find
/// this server.
class WsDiscoveryServer with UiLoggy {
  static final InternetAddress multicastGroup = InternetAddress(
    '239.255.255.250',
  );

  final ServerConfig config;

  /// The host address advertised in `XAddrs`. When `null`, the first
  /// non-loopback IPv4 address is used.
  final String? advertisedHost;

  RawDatagramSocket? _socket;

  String? _resolvedHost;

  WsDiscoveryServer({required this.config, this.advertisedHost});

  bool get isRunning => _socket != null;

  Future<void> start() async {
    if (_socket != null) return;

    _resolvedHost = advertisedHost ?? await _resolveHost();

    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      config.discoveryPort,
      reuseAddress: true,
    );

    socket.joinMulticast(multicastGroup);
    socket.multicastLoopback = true;

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();

        if (datagram != null) _handleDatagram(socket, datagram);
      }
    });

    _socket = socket;

    loggy.info(
      'WS-Discovery responder listening on port ${config.discoveryPort} '
      '(advertising $_resolvedHost)',
    );
  }

  void _handleDatagram(RawDatagramSocket socket, Datagram datagram) {
    final message = String.fromCharCodes(datagram.data);

    if (!_isProbe(message)) return;

    loggy.debug('WS-Discovery probe from ${datagram.address.address}');

    final response = _buildProbeMatches();

    try {
      socket.send(response.codeUnits, datagram.address, datagram.port);
    } on SocketException catch (error) {
      // A failed reply (e.g. sandbox restrictions or an unreachable peer)
      // should not take down the responder.
      loggy.debug('WS-Discovery reply failed: $error');
    }
  }

  /// Returns `true` if [message] is a WS-Discovery `Probe` (and not a
  /// `ProbeMatches` or other discovery message).
  bool _isProbe(String message) {
    try {
      final document = XmlDocument.parse(message);

      final body = document
          .findAllElements(
            'Body',
            namespaceUri: 'http://www.w3.org/2003/05/soap-envelope',
          )
          .firstOrNull;

      final operation = body?.childElements.firstOrNull;

      return operation?.localName == 'Probe';
    } catch (_) {
      return false;
    }
  }

  String _buildProbeMatches() {
    final host = _resolvedHost ?? '127.0.0.1';
    final xAddr = config.deviceServiceUrl(host);

    final builder = XmlBuilder();

    builder.declaration(encoding: 'UTF-8');

    builder.element(
      'Envelope',
      namespaceUri: 'http://www.w3.org/2003/05/soap-envelope',
      namespaceUris: {
        's': 'http://www.w3.org/2003/05/soap-envelope',
        'a': 'http://schemas.xmlsoap.org/ws/2004/08/addressing',
        'd': 'http://schemas.xmlsoap.org/ws/2005/04/discovery',
        'dn': 'http://www.onvif.org/ver10/network/wsdl',
        'tds': 'http://www.onvif.org/ver10/device/wsdl',
      },
      nest: () {
        builder.element(
          'Header',
          namespaceUri: 'http://www.w3.org/2003/05/soap-envelope',
          nest: () {
            builder.element(
              'Action',
              namespaceUri: 'http://schemas.xmlsoap.org/ws/2004/08/addressing',
              nest:
                  'http://schemas.xmlsoap.org/ws/2005/04/discovery/'
                  'ProbeMatches',
            );
            builder.element(
              'MessageID',
              namespaceUri: 'http://schemas.xmlsoap.org/ws/2004/08/addressing',
              nest: 'uuid:${const Uuid().v4()}',
            );
          },
        );

        builder.element(
          'Body',
          namespaceUri: 'http://www.w3.org/2003/05/soap-envelope',
          nest: () {
            builder.element(
              'ProbeMatches',
              namespaceUri: 'http://schemas.xmlsoap.org/ws/2005/04/discovery',
              nest: () {
                builder.element(
                  'ProbeMatch',
                  namespaceUri: 'http://schemas.xmlsoap.org/ws/2005/04/discovery',
                  nest: () {
                    builder.element(
                      'EndpointReference',
                      namespaceUri:
                          'http://schemas.xmlsoap.org/ws/2004/08/addressing',
                      nest: () {
                        builder.element(
                          'Address',
                          namespaceUri:
                              'http://schemas.xmlsoap.org/ws/2004/08/addressing',
                          nest: 'urn:uuid:${config.endpointUuid}',
                        );
                      },
                    );
                    builder.element(
                      'Types',
                      namespaceUri:
                          'http://schemas.xmlsoap.org/ws/2005/04/discovery',
                      nest: 'dn:NetworkVideoTransmitter tds:Device',
                    );
                    builder.element(
                      'Scopes',
                      namespaceUri:
                          'http://schemas.xmlsoap.org/ws/2005/04/discovery',
                      nest:
                          'onvif://www.onvif.org/location/country/US '
                          'onvif://www.onvif.org/name/${config.hostname} '
                          'onvif://www.onvif.org/hardware/${config.model}',
                    );
                    builder.element(
                      'XAddrs',
                      namespaceUri:
                          'http://schemas.xmlsoap.org/ws/2005/04/discovery',
                      nest: xAddr,
                    );
                    builder.element(
                      'MetadataVersion',
                      namespaceUri:
                          'http://schemas.xmlsoap.org/ws/2005/04/discovery',
                      nest: '1',
                    );
                  },
                );
              },
            );
          },
        );
      },
    );

    return builder.buildDocument().toXmlString();
  }

  Future<String> _resolveHost() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) return address.address;
        }
      }
    } catch (_) {
      // Fall through to the loopback default.
    }

    return '127.0.0.1';
  }

  Future<void> stop() async {
    final socket = _socket;

    if (socket != null) {
      try {
        socket.leaveMulticast(multicastGroup);
      } catch (_) {
        // Ignore errors leaving the group on shutdown.
      }
      socket.close();
    }

    _socket = null;
  }
}
