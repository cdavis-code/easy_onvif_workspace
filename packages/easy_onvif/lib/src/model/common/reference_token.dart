import 'package:easy_onvif/shared.dart';
import 'package:xml/xml.dart';

class ReferenceToken implements XmlSerializable {
  final String token;

  ReferenceToken(this.token) {
    if (token.isEmpty) {
      throw ArgumentError('Token cannot be empty.');
    }

    if (token.length > 64) {
      throw ArgumentError('Token cannot be longer than 64 characters.');
    }
  }

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'ProfileToken',
    String? namespace,
  }) => builder.element(
    tag,
    nest: () {
      builder.text(token);

      if (namespace != null) {
        builder.namespaceUri(null, namespace);
      }
    },
  );
}
