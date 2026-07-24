import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

/// The WS-Security `UsernameToken` credentials extracted from an incoming
/// request, if present.
class UsernameTokenCredentials {
  final String username;

  /// The Base64 `PasswordDigest` supplied by the client.
  final String passwordDigest;

  /// The Base64-encoded nonce supplied by the client.
  final String nonce;

  /// The `Created` timestamp (ISO-8601 UTC) supplied by the client.
  final String created;

  UsernameTokenCredentials({
    required this.username,
    required this.passwordDigest,
    required this.nonce,
    required this.created,
  });
}

/// A parsed incoming SOAP request.
///
/// Provides the operation element (the first child of `env:Body`) along with
/// any WS-Security credentials found in the header.
class RequestContext {
  /// The local name of the operation element, e.g. `GetDeviceInformation`.
  final String operation;

  /// The namespace URI of the operation element, e.g. the `tds` namespace.
  final String operationNamespace;

  /// The full operation element, for reading request parameters.
  final XmlElement operationElement;

  /// Credentials extracted from the WS-Security header, if any.
  final UsernameTokenCredentials? credentials;

  RequestContext({
    required this.operation,
    required this.operationNamespace,
    required this.operationElement,
    required this.credentials,
  });

  /// Parses [rawXml] into a [RequestContext].
  ///
  /// Throws [FormatException] if the envelope or body cannot be located.
  factory RequestContext.parse(String rawXml) {
    final document = XmlDocument.parse(rawXml);

    final body = document
        .findAllElements('Body', namespace: Xmlns.s)
        .firstOrNull;

    if (body == null) {
      throw const FormatException('SOAP Body element not found.');
    }

    final operationElement = body.childElements.firstOrNull;

    if (operationElement == null) {
      throw const FormatException('SOAP Body has no operation element.');
    }

    return RequestContext(
      operation: operationElement.localName,
      operationNamespace: operationElement.namespaceUri ?? '',
      operationElement: operationElement,
      credentials: _extractCredentials(document),
    );
  }

  static UsernameTokenCredentials? _extractCredentials(XmlDocument document) {
    final token = document.findAllElements('UsernameToken').firstOrNull;

    if (token == null) return null;

    final username = _childText(token, 'Username');
    final password = _childText(token, 'Password');
    final nonce = _childText(token, 'Nonce');
    final created = _childText(token, 'Created');

    if (username == null ||
        password == null ||
        nonce == null ||
        created == null) {
      return null;
    }

    return UsernameTokenCredentials(
      username: username,
      passwordDigest: password,
      nonce: nonce,
      created: created,
    );
  }

  /// Returns the trimmed text of the first descendant of [parent] whose local
  /// name matches [localName], regardless of namespace.
  static String? _childText(XmlElement parent, String localName) {
    final element = parent.findAllElements(localName).firstOrNull;

    return element?.innerText.trim();
  }

  /// Reads the trimmed text of the first direct child of [operationElement]
  /// whose local name matches [localName], used for request parameters.
  String? param(String localName) {
    for (final child in operationElement.childElements) {
      if (child.localName == localName) return child.innerText.trim();
    }

    return null;
  }

  /// Reads all direct children of [operationElement] whose local name matches
  /// [localName], used for repeated request parameters.
  List<XmlElement> params(String localName) => operationElement.childElements
      .where((child) => child.localName == localName)
      .toList();
}
