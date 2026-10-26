// ignore_for_file: non_constant_identifier_names, camel_case_extensions

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Low-level bindings to the JavaScript global scope.
///
/// These are only safe to use after the Dart code has determined that it is
/// running in a JS host; on the Dart VM none of these symbols exist.
@JS('globalThis')
external JSObject get jsGlobal;

@JS('globalThis.require')
external JSAny? _requireRaw(JSString id);

/// Returns `true` when the executing JS host is Node.js.
///
/// We detect Node by the presence of `globalThis.process.versions.node`.
bool isNodeRuntime() {
  final process = jsGlobal.getProperty<JSAny?>('process'.toJS);

  if (process == null) return false;

  final versions = (process as JSObject).getProperty<JSAny?>('versions'.toJS);

  if (versions == null) return false;

  final nodeVersion = (versions as JSObject).getProperty<JSAny?>('node'.toJS);

  return nodeVersion != null && nodeVersion.isA<JSString>();
}

/// Loads a CommonJS module from Node.js.
///
/// Throws [UnsupportedError] on non-Node JS hosts (browsers, workers, etc.)
/// because `globalThis.require` is only provided by Node's module loader.
JSObject nodeRequire(String moduleId) {
  if (!isNodeRuntime()) {
    throw UnsupportedError(
      'nodeRequire("$moduleId") is only available when running under '
      'Node.js. Current host has no `globalThis.process.versions.node`.',
    );
  }

  final mod = _requireRaw(moduleId.toJS);

  if (mod == null) {
    throw StateError('Node `require("$moduleId")` returned null / undefined.');
  }

  return mod as JSObject;
}
