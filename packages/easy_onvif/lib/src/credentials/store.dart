/// Credential file selection: the OS-agnostic entry point used by the CLI and
/// the MCP server.
library;

export 'store_stub.dart' if (dart.library.io) 'store_io.dart';
