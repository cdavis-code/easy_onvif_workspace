/// The plaintext payload that gets sealed into a credential file: a flat list
/// of devices, plus an optional default selection.
///
/// Flat, not a tree: `site` is an attribute so a camera that moves site does not
/// become a migration. Nothing here touches `dart:io`; this compiles to the VM,
/// dart2js and dartwasm alike.
library;

/// One ONVIF device and the credentials used to reach it.
final class DeviceEntry {
  /// Stable, operator-chosen, unique within the bundle (slug-shaped).
  final String id;

  /// Human label; may change without breaking `--device`.
  final String? name;

  /// Optional grouping attribute, e.g. `plant-a`. A filter, not a parent.
  final String? site;

  /// Device host, optionally `host:port` or a scheme.
  final String host;

  final String username;
  final String password;

  final List<String> tags;

  const DeviceEntry({
    required this.id,
    required this.host,
    required this.username,
    required this.password,
    this.name,
    this.site,
    this.tags = const [],
  });

  factory DeviceEntry.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'];
    return DeviceEntry(
      id: _requireString(json, 'id'),
      name: json['name'] as String?,
      site: json['site'] as String?,
      host: _requireString(json, 'host'),
      username: _requireString(json, 'username'),
      password: _requireString(json, 'password'),
      tags: tags is List ? tags.whereType<String>().toList() : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (name != null) 'name': name,
    if (site != null) 'site': site,
    'host': host,
    'username': username,
    'password': password,
    if (tags.isNotEmpty) 'tags': tags,
  };

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw CredentialsFormatException('device entry is missing "$key"');
    }
    return value;
  }
}

/// A sealed bundle's plaintext: every device plus the default selection.
final class DeviceBundle {
  final List<DeviceEntry> devices;
  final String? defaultId;

  const DeviceBundle({required this.devices, this.defaultId});

  factory DeviceBundle.single(DeviceEntry entry) =>
      DeviceBundle(devices: [entry], defaultId: entry.id);

  factory DeviceBundle.fromJson(Map<String, dynamic> json) {
    final raw = json['devices'];
    if (raw is! List || raw.isEmpty) {
      throw const CredentialsFormatException('bundle has no devices');
    }
    final devices = [
      for (final entry in raw)
        if (entry is Map<String, dynamic>)
          DeviceEntry.fromJson(entry)
        else
          throw const CredentialsFormatException(
            'device entry is not an object',
          ),
    ];
    final seen = <String>{};
    for (final device in devices) {
      if (!seen.add(device.id)) {
        throw CredentialsFormatException('duplicate device id "${device.id}"');
      }
    }
    return DeviceBundle(
      devices: devices,
      defaultId: json['default'] as String?,
    );
  }

  /// Reads the pre-encryption shape — `{"host","username","password"}` — as a
  /// single device with the id `default`, so existing files keep working.
  factory DeviceBundle.legacy(Map<String, dynamic> json) => DeviceBundle.single(
    DeviceEntry(
      id: 'default',
      name: json['name'] as String?,
      host: DeviceEntry._requireString(json, 'host'),
      username: DeviceEntry._requireString(json, 'username'),
      password: DeviceEntry._requireString(json, 'password'),
    ),
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    if (defaultId != null) 'default': defaultId,
    'devices': [for (final device in devices) device.toJson()],
  };

  /// The device `--device`/`ONVIF_DEVICE` asks for, else the bundle default.
  ///
  /// Throws with the available ids when the request cannot be resolved, so the
  /// caller never guesses on the operator's behalf.
  DeviceEntry resolve([String? requestedId]) {
    final wanted = requestedId ?? defaultId;
    if (wanted == null) {
      throw CredentialsFormatException(
        'no device selected: pass --device <id> or set a default '
        '(available: ${ids.join(', ')})',
      );
    }
    for (final device in devices) {
      if (device.id == wanted) return device;
    }
    throw CredentialsFormatException(
      'unknown device "$wanted" (available: ${ids.join(', ')})',
    );
  }

  List<String> get ids => [for (final device in devices) device.id];

  /// `--site` / `--tag` filtering for `credentials list`.
  Iterable<DeviceEntry> matching({String? site, String? tag}) => devices.where(
    (d) =>
        (site == null || d.site == site) &&
        (tag == null || d.tags.contains(tag)),
  );
}

/// A credential file plus whether it was encrypted (legacy files are not).
final class BundleFile {
  final DeviceBundle bundle;
  final bool encrypted;

  const BundleFile(this.bundle, {required this.encrypted});
}

/// Malformed, unreadable or mismatched credential material.
final class CredentialsFormatException implements Exception {
  final String message;

  const CredentialsFormatException(this.message);

  @override
  String toString() => 'CredentialsFormatException: $message';
}
