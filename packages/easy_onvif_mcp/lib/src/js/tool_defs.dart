/// The Node.js tool vocabulary.
///
/// The Dart VM binary registers the tools generated from the `@Tool`
/// annotations on [EasyOnvifMcpServer]; the generated dispatcher imports
/// `dart:io` and cannot be compiled with `dart compile js`, so the npm bundle
/// keeps this hand-written registry. Both paths call the same annotated
/// methods, so behaviour lives in exactly one place.
library;

import 'dart:async';

import 'package:dart_mcp/server.dart';

import '../easy_onvif_mcp_server.dart';

/// A tool handler receives the validated MCP arguments.
typedef ToolDispatch = FutureOr<Object?> Function(Map<String, dynamic> args);

/// One MCP tool: its name, the schema the client sees, and the Dart that runs.
final class ToolDef {
  /// The fully qualified tool name, e.g. `onvif_get_profiles`.
  final String name;

  /// What the tool does, shown to the model.
  final String description;

  /// The JSON schema describing this tool's arguments.
  final ObjectSchema inputSchema;

  /// Runs the tool; the returned value is JSON-encoded into the MCP result.
  final ToolDispatch dispatch;

  /// Whether `dart_mcp` should validate arguments against [inputSchema]
  /// before [dispatch] runs.
  ///
  /// Its failure message quotes the offending value
  /// (``Value `12345` is not of type `String` at path #root["password"]``), so
  /// tools that accept a credential must validate themselves instead — many
  /// ONVIF devices ship numeric default passwords, and echoing one into the
  /// model transcript would disclose it.
  final bool validateArguments;

  const ToolDef({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.dispatch,
    this.validateArguments = true,
  });

  /// A tool that takes no arguments, the common case for the `get_*` tools.
  factory ToolDef.noArgs({
    required String name,
    required String description,
    required ToolDispatch dispatch,
  }) => ToolDef(
    name: name,
    description: description,
    inputSchema: ObjectSchema(properties: const {}),
    dispatch: dispatch,
  );
}

// ---------------------------------------------------------------------------
// Argument accessors
// ---------------------------------------------------------------------------

/// Reads a required string argument.
///
/// The failure message deliberately omits the received value: these accessors
/// are used for credentials too.
String requiredString(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is! String || value.isEmpty) {
    throw ArgumentError('"$key" is required and must be a non-empty string');
  }
  return value;
}

/// Reads an optional string argument.
String? optionalString(Map<String, dynamic> args, String key) {
  final value = args[key];
  return value is String && value.isNotEmpty ? value : null;
}

/// Reads a required numeric argument.
double requiredNumber(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw ArgumentError.value(value, key, 'is required and must be a number');
}

/// Reads an optional numeric argument.
double? optionalNumber(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Reads an optional integer argument.
int? optionalInt(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Reads an optional boolean argument, defaulting to [fallback].
bool optionalBool(
  Map<String, dynamic> args,
  String key, {
  bool fallback = false,
}) => args[key] is bool ? args[key]! as bool : fallback;

// ---------------------------------------------------------------------------
// Common schema fragments
// ---------------------------------------------------------------------------

/// The media profile token almost every media/PTZ call is scoped by.
final ObjectSchema profileTokenArgs = ObjectSchema(
  properties: {
    'profile_token': Schema.string(
      description:
          'Media profile token, e.g. `Profile_1`. Obtain it from onvif_get_profiles.',
    ),
  },
  required: ['profile_token'],
);

/// A host/username/password triple for [Onvif.connect].
final ObjectSchema deviceArgs = ObjectSchema(
  properties: {
    'host': Schema.string(
      description:
          'Device host, optionally with a port or scheme, e.g. `192.168.1.10:8080`.',
    ),
    'username': Schema.string(description: 'Device username.'),
    'password': Schema.string(description: 'Device password.'),
  },
  required: ['host', 'username', 'password'],
);
