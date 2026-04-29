// ignore_for_file: non_constant_identifier_names

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'js_globals.dart';

/// Lazily-loaded reference to Node's `dgram` module.
JSObject? _dgramCache;

JSObject _dgram() => _dgramCache ??= nodeRequire('dgram');

/// Thin wrapper around Node's `dgram.Socket`.
///
/// Exposes only the subset of the API surface needed by ONVIF WS-Discovery:
/// `bind`, `addMembership`, `send`, `close`, and the `'message'` /
/// `'error'` events.
extension type DgramSocket._(JSObject _raw) implements JSObject {
  external void bind([JSNumber? port]);

  external void addMembership(JSString multicastAddr);

  external void send(
    JSUint8Array msg,
    JSNumber port,
    JSString address, [
    JSFunction? callback,
  ]);

  external void on(JSString event, JSFunction listener);

  external void close([JSFunction? callback]);

  external DgramAddress address();
}

/// The object returned by `dgram.Socket.address()`.
extension type DgramAddress._(JSObject _raw) implements JSObject {
  external JSString get address;
  external JSNumber get port;
  external JSString get family;
}

/// The `rinfo` object passed to the `'message'` event listener.
extension type RemoteInfo._(JSObject _raw) implements JSObject {
  external JSString get address;
  external JSNumber get port;
  external JSString get family;
  external JSNumber get size;
}

/// Creates a `udp4` datagram socket.
DgramSocket createUdp4Socket() {
  final factory = _dgram().getProperty<JSFunction>('createSocket'.toJS);

  return factory.callAsFunction(_dgram(), 'udp4'.toJS) as DgramSocket;
}

/// Sends [bytes] as a single UDP datagram to [address]:[port].
///
/// Returns immediately; the [socket]'s write callback reports completion
/// via its [JSFunction] argument, which callers may ignore for fire-and-
/// forget semantics.
void sendDatagram(
  DgramSocket socket,
  Uint8List bytes,
  String address,
  int port,
) {
  socket.send(bytes.toJS, port.toJS, address.toJS);
}
