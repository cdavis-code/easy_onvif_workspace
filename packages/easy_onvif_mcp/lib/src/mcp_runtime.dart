/// The per-target seam between the MCP server and its host environment.
///
/// The MCP server itself is compiled twice: once for the Dart VM (`dart run
/// bin/easy_onvif_mcp_server.dart`) and once with `dart compile js` for Node.js
/// (`npx easy-onvif-mcp`).  Only six things actually differ between those
/// hosts, and they are all gathered here so the server, the tool registry and
/// the wire protocol exist exactly once.
///
/// Never write to stdout from an implementation of this interface: stdout is
/// the newline-delimited JSON-RPC channel.
library;

import 'package:dio/dio.dart';
import 'package:stream_channel/stream_channel.dart';

/// Host capabilities the MCP server needs, supplied per target.
abstract class McpRuntime {
  /// The newline-delimited JSON-RPC channel bound to the host's stdio.
  StreamChannel<String> stdioChannel();

  /// Writes a diagnostic line to the host's *stderr*. Never stdout.
  void log(String message);

  /// Reads an environment variable (`ONVIF_HOST`, `ONVIF_USERNAME`, ...).
  String? env(String name);

  /// A Dio client that can actually reach the device from this host.
  ///
  /// Under `dart compile js` the default adapter is `XMLHttpRequest`, which
  /// Node.js does not provide, so the Node runtime returns a Dio wired to a
  /// fetch-based adapter instead.
  Dio buildDio();

  /// WS-Discovery probe returning up to [seconds] worth of `ProbeMatch`
  /// payloads. Throws [UnsupportedError] where the host cannot open UDP
  /// sockets (browsers).
  Future<List<Map<String, dynamic>>> probe(int seconds);

  /// Credentials from the host's config file, or `null` when unavailable.
  ///
  /// Mirrors the `easy_onvif_cli` `--config-file` shape so one
  /// `~/.onvif/credentials.json` serves both tools:
  /// `{"host": "...", "username": "...", "password": "..."}`.
  Future<Map<String, String>?> readCredentials();
}
