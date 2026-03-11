import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_onvif/soap.dart';

String parseMtom(Response<Uint8List> response, {String? writeLogToFolder}) {
  final headerMap = response.headers.map;

  String? xmlString;

  if (headerMap.containsKey('content-type')) {
    final contentType = ContentType.parse(
      headerMap['content-type']!.first,
    ).parameters;

    if (contentType['boundary'] == null) throw Exception('No boundary found');

    final parts = Mtom.parse(
      boundary: contentType['boundary']!,
      response: response.data!,
    );

    for (var part in parts) {
      if (part.mediaType.mimeType == 'application/xop+xml' &&
          part.mediaType.parameters.containsValue('application/soap+xml')) {
        xmlString = part.contentAsString;
      }

      if (part.mediaType.mimeType == '/' && writeLogToFolder != null) {
        final fileName = part.contentId.split('/').last.replaceAll('>', '');

        var zipFile = File('$writeLogToFolder/$fileName');

        var counter = 0;

        while (zipFile.existsSync()) {
          counter++;

          zipFile = File('$writeLogToFolder/${counter}_$fileName');
        }

        zipFile.writeAsBytesSync(part.content);
      }
    }
  }

  return xmlString ??= String.fromCharCodes(response.data!);
}
