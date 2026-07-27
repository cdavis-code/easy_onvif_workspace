import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/src/soap/xmlns.dart';
import 'package:xml/xml.dart';

import 'username_token.dart';

/// Security header for SOAP requests.
class Security implements XmlSerializable {
  final UsernameToken usernameToken;

  final int mustUnderstand;

  Security({required this.usernameToken, required this.mustUnderstand});

  Map<String, dynamic> toJson() => {
    'UsernameToken': {
      'Authorization': {
        'Username': usernameToken.authorization.authInfo.username,
        'Password': usernameToken.authorization.digest,
        'Nonce': usernameToken.authorization.nonce.toBase64(),
        'Created': usernameToken.authorization.utcTimestamp,
      },
    },
  };

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Security',
    String? namespace,
  }) => builder.element(
    'Security',
    namespaceUri: namespace,
    // namespaces: {Xmlns.s: 's'},
    nest: () {
      builder.namespaceUri(
        null,
        'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
      );

      builder.attribute(
        'mustUnderstand',
        mustUnderstand,
        namespaceUri: Xmlns.s,
      );

      usernameToken.buildXml(builder);
    },
  );
}
