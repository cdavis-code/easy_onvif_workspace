import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_onvif/soap.dart';
import 'package:http_parser/http_parser.dart';

/// Web-platform implementation of [parseMtom].
///
/// Browsers and WASM targets do not expose `dart:io`, so this variant
/// replaces `ContentType` parsing with [MediaType.parse] from
/// `package:http_parser` and omits the file-system attachment dump that the
/// `_io` implementation performs.
///
/// The MTOM envelope itself is still decoded with the pure-Dart [Mtom.parse]
/// helper and the embedded `application/soap+xml` part is returned as a
/// [String], giving feature parity for the SOAP payload extraction path.
///
/// Writing MTOM attachment parts to a local folder is inherently unsupported
/// in web environments. Passing a non-null [writeLogToFolder] therefore
/// raises an [UnsupportedError] to make the limitation explicit, rather than
/// silently discarding the attachments.
String parseMtom(Response<Uint8List> response, {String? writeLogToFolder}) {
  if (writeLogToFolder != null) {
    throw UnsupportedError(
      'Writing MTOM attachments to a local folder is not supported on the '
      'web platform. Omit `writeLogToFolder` to receive the SOAP XML '
      'payload only.',
    );
  }

  final headerMap = response.headers.map;

  String? xmlString;

  if (headerMap.containsKey('content-type')) {
    final mediaType = MediaType.parse(headerMap['content-type']!.first);

    final boundary = mediaType.parameters['boundary'];

    if (boundary == null) throw Exception('No boundary found');

    final parts = Mtom.parse(boundary: boundary, response: response.data!);

    for (var part in parts) {
      if (part.mediaType.mimeType == 'application/xop+xml' &&
          part.mediaType.parameters.containsValue('application/soap+xml')) {
        xmlString = part.contentAsString;
      }
    }
  }

  return xmlString ??= String.fromCharCodes(response.data!);
}
