/// The tool vocabulary shared by every ONVIF MCP target.
///
/// This is the single source of truth for what the server can do: the Dart VM
/// binary (`bin/easy_onvif_mcp_server.dart`) and the `dart compile js` Node.js
/// bundle both register exactly the list built in `onvif_tools.dart`, so a
/// tool is written once instead of per-target.
library;

import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:easy_onvif/onvif.dart';

import 'onvif_mcp_server.dart';

/// A tool handler receives the validated MCP arguments and the server that
/// owns the device connection.
typedef ToolDispatch =
    FutureOr<Object?> Function(
      Map<String, dynamic> args,
      OnvifMcpServer server,
    );

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

  const ToolDef({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.dispatch,
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
String requiredString(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is! String || value.isEmpty) {
    throw ArgumentError.value(value, key, 'is required and must be a string');
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
// Result encoding
// ---------------------------------------------------------------------------

/// Converts an `easy_onvif` model graph into something `jsonEncode` can write.
///
/// The ONVIF models are `json_serializable` classes whose `toJson()` output
/// keeps XML artefacts on purpose: `@`-prefixed keys are the XML attributes,
/// and for these models the attribute *is* the payload callers want (`@token`,
/// `@x`) — the CLI documents `jq '.[] | ."@token"'` against the same shape, so
/// they are preserved rather than stripped. What does need normalizing is
/// values a JSON encoder cannot reach on a JS host: `DateTime`, `Uri`, enums
/// and nested model objects.
Object? jsonSafe(Object? value) {
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }
  if (value is DateTime) return value.toIso8601String();
  if (value is Uri) return value.toString();
  if (value is Enum) return value.name;
  if (value is Iterable) return value.map(jsonSafe).toList();
  if (value is Map) return _mapSafe(value);

  final json = _toJson(value);
  if (json is Map) return _mapSafe(json);
  if (json != null) return jsonSafe(json);
  return value.toString();
}

Map<String, Object?> _mapSafe(Map<dynamic, dynamic> source) => {
  for (final entry in source.entries)
    entry.key.toString(): jsonSafe(entry.value),
};

/// Calls `toJson()` when the object has one, otherwise returns null.
Object? _toJson(Object value) {
  try {
    return (value as dynamic).toJson() as Object?;
  } catch (_) {
    return null;
  }
}

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
