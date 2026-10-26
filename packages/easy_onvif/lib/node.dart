/// Node.js host bindings for `easy_onvif`.
///
/// Only importable in code compiled for Node.js (`dart compile js`); the
/// bindings rely on `globalThis.require` and `dart:js_interop`, neither of
/// which exists on the Dart VM. Used by the `easy-onvif-node` and
/// `easy-onvif-mcp` npm artifacts.
library;

export 'src/platform/node/dgram.dart';
export 'src/platform/node/js_globals.dart';
export 'src/platform/node/node_fetch_adapter.dart';
export 'src/platform/node/node_multicast_probe.dart';
