/// Entry point for `dart compile js`, producing the `easy-onvif-mcp` npm
/// bundle's runtime.
///
/// The Dart VM binary uses the generated stdio dispatcher instead (see
/// `bin/easy_onvif_mcp_server.dart`); this entry exists because that generated
/// code imports `dart:io`.
library;

import 'package:easy_onvif_mcp/meta.dart';

import 'js_server.dart';
import 'runtime_node.dart';

Future<void> main() async {
  configureNodeHooks();
  final server = NodeMcpServer(nodeStdioChannel(), version: serverVersion);
  await server.done;
}
