import 'package:loggy/loggy.dart';

import '../services/onvif_service.dart';
import '../soap/authenticator.dart';
import '../soap/envelope_builder.dart';
import '../soap/request_context.dart';

/// Parses incoming SOAP requests, enforces WS-Security authentication, and
/// routes each operation to the [OnvifService] that owns its namespace.
class SoapDispatcher with UiLoggy {
  final List<OnvifService> services;
  final Authenticator authenticator;

  SoapDispatcher({required this.services, required this.authenticator});

  /// Dispatches [rawXml] and returns the serialized SOAP response.
  ///
  /// [host] is the address the client used to reach the server (from the HTTP
  /// `Host` header); it is used to build self-referential service URLs.
  Future<String> dispatch(String rawXml, {required String host}) async {
    final RequestContext ctx;

    try {
      ctx = RequestContext.parse(rawXml);
    } on FormatException catch (error) {
      loggy.error('Malformed SOAP request: $error');

      return SoapEnvelopeBuilder.fault(
        subcode: 'InvalidRequest',
        reason: 'The request could not be parsed.',
      );
    }

    loggy.debug('Dispatching ${ctx.operation} (${ctx.operationNamespace})');

    final service = _serviceFor(ctx.operationNamespace);

    if (service == null) {
      loggy.warning('No service for namespace ${ctx.operationNamespace}');

      return SoapEnvelopeBuilder.fault(
        subcode: 'ActionNotSupported',
        reason: 'No service is registered for the requested namespace.',
      );
    }

    if (!service.isPreAuth(ctx.operation) &&
        !authenticator.verify(ctx.credentials)) {
      loggy.warning('Authentication failed for ${ctx.operation}');

      return SoapEnvelopeBuilder.fault(
        subcode: 'NotAuthorized',
        reason: 'The credentials supplied were invalid.',
      );
    }

    try {
      return await service.handle(ctx, host: host);
    } catch (error, stackTrace) {
      loggy.error('Error handling ${ctx.operation}: $error\n$stackTrace');

      return SoapEnvelopeBuilder.fault(
        subcode: 'InternalError',
        reason: 'The device encountered an internal error.',
      );
    }
  }

  OnvifService? _serviceFor(String namespace) {
    for (final service in services) {
      if (service.handles(namespace)) return service;
    }

    return null;
  }
}
