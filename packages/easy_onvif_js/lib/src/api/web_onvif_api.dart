// ignore_for_file: non_constant_identifier_names

import 'dart:js_interop';

import 'onvif_api_core.dart';

/// Browser-flavored ONVIF JS API.
///
/// The surface is identical to [OnvifApiCore] except that [probe] is defined
/// and always rejects with an [UnsupportedError]: browsers cannot open UDP
/// sockets, so WS-Discovery is structurally unavailable. Consumers targeting
/// browsers must connect to a known camera endpoint through a CORS-friendly
/// proxy.
@JSExport()
class WebOnvifApi extends OnvifApiCore {
  JSPromise<JSArray<JSObject>> probe({int timeoutSeconds = 2}) {
    return Future<JSArray<JSObject>>.error(
      UnsupportedError(
        'WS-Discovery is not supported in the browser. Connect to a known '
        'ONVIF endpoint via `connect({ host, username, password })` instead.',
      ),
    ).toJS;
  }
}
