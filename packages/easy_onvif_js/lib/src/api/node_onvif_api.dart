// ignore_for_file: non_constant_identifier_names

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dio/dio.dart';
import 'package:easy_onvif/onvif.dart';

import '../node/node_fetch_adapter.dart';
import '../node/node_multicast_probe.dart';
import 'onvif_api_core.dart';

/// Node.js-flavored ONVIF JS API.
///
/// Adds [probe] on top of [OnvifApiCore] by driving WS-Discovery through
/// [NodeMulticastProbe] (Node's `dgram` via `dart:js_interop`), and overrides
/// [connect] to inject a [NodeFetchAdapter] so Dio's SOAP calls go through
/// Node's built-in `fetch` instead of the browser adapter's `XMLHttpRequest`
/// (which is unavailable in Node).
@JSExport()
class NodeOnvifApi extends OnvifApiCore {
  /// Performs a WS-Discovery probe for [timeoutSeconds] and returns an array
  /// of JS objects describing each discovered device.
  ///
  /// [timeoutSeconds] is positional (rather than a Dart named parameter
  /// with a default) because dart2js's `@JSExport` wrapper is not
  /// arity-aware for named arguments. Callers may pass `null` / `undefined`
  /// to use the default of two seconds.
  JSPromise<JSArray<JSObject>> probe([int? timeoutSeconds]) {
    return (() async {
      final probe = NodeMulticastProbe(timeoutSeconds: timeoutSeconds ?? 2);

      await probe.probe();

      return <JSObject>[
        for (final m in probe.matches) convertProbeMatch(m),
      ].toJS;
    })().toJS;
  }

  /// Overrides [OnvifApiCore.connect] to supply a Node-compatible Dio
  /// instance backed by [NodeFetchAdapter].
  @override
  JSPromise<JSNumber> connect(JSObject options) {
    return (() async {
      final host = (options.getProperty<JSString>('host'.toJS)).toDart;
      final username = (options.getProperty<JSString>('username'.toJS)).toDart;
      final password = (options.getProperty<JSString>('password'.toJS)).toDart;

      final dio = Dio()..httpClientAdapter = NodeFetchAdapter();

      final onvif = await Onvif.connect(
        host: host,
        username: username,
        password: password,
        dio: dio,
      );

      return registerHandle(onvif).toJS;
    })().toJS;
  }
}
