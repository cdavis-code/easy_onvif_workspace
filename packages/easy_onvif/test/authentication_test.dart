import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/soap.dart';
import 'package:easy_onvif/util.dart';

import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';
import 'package:xml2json/xml2json.dart';

void main() {
  group('Authorization', () {
    final authInfo = AuthInfo(
      host: 'localhost',
      username: 'admin',
      password: 'password',
    );

    final authorization = Authorization(
      authInfo: authInfo,
      timeDelta: Duration(seconds: 0),
      timestampOverride: DateTime(2024, 1, 20, 16, 10, 0),
      nonceOverride: Nonce(
        bytesOverride: hex.decode('0102030405060708090A0B0C0D0E0F10'),
      ),
    );

    test('generate valid nonce and digest', () {
      expect(authorization.utcTimestamp, '2024-01-20T21:10:00.000Z');
      expect(authorization.nonce.toBase64(), 'AQIDBAUGBwgJCgsMDQ4PEA==');
      expect(authorization.digest, 'iJSWNCOtYP5YI9F5j4z4/hkM/yo=');
    });

    test('generate valid security header', () {
      final builder = XmlBuilder();

      final jsonTransformer = Xml2Json();

      final securityHeader = Header(
        security: Security(
          usernameToken: UsernameToken(authorization: authorization),
          mustUnderstand: 1,
        ),
      );

      final envelope = Envelope(header: securityHeader, body: Body());

      final xml = envelope.toXml(builder);

      jsonTransformer.parse(
        xml
            // ignore: experimental_member_use
            .xpath('s:Envelope/s:Header/Security/UsernameToken')
            .last
            .toXmlString(),
      );

      final usernameJson = json.decode(jsonTransformer.toBadgerfish());

      expect(
        OnvifUtil.stringMappedFromXml(
          usernameJson['UsernameToken']['Username'],
        ),
        'admin',
      );
      expect(
        OnvifUtil.stringMappedFromXml(
          usernameJson['UsernameToken']['Password'],
        ),
        'iJSWNCOtYP5YI9F5j4z4/hkM/yo=',
      );
      expect(
        OnvifUtil.stringMappedFromXml(usernameJson['UsernameToken']['Nonce']),
        'AQIDBAUGBwgJCgsMDQ4PEA==',
      );
      expect(
        OnvifUtil.stringMappedFromXml(usernameJson['UsernameToken']['Created']),
        '2024-01-20T21:10:00.000Z',
      );
    });
  });
}
