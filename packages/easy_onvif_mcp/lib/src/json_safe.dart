/// JSON normalization for `easy_onvif` model graphs.
///
/// Shared by the generated stdio dispatcher (via the tool methods) and the
/// Node.js registry.
library;

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
