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
  /// Namespace declarations for every envelope, keyed by prefix as required
  /// by `XmlBuilder.element`'s `namespaceUris` parameter.
  static const Map<String, String> _namespaceUris = {
    'env': Xmlns.s,
    'tt': Xmlns.tt,
    'tds': Xmlns.tds,
    'trt': Xmlns.trt,
    'tr2': Xmlns.tr2,
    'tptz': Xmlns.tptz,
    'timg': Xmlns.timg,
    'trc': Xmlns.trc,
    'tse': Xmlns.tse,
    'trp': Xmlns.trp,
    'ter': Xmlns.ter,
  };

  /// Wraps a response body (written by [body] into the shared [XmlBuilder]) in
  /// a standard `env:Envelope > env:Body` and returns the serialized XML.
  static String response(void Function(XmlBuilder builder) body) {
    final builder = XmlBuilder();

    builder.declaration(encoding: 'UTF-8');

    builder.element(
      'Envelope',
      namespaceUri: Xmlns.s,
      namespaceUris: _namespaceUris,
      nest: () {
        builder.element(
          'Body',
          namespaceUri: Xmlns.s,
          nest: () {
            body(builder);
          },
        );
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
      namespaceUri: Xmlns.s,
      namespaceUris: _namespaceUris,
      nest: () {
        builder.element(
          'Body',
          namespaceUri: Xmlns.s,
          nest: () {
            builder.element(
              'Fault',
              namespaceUri: Xmlns.s,
              nest: () {
                builder.element(
                  'Code',
                  namespaceUri: Xmlns.s,
                  nest: () {
                    builder.element(
                      'Value',
                      namespaceUri: Xmlns.s,
                      nest: topCode,
                    );
                    builder.element(
                      'Subcode',
                      namespaceUri: Xmlns.s,
                      nest: () {
                        builder.element(
                          'Value',
                          namespaceUri: Xmlns.s,
                          nest: 'ter:$subcode',
                        );
                      },
                    );
                  },
                );
                builder.element(
                  'Reason',
                  namespaceUri: Xmlns.s,
                  nest: () {
                    builder.element(
                      'Text',
                      namespaceUri: Xmlns.s,
                      attributes: {'xml:lang': 'en'},
                      nest: reason,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );

    return builder.buildDocument().toXmlString();
  }
}
