import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'js_globals.dart';

/// Thin accessor for `globalThis.process.env` under Node.js.
///
/// On non-Node JS hosts returns an empty map.
Map<String, String> nodeProcessEnv() {
  if (!isNodeRuntime()) return const <String, String>{};

  final process = jsGlobal.getProperty<JSObject>('process'.toJS);
  final env = process.getProperty<JSObject?>('env'.toJS);

  if (env == null) return const <String, String>{};

  // `Object.keys(env)` gives us the enumerable string keys.
  final objectCtor = jsGlobal.getProperty<JSObject>('Object'.toJS);
  final keysFn = objectCtor.getProperty<JSFunction>('keys'.toJS);

  final jsKeys = keysFn.callAsFunction(objectCtor, env) as JSArray<JSString>;
  final length = (jsKeys.getProperty<JSNumber>('length'.toJS)).toDartInt;

  final out = <String, String>{};

  for (var i = 0; i < length; i++) {
    final key = (jsKeys.getProperty<JSString>(i.toJS)).toDart;
    final value = env.getProperty<JSAny?>(key.toJS);

    if (value != null && value.isA<JSString>()) {
      out[key] = (value as JSString).toDart;
    }
  }

  return out;
}

/// Returns the value of `process.env[name]` when running under Node, or
/// [defaultValue] otherwise.
String? nodeEnv(String name, {String? defaultValue}) {
  if (!isNodeRuntime()) return defaultValue;

  final process = jsGlobal.getProperty<JSObject>('process'.toJS);
  final env = process.getProperty<JSObject?>('env'.toJS);

  if (env == null) return defaultValue;

  final value = env.getProperty<JSAny?>(name.toJS);

  if (value != null && value.isA<JSString>()) return (value as JSString).toDart;

  return defaultValue;
}
