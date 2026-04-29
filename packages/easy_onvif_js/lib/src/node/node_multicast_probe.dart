// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:easy_onvif/probe.dart';
import 'package:easy_onvif/soap.dart';
import 'package:loggy/loggy.dart';
import 'package:uuid/uuid.dart';

import '../interop/dgram.dart';

/// Node.js-native WS-Discovery probe.
///
/// Re-implements the parts of
/// `easy_onvif/lib/src/platform/multicast_probe_io.dart` that need sockets,
/// but does so through Node's `dgram` module via `dart:js_interop`. The XML
/// message construction continues to come from [WsDiscovery] and
/// [Envelope.fromXmlString] inside the pure-Dart `easy_onvif` library.
///
/// The browser ships a different class that simply throws
/// [UnsupportedError]; this file is only ever imported from the Node
/// entry point.
class NodeMulticastProbe with UiLoggy {
  NodeMulticastProbe({int? timeoutSeconds})
    : _timeout = Duration(seconds: timeoutSeconds ?? 2);

  static const _broadcastAddress = '239.255.255.250';
  static const _broadcastPort = 3702;

  final Duration _timeout;

  final List<ProbeMatch> _matches = <ProbeMatch>[];

  /// Returns the devices discovered during the most recent [probe] call.
  List<ProbeMatch> get matches => List.unmodifiable(_matches);

  /// Sends a WS-Discovery `Probe` message on the ONVIF multicast group and
  /// collects `ProbeMatches` responses for [_timeout].
  Future<void> probe() async {
    _matches.clear();

    final socket = createUdp4Socket();
    final completer = Completer<void>();

    final messageListener = ((JSUint8Array buffer, RemoteInfo rinfo) {
      try {
        final bytes = buffer.toDart;
        final xml = String.fromCharCodes(bytes);

        loggy.debug(
          'RESPONSE from ${rinfo.address.toDart}:${rinfo.port.toDartInt}:\n$xml',
        );

        final envelope = Envelope.fromXmlString(xml);
        final response = envelope.body.response;

        if (response == null) return;

        _matches.addAll(ProbeMatches.fromJson(response).probeMatches);
      } catch (e, st) {
        loggy.warning('Failed to parse discovery response: $e\n$st');
      }
    }).toJS;

    final errorListener = ((JSObject err) {
      final code = err.getProperty<JSAny?>('code'.toJS);
      final codeStr = code?.isA<JSString>() == true
          ? (code! as JSString).toDart
          : '';

      loggy.warning(
        'dgram socket error $codeStr (non-fatal, continuing probe): $err',
      );

      // EADDRINUSE is the only error from which we cannot recover at all.
      if (codeStr == 'EADDRINUSE' || codeStr == 'EACCES') {
        if (!completer.isCompleted) completer.completeError(err);
      }
    }).toJS;

    socket.on('message'.toJS, messageListener);
    socket.on('error'.toJS, errorListener);

    final listeningListener = (() {
      // Join the ONVIF multicast group so we receive `ProbeMatches`.
      try {
        socket.addMembership(_broadcastAddress.toJS);
      } catch (e) {
        loggy.warning('addMembership failed (non-fatal): $e');
      }

      _sendHello(socket);
      _sendProbe(socket);
    }).toJS;

    socket.on('listening'.toJS, listeningListener);

    // Bind to an ephemeral port; Node will emit 'listening' when ready.
    socket.bind();

    // Honor the timeout, then send Bye and close.
    final timer = Timer(_timeout, () async {
      try {
        _sendBye(socket);
      } catch (_) {
        /* best effort */
      }

      // Node's dgram `socket.close([callback])` invokes the callback with
      // zero arguments when it finishes. Under dart2js, a 1-arg closure
      // wrapped by `.toJS` only has a `call$1` signature, and the bridge
      // crashes with `call$0 is not a function` if JS calls it with 0
      // args. Use a 0-arg closure to match the real arity.
      socket.close(
        (() {
          if (!completer.isCompleted) completer.complete();
        }).toJS,
      );
    });

    try {
      await completer.future;
    } finally {
      if (timer.isActive) timer.cancel();
    }
  }

  void _sendHello(DgramSocket socket) {
    final xml = WsDiscovery.hello(
      messageNumber: 1,
      xAddrs: const <String>['http://0.0.0.0/onvif/device_service'],
    ).toXmlString();

    sendDatagram(
      socket,
      Uint8List.fromList(xml.codeUnits),
      _broadcastAddress,
      _broadcastPort,
    );
  }

  void _sendProbe(DgramSocket socket) {
    final xml = WsDiscovery.probe().toXmlString();

    sendDatagram(
      socket,
      Uint8List.fromList(xml.codeUnits),
      _broadcastAddress,
      _broadcastPort,
    );
  }

  void _sendBye(DgramSocket socket) {
    final uuid = const Uuid().v4();

    final xml = WsDiscovery.bye(messageId: uuid, address: uuid).toXmlString();

    sendDatagram(
      socket,
      Uint8List.fromList(xml.codeUnits),
      _broadcastAddress,
      _broadcastPort,
    );
  }
}
