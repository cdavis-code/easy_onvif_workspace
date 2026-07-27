import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/soap.dart';
import 'package:easy_onvif/util.dart';
import 'package:loggy/loggy.dart';
import 'package:xml/xml.dart';

/// Utility class for interacting through the SOAP protocol
class Transport with UiLoggy {
  final Dio dio;

  final AuthInfo authInfo;

  final bool overrideSpecificationAuthentication;

  static Duration timeDelta = Duration.zero;

  static final builder = XmlBuilder();

  Transport({
    required this.dio,
    required this.authInfo,
    this.overrideSpecificationAuthentication = false,
  });

  /// Send the SOAP [requestData] to the given [url] endpoint.
  Future<Response<Uint8List>> sendLogRequest(
    Uri uri,
    XmlDocument requestData,
  ) async {
    Response<Uint8List> response;

    try {
      response = await dio.post<Uint8List>(
        uri.toString(),
        data: requestData.toString(),
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            // Headers.contentTypeHeader: 'text/xml; charset=utf-8',
            Headers.contentTypeHeader: 'application/soap+xml; charset=utf-8',
          },
        ),
      );
    } on DioException catch (error) {
      switch (error.response?.statusCode) {
        case 500:
        case 400:
          loggy.error('ERROR RESPONSE:\n${error.response?.data}');

          final jsonData = error.response?.data;
          final jsonMap = OnvifUtil.xmlToMap(jsonData as String);

          final envelope = Envelope.fromJson(jsonMap);

          if (envelope.body.hasFault) {
            // Log detailed fault for debugging, throw sanitized message
            loggy.error('ONVIF fault: ${envelope.body.fault}');
            throw Exception(
              'ONVIF operation failed. Please check device logs for details.',
            );
          }
          break;
      }

      // Log full error context, throw generic message to prevent info leakage
      loggy.error('Transport error: $error');
      throw Exception('Network communication failed. Please try again.');
    }

    return response;
  }

  /// Send the SOAP [requestData] to the given [url] endpoint.
  Future<Envelope> sendRequest(Uri uri, XmlDocument requestData) async {
    Response response;

    try {
      response = await dio.post(
        uri.toString(),
        data: requestData.toString(),
        options: Options(
          headers: {
            // Headers.contentTypeHeader: 'text/xml; charset=utf-8',
            Headers.contentTypeHeader: 'application/soap+xml; charset=utf-8',
          },
        ),
      );
    } on DioException catch (error) {
      switch (error.response?.statusCode) {
        case 500:
        case 400:
          loggy.error('ERROR RESPONSE:\n${error.response?.data}');

          final jsonData = error.response?.data;
          final jsonMap = OnvifUtil.xmlToMap(jsonData as String);

          final envelope = Envelope.fromJson(jsonMap);

          if (envelope.body.hasFault) {
            // Log detailed fault for debugging, throw sanitized message
            loggy.error('ONVIF fault: ${envelope.body.fault}');
            throw Exception(
              'ONVIF operation failed. Please check device logs for details.',
            );
          }
          break;
      }

      // Log full error context, throw generic message to prevent info leakage
      loggy.error('Transport error: $error');
      throw Exception('Network communication failed. Please try again.');
    }

    return Envelope.fromXmlString(response.data as String);
  }

  static XmlDocumentFragment quickTag(String tagName, String nameSpace) {
    Transport.builder.element(
      tagName,
      nest: () {
        Transport.builder.namespaceUri(null, nameSpace);
      },
    );

    return Transport.builder.buildFragment();
  }

  /// XML for the SOAP envelope
  Envelope getEnvelope(Body body) => Envelope(body: body, header: Header());

  /// XML for the SOAP envelope
  Envelope getSecuredEnvelope(Body body, [Authorization? authorization]) =>
      Envelope(
        body: body,
        header: Header(
          security: Security(
            usernameToken: UsernameToken(
              authorization:
                  authorization ??
                  Authorization(authInfo: authInfo, timeDelta: timeDelta),
            ),
            mustUnderstand: 1,
          ),
        ),
      );

  Future<Envelope> request(Uri uri, Body body) async =>
      await sendRequest(uri, getEnvelope(body).toXml(builder));

  Future<Envelope> securedRequest(Uri uri, Body body) async =>
      await sendRequest(uri, getSecuredEnvelope(body).toXml(builder));
}
