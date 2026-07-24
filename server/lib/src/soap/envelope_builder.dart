import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

/// Builds SOAP 1.2 response envelopes compatible with the `easy_onvif`
/// client's parser.
///
/// The client parses responses with `xml2json` in Badgerfish mode using
/// `useLocalNameForNodes: true`, so only element local-names and namespace
/// URIs matter (prefixes are stripped). The namespace map below mirrors the
/// prefixes used by the reference fixtures in `packages/easy_onvif/test/xml/`.
class SoapEnvelopeBuilder {
  static const Map<String, String> _namespaces = {
    Xmlns.s: 'env',
    Xmlns.tt: 'tt',
    Xmlns.tds: 'tds',
    Xmlns.trt: 'trt',
    Xmlns.tr2: 'tr2',
    Xmlns.tptz: 'tptz',
    Xmlns.timg: 'timg',
    Xmlns.ter: 'ter',
  };

  /// Wraps a response body (written by [body] into the shared [XmlBuilder]) in
  /// a standard `env:Envelope > env:Body` and returns the serialized XML.
  static String response(void Function(XmlBuilder builder) body) {
    final builder = XmlBuilder();

    builder.declaration(encoding: 'UTF-8');

    builder.element(
      'Envelope',
      namespace: Xmlns.s,
      namespaces: _namespaces,
      nest: () {
        builder.element('Body', namespace: Xmlns.s, nest: () {
          body(builder);
        });
      },
    );

    return builder.buildDocument().toXmlString();
  }

  /// Builds a SOAP 1.2 fault envelope.
  ///
  /// [subcode] is a `ter:`-qualified fault subcode such as `NotAuthorized` or
  /// `ActionNotSupported`. [topCode] defaults to `env:Sender`.
  static String fault({
    required String subcode,
    required String reason,
    String topCode = 'env:Sender',
  }) {
    final builder = XmlBuilder();

    builder.declaration(encoding: 'UTF-8');

    builder.element(
      'Envelope',
      namespace: Xmlns.s,
      namespaces: _namespaces,
      nest: () {
        builder.element('Body', namespace: Xmlns.s, nest: () {
          builder.element('Fault', namespace: Xmlns.s, nest: () {
            builder.element('Code', namespace: Xmlns.s, nest: () {
              builder.element(
                'Value',
                namespace: Xmlns.s,
                nest: topCode,
              );
              builder.element('Subcode', namespace: Xmlns.s, nest: () {
                builder.element(
                  'Value',
                  namespace: Xmlns.s,
                  nest: 'ter:$subcode',
                );
              });
            });
            builder.element('Reason', namespace: Xmlns.s, nest: () {
              builder.element(
                'Text',
                namespace: Xmlns.s,
                attributes: {'xml:lang': 'en'},
                nest: reason,
              );
            });
          });
        });
      },
    );

    return builder.buildDocument().toXmlString();
  }
}
