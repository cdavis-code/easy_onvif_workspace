import '../soap/request_context.dart';

/// Common contract for an ONVIF service handled by the [SoapDispatcher].
///
/// Each service owns one ONVIF namespace (device `tds`, media `trt`,
/// media2 `tr2`, ptz `tptz`) and produces the response XML for the operations
/// in that namespace.
abstract interface class OnvifService {
  /// Whether this service handles operations in [namespace].
  bool handles(String namespace);

  /// Whether [operation] may be invoked without WS-Security authentication.
  bool isPreAuth(String operation);

  /// Handles [ctx] and returns the serialized SOAP response (or a fault).
  Future<String> handle(RequestContext ctx, {required String host});
}
