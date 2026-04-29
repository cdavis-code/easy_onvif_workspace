// ignore_for_file: non_constant_identifier_names

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../src/api/web_onvif_api.dart';

/// dart2wasm entry point for the `easy-onvif-web` npm package.
///
/// Build with:
///
/// ```sh
/// dart compile wasm -O2 \
///   -o build/web/easy_onvif.wasm \
///   lib/entry/web.dart
/// ```
///
/// On load, the generated wasm module exports a single global
/// `globalThis.EasyOnvif` whose `probe()` method rejects with
/// `UnsupportedError`. All SOAP calls (`connect`, `getDeviceInformation`,
/// `getProfiles`, `getStreamUri`, `getSnapshotUri`, `absoluteMove`) work
/// through the fetch-based Dio adapter, provided a CORS-friendly proxy is
/// in front of the ONVIF device.
final WebOnvifApi _api = WebOnvifApi();

void main() {
  globalContext.setProperty('EasyOnvif'.toJS, createJSInteropWrapper(_api));
}
