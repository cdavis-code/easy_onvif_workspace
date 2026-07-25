import 'dart:convert';
import 'dart:io';

import 'package:loggy/loggy.dart';

import '../config.dart';
import '../hardware/hardware_adapter.dart';
import '../streaming/stream_backend.dart';
import 'soap_dispatcher.dart';

/// The HTTP front-end for the ONVIF device.
///
/// Listens on [ServerConfig.httpPort] and routes SOAP `POST` requests to the
/// [SoapDispatcher]. Also serves JPEG snapshots over HTTP `GET` at
/// `/onvif/snapshot/<profileToken>` (the URL advertised by `GetSnapshotUri`).
///
/// Responses include CORS headers (and `OPTIONS` preflights are answered), so
/// browser-based clients — e.g. the `easy_onvif` example running on Flutter
/// web — can reach the server directly without a separate CORS proxy.
class OnvifServer with UiLoggy {
  final ServerConfig config;
  final SoapDispatcher dispatcher;
  final HardwareAdapter hardware;

  /// Optional source of stream-derived snapshots (preferred over opening the
  /// camera device again, which would contend with the RTSP encoder).
  final StreamBackend? streamBackend;

  HttpServer? _server;

  OnvifServer({
    required this.config,
    required this.dispatcher,
    required this.hardware,
    this.streamBackend,
  });

  /// The port the server is bound to (once started).
  int? get port => _server?.port;

  Future<void> start({
    LogOptions logOptions = const LogOptions(LogLevel.info),
    LoggyPrinter printer = const PrettyPrinter(showColors: false),
  }) async {
    Loggy.initLoggy(logPrinter: printer, logOptions: logOptions);

    _server = await HttpServer.bind(InternetAddress.anyIPv4, config.httpPort);

    loggy.info('ONVIF server listening on port ${_server!.port}');

    _server!.listen(_handleRequest);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // Allow browser clients to call the server cross-origin (Flutter web).
    _addCorsHeaders(request.response);

    try {
      if (request.method == 'OPTIONS') {
        // CORS preflight: the allowed methods/headers are in the CORS headers.
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      } else if (request.method == 'POST') {
        await _handleSoap(request);
      } else if (request.method == 'GET' &&
          request.uri.path.startsWith('/onvif/snapshot')) {
        await _handleSnapshot(request);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    } catch (error, stackTrace) {
      loggy.error('Request handling error: $error\n$stackTrace');

      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  /// Sets permissive CORS headers so the server can be used from a browser
  /// (the ONVIF SOAP calls carry WS-Security in the body, not HTTP
  /// credentials, so a wildcard origin is appropriate).
  void _addCorsHeaders(HttpResponse response) {
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type, Authorization')
      ..set('Access-Control-Max-Age', '86400');
  }

  Future<void> _handleSoap(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();

    final responseXml = await dispatcher.dispatch(body, host: _hostOf(request));

    request.response.statusCode = HttpStatus.ok;

    if (responseXml.contains('GetSystemLogResponse')) {
      // The `easy_onvif` client parses GetSystemLog strictly as an MTOM
      // (multipart/related) response and rejects plain SOAP XML.
      _writeMtomResponse(request.response, responseXml);
    } else {
      request.response.headers.contentType = ContentType(
        'application',
        'soap+xml',
        charset: 'utf-8',
      );

      request.response.write(responseXml);
    }

    await request.response.close();
  }

  /// Wraps [xml] in a single-part MTOM (XOP) body, matching the shape real
  /// devices use for log downloads.
  void _writeMtomResponse(HttpResponse response, String xml) {
    const boundary = 'MIMEBoundary_easy_onvif_server';

    response.headers.contentType = ContentType(
      'multipart',
      'related',
      parameters: {'boundary': boundary, 'type': 'application/xop+xml'},
    );

    response.write(
      '\r\n--$boundary\r\n'
      'Content-Type: application/xop+xml; charset=utf-8; '
      'type="application/soap+xml"\r\n'
      'Content-Transfer-Encoding: 8bit\r\n'
      'Content-ID: <soap@easy-onvif-server>\r\n'
      '\r\n'
      '$xml'
      '\r\n--$boundary--',
    );
  }

  Future<void> _handleSnapshot(HttpRequest request) async {
    // Prefer a frame grabbed from the live stream (avoids contending for the
    // camera device); fall back to the hardware adapter's camera.
    final bytes =
        await streamBackend?.snapshot() ?? await hardware.captureSnapshot();

    if (bytes == null) {
      request.response.statusCode = HttpStatus.notFound;
    } else {
      request.response.headers.contentType = ContentType('image', 'jpeg');
      request.response.add(bytes);
    }

    await request.response.close();
  }

  /// Derives the advertised host from the request's `Host` header so that
  /// self-referential service URLs point back to the address the client used.
  String _hostOf(HttpRequest request) {
    final hostHeader = request.headers.value('host');

    if (hostHeader != null && hostHeader.isNotEmpty) {
      return hostHeader.split(':').first;
    }

    return request.connectionInfo?.remoteAddress.address ?? 'localhost';
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}
