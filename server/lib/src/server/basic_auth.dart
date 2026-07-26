import 'dart:convert';

/// Returns `true` if [authorizationHeader] is an HTTP `Basic` credential
/// matching [username]/[password].
///
/// Shared by the HTTP snapshot endpoint and the RTSP server, both of which
/// gate access with the same device credentials. Malformed headers return
/// `false` rather than throwing.
bool basicAuthMatches(
  String? authorizationHeader,
  String username,
  String password,
) {
  if (authorizationHeader == null) return false;

  final parts = authorizationHeader.trim().split(RegExp(r'\s+'));

  if (parts.length != 2 || parts[0] != 'Basic') return false;

  try {
    final decoded = utf8.decode(base64.decode(parts[1]));
    final separator = decoded.indexOf(':');

    if (separator < 0) return false;

    return decoded.substring(0, separator) == username &&
        decoded.substring(separator + 1) == password;
  } catch (_) {
    return false;
  }
}
