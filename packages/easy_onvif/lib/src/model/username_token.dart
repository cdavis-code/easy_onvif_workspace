import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/src/soap/authorization.dart';
import 'package:easy_onvif/util.dart';
import 'package:xml/xml.dart';

class UsernameToken implements XmlSerializable {
  final Authorization authorization;

  UsernameToken({required this.authorization});

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'UsernameToken',
    String? namespace,
  }) => builder.element(
    'UsernameToken',
    nest: () {
      authorization.authInfo.username.buildXml(builder, tag: 'Username');

      builder.element(
        'Password',
        attributes: {
          'Type':
              'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest',
        },
        nest: authorization.digest,
      );

      builder.element(
        'Nonce',
        attributes: {
          'EncodingType':
              'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
        },
        nest: authorization.nonce.toBase64(),
      );

      builder.element(
        'Created',
        nest: () {
          builder.namespaceUri(
            null,
            'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
          );
          builder.text(authorization.utcTimestamp);
        },
      );
    },
  );
}
