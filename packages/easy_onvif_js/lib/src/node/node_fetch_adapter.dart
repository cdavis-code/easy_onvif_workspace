// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../interop/js_globals.dart';

/// A Dio [HttpClientAdapter] that delegates HTTP requests to Node.js's
/// built-in `globalThis.fetch` via `dart:js_interop`.
///
/// Motivation: on Node.js, Dio's default adapter (chosen at compile time via
/// `dart.library.js_interop`) is the browser adapter, which relies on
/// `XMLHttpRequest`. Node has no XHR, so requests trap with "unreachable"
/// under dart2wasm or throw at runtime under dart2js. Modern Node (>= 18)
/// ships a built-in fetch implementation; this adapter routes Dio's SOAP
/// POSTs through it.
class NodeFetchAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // 1. Collect request body bytes (SOAP envelopes are small; streaming
    //    semantics aren't needed here).
    Uint8List? bodyBytes;
    if (requestStream != null) {
      final chunks = <int>[];
      await for (final chunk in requestStream) {
        chunks.addAll(chunk);
      }
      if (chunks.isNotEmpty) bodyBytes = Uint8List.fromList(chunks);
    }

    // 2. Build the JS init object for fetch().
    final init = JSObject();
    init.setProperty('method'.toJS, options.method.toJS);

    final headers = JSObject();
    options.headers.forEach((name, value) {
      if (value == null) return;
      headers.setProperty(name.toJS, value.toString().toJS);
    });
    init.setProperty('headers'.toJS, headers);

    if (bodyBytes != null) {
      init.setProperty('body'.toJS, bodyBytes.toJS);
    }

    // 3. Call globalThis.fetch(url, init).
    final fetchFn = jsGlobal.getProperty<JSFunction?>('fetch'.toJS);
    if (fetchFn == null) {
      throw StateError(
        'NodeFetchAdapter: `globalThis.fetch` is not available. '
        'Node.js >= 18 is required.',
      );
    }

    final responsePromise =
        fetchFn.callAsFunction(jsGlobal, options.uri.toString().toJS, init)
            as JSPromise;

    final response = (await responsePromise.toDart) as JSObject;

    final statusCode = (response.getProperty<JSNumber>(
      'status'.toJS,
    )).toDartInt;
    final statusText = response
        .getProperty<JSString?>('statusText'.toJS)
        ?.toDart;

    // 4. Collect response headers into Dio's Map<String, List<String>>.
    final respHeaders = <String, List<String>>{};
    final headersObj = response.getProperty<JSObject>('headers'.toJS);
    final entriesFn = headersObj.getProperty<JSFunction>('entries'.toJS);
    final iterator = entriesFn.callAsFunction(headersObj) as JSObject;

    while (true) {
      final nextFn = iterator.getProperty<JSFunction>('next'.toJS);
      final step = nextFn.callAsFunction(iterator) as JSObject;
      final done = step.getProperty<JSBoolean>('done'.toJS).toDart;
      if (done) break;

      final value = step.getProperty<JSArray>('value'.toJS);
      final name = (value.getProperty<JSString>(0.toJS)).toDart.toLowerCase();
      final val = (value.getProperty<JSString>(1.toJS)).toDart;
      respHeaders.putIfAbsent(name, () => <String>[]).add(val);
    }

    // 5. Read the body as ArrayBuffer -> Uint8List.
    final arrayBufferFn = response.getProperty<JSFunction>('arrayBuffer'.toJS);
    final bufferPromise = arrayBufferFn.callAsFunction(response) as JSPromise;
    final buffer = (await bufferPromise.toDart) as JSArrayBuffer;
    final bytes = buffer.toDart.asUint8List();

    return ResponseBody.fromBytes(
      bytes,
      statusCode,
      statusMessage: statusText,
      headers: respHeaders,
    );
  }

  @override
  void close({bool force = false}) {
    // Nothing to close: fetch is stateless at the adapter level.
  }
}
