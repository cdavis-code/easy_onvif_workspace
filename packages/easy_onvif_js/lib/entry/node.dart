// ignore_for_file: non_constant_identifier_names

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../src/api/node_onvif_api.dart';

/// dart2js entry point for the `easy-onvif-node` npm package.
///
/// Build with `tool/build_node.sh`, which runs:
///
/// ```sh
/// dart compile js -O2 \
///   -o build/node/easy_onvif.raw.js \
///   lib/entry/node.dart
/// ```
///
/// and then prepends `tool/node_preamble.js` so the output boots cleanly
/// under Node.js (>= 18). Running the resulting script stashes a single
/// global `globalThis.EasyOnvif` that contains the Node-flavored API
/// surface, including WS-Discovery via `node:dgram` and SOAP via
/// `globalThis.fetch`.
final NodeOnvifApi _api = NodeOnvifApi();

void main() {
  // Expose the API object as a JS interop wrapper so that every @JSExport
  // method on `_api` is reachable from JavaScript as `EasyOnvif.foo(...)`.
  globalContext.setProperty('EasyOnvif'.toJS, createJSInteropWrapper(_api));
}
