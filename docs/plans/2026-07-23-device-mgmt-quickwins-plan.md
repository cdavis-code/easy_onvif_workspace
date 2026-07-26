# Device Management Quick-Wins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the missing Device Management (`tds`) operations — Relay I/O, GeoLocation set/delete, network setters, and gateway/zero-config/IP-filter — to the `easy_onvif` Dart client.

**Architecture:** Each operation follows the codebase's established pattern: a static SOAP request builder on `DeviceManagementRequest`, json_serializable model(s) in `model/device_management/`, a public async method on the `DeviceManagement` class, a barrel export, and a request-construction unit test asserting exact XML. Grounded in `docs/plans/2026-07-23-device-mgmt-quickwins-design.md` and the `devicemgmt.wsdl` / `onvif.xsd`.

**Tech Stack:** Dart, `package:xml` (XmlBuilder), `json_serializable` + `build_runner`, `package:test`.

---

## Environment notes (READ FIRST)

- Work happens in `/Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif`.
- **`git`, `grep`, `ls`, `cat` MUST be prefixed with `rtk`** (a hook blocks them otherwise): `rtk git add …`, `rtk grep -E …`.
- Test/analyze runs can be verbose; redirect and grep the verdict:
  `dart test test/soap_request_test.dart > /tmp/t.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t.log | tail -1`
- After adding/editing any model with a `part 'x.g.dart'`, regenerate code:
  `dart run build_runner build --delete-conflicting-outputs`
- The tds namespace constant `Xmlns.tds` = `http://www.onvif.org/ver10/device/wsdl`.
- Request-construction tests wrap the builder fragment in a `<Test>` element and assert the exact XML string (pattern in `test/soap_request_test.dart`). No device is needed.
- Models that serialize into request XML implement `XmlSerializable` (`lib/src/model/common/xml_serializable.dart`): `void buildXml(XmlBuilder builder, {String tag, String? namespace})`.
- Scalar elements use the `String.buildXml(builder, tag: ...)` extension (`lib/src/util/extra.dart`).
- Enum fields parsed from XML responses need a custom `fromJson` using `OnvifUtil.stringMappedFromXml` (badgerfish `{'$': value}` maps) — see `IpAddressFilter._mappedToType`.

## File structure

| File | Responsibility |
|---|---|
| `lib/src/model/device_management/relay_output_settings.dart` (create) | `RelayMode`/`RelayIdleState`/`RelayLogicalState` enums + `RelayOutputSettings` (XmlSerializable) |
| `lib/src/model/device_management/relay_output.dart` (create) | `RelayOutput` + `GetRelayOutputsResponse` |
| `lib/src/model/device_management/network_gateway.dart` (create) | `NetworkGateway` + `GetNetworkDefaultGatewayResponse` |
| `lib/src/model/device_management/network_zero_configuration.dart` (create) | `NetworkZeroConfiguration` + `GetZeroConfigurationResponse` |
| `lib/src/model/device_management/location_entity.dart` (modify) | add `buildXml` (implement `XmlSerializable`) |
| `lib/src/soap/device_management.dart` (modify) | new static request builders |
| `lib/src/device_management.dart` (modify) | new public methods on `DeviceManagement` |
| `lib/device_management.dart` (modify) | barrel exports for new models |
| `test/soap_request_test.dart` (modify) | request-construction tests |
| `README.md` (modify) | Device Management operations matrix |

---

### Task 1: Relay I/O (`GetRelayOutputs`, `SetRelayOutputState`, `SetRelayOutputSettings`)

**Files:**
- Create: `lib/src/model/device_management/relay_output_settings.dart`
- Create: `lib/src/model/device_management/relay_output.dart`
- Modify: `lib/src/soap/device_management.dart`
- Modify: `lib/src/device_management.dart`
- Modify: `lib/device_management.dart`
- Test: `test/soap_request_test.dart`

- [ ] **Step 1: Write the failing request-construction tests.** Add inside the `group('Device Management SOAP Requests', ...)` in `test/soap_request_test.dart`:

```dart
    test('getRelayOutputs', () {
      builder.element('Test', nest: DeviceManagementRequest.getRelayOutputs());

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetRelayOutputs xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('setRelayOutputState', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setRelayOutputState(
          relayOutputToken: 'relay1',
          logicalState: RelayLogicalState.active,
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetRelayOutputState xmlns="http://www.onvif.org/ver10/device/wsdl"><RelayOutputToken>relay1</RelayOutputToken><LogicalState>active</LogicalState></SetRelayOutputState></Test>',
      );
    });

    test('setRelayOutputSettings', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setRelayOutputSettings(
          relayOutputToken: 'relay1',
          properties: RelayOutputSettings(
            mode: RelayMode.monostable,
            delayTime: 'PT1S',
            idleState: RelayIdleState.open,
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetRelayOutputSettings xmlns="http://www.onvif.org/ver10/device/wsdl"><RelayOutputToken>relay1</RelayOutputToken><Properties><Mode>Monostable</Mode><DelayTime>PT1S</DelayTime><IdleState>open</IdleState></Properties></SetRelayOutputSettings></Test>',
      );
    });
```

- [ ] **Step 2: Run — verify FAIL** (builders/models undefined).

Run: `cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif && dart test test/soap_request_test.dart > /tmp/t1.log 2>&1; rtk grep -E "(All tests passed|Some tests failed|Error)" /tmp/t1.log | tail -1`

- [ ] **Step 3: Create** `lib/src/model/device_management/relay_output_settings.dart`:

```dart
import 'dart:convert';

import 'package:easy_onvif/src/model/common/xml_serializable.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'relay_output_settings.g.dart';

/// Relay operating mode (tt:RelayMode): 'Monostable' or 'Bistable'.
enum RelayMode {
  @JsonValue('Monostable')
  monostable('Monostable'),
  @JsonValue('Bistable')
  bistable('Bistable');

  final String value;
  const RelayMode(this.value);
}

/// Relay idle state (tt:RelayIdleState): 'closed' or 'open'.
enum RelayIdleState {
  @JsonValue('closed')
  closed('closed'),
  @JsonValue('open')
  open('open');

  final String value;
  const RelayIdleState(this.value);
}

/// Relay logical state (tt:RelayLogicalState) for SetRelayOutputState:
/// 'active' or 'inactive'.
enum RelayLogicalState {
  @JsonValue('active')
  active('active'),
  @JsonValue('inactive')
  inactive('inactive');

  final String value;
  const RelayLogicalState(this.value);
}

/// Settings for a relay output (tt:RelayOutputSettings).
@JsonSerializable()
class RelayOutputSettings implements XmlSerializable {
  @JsonKey(name: 'Mode', fromJson: _modeFromXml)
  final RelayMode mode;

  /// Time after which the relay returns to its idle state (monostable mode);
  /// an xs:duration string such as `PT1S`.
  @JsonKey(name: 'DelayTime', fromJson: OnvifUtil.nullableStringMappedFromXml)
  final String? delayTime;

  @JsonKey(name: 'IdleState', fromJson: _idleStateFromXml)
  final RelayIdleState idleState;

  RelayOutputSettings({
    required this.mode,
    required this.idleState,
    this.delayTime,
  });

  factory RelayOutputSettings.fromJson(Map<String, dynamic> json) =>
      _$RelayOutputSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$RelayOutputSettingsToJson(this);

  @override
  String toString() => json.encode(toJson());

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Properties',
    String? namespace,
  }) => builder.element(
    tag,
    nest: () {
      if (namespace != null) builder.namespace(namespace);

      mode.value.buildXml(builder, tag: 'Mode');
      (delayTime ?? 'PT0S').buildXml(builder, tag: 'DelayTime');
      idleState.value.buildXml(builder, tag: 'IdleState');
    },
  );

  static RelayMode _modeFromXml(dynamic value) => RelayMode.values.firstWhere(
    (e) =>
        e.value == OnvifUtil.stringMappedFromXml(value as Map<String, dynamic>),
  );

  static RelayIdleState _idleStateFromXml(dynamic value) =>
      RelayIdleState.values.firstWhere(
        (e) =>
            e.value ==
            OnvifUtil.stringMappedFromXml(value as Map<String, dynamic>),
      );
}
```

- [ ] **Step 4: Create** `lib/src/model/device_management/relay_output.dart`:

```dart
import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

import 'relay_output_settings.dart';

part 'relay_output.g.dart';

/// A relay output (tt:RelayOutput): a DeviceEntity (token) with settings.
@JsonSerializable()
class RelayOutput {
  @JsonKey(name: '@token')
  final String token;

  @JsonKey(name: 'Properties')
  final RelayOutputSettings properties;

  RelayOutput({required this.token, required this.properties});

  factory RelayOutput.fromJson(Map<String, dynamic> json) =>
      _$RelayOutputFromJson(json);

  Map<String, dynamic> toJson() => _$RelayOutputToJson(this);

  @override
  String toString() => json.encode(toJson());
}

/// Response for the GetRelayOutputs operation.
@JsonSerializable()
class GetRelayOutputsResponse {
  @JsonKey(name: 'RelayOutputs', fromJson: _fromJson)
  final List<RelayOutput> relayOutputs;

  GetRelayOutputsResponse(this.relayOutputs);

  factory GetRelayOutputsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetRelayOutputsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetRelayOutputsResponseToJson(this);

  @override
  String toString() => json.encode(toJson());

  static List<RelayOutput> _fromJson(dynamic json) =>
      OnvifUtil.jsonList<RelayOutput>(
        json,
        (json) => RelayOutput.fromJson(json as Map<String, dynamic>),
      );
}
```

- [ ] **Step 5: Add barrel exports** to `lib/device_management.dart` (alphabetical position, near the other device_management exports):

```dart
export 'src/model/device_management/relay_output.dart';
export 'src/model/device_management/relay_output_settings.dart';
```

- [ ] **Step 6: Add the request builders** to `lib/src/soap/device_management.dart` (inside `class DeviceManagementRequest`, e.g. after `setIpAddressFilter`):

```dart
  /// XML for the [getRelayOutputs]
  static XmlDocumentFragment getRelayOutputs() =>
      Transport.quickTag('GetRelayOutputs', Xmlns.tds);

  /// XML for the [setRelayOutputState]
  static XmlDocumentFragment setRelayOutputState({
    required String relayOutputToken,
    required RelayLogicalState logicalState,
  }) {
    builder.element(
      'SetRelayOutputState',
      nest: () {
        builder.namespace(Xmlns.tds);

        relayOutputToken.buildXml(builder, tag: 'RelayOutputToken');
        logicalState.value.buildXml(builder, tag: 'LogicalState');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setRelayOutputSettings]
  static XmlDocumentFragment setRelayOutputSettings({
    required String relayOutputToken,
    required RelayOutputSettings properties,
  }) {
    builder.element(
      'SetRelayOutputSettings',
      nest: () {
        builder.namespace(Xmlns.tds);

        relayOutputToken.buildXml(builder, tag: 'RelayOutputToken');
        properties.buildXml(builder, tag: 'Properties');
      },
    );

    return builder.buildFragment();
  }
```

- [ ] **Step 7: Add the public methods** to `lib/src/device_management.dart` (inside `class DeviceManagement`, e.g. after `getEndpointReference`):

```dart
  /// This operation gets a list of all available relay outputs and their
  /// settings.
  ///
  /// Access Class: READ_SYSTEM
  Future<List<RelayOutput>> getRelayOutputs() async {
    loggy.debug('getRelayOutputs');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getRelayOutputs()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetRelayOutputsResponse.fromJson(
      responseEnvelope.body.response!,
    ).relayOutputs;
  }

  /// This operation sets the state of a relay output.
  ///
  /// Access Class: ACTUATE
  Future<bool> setRelayOutputState({
    required String relayOutputToken,
    required RelayLogicalState logicalState,
  }) async {
    loggy.debug('setRelayOutputState');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.setRelayOutputState(
          relayOutputToken: relayOutputToken,
          logicalState: logicalState,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation sets the settings of a relay output.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setRelayOutputSettings({
    required String relayOutputToken,
    required RelayOutputSettings properties,
  }) async {
    loggy.debug('setRelayOutputSettings');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.setRelayOutputSettings(
          relayOutputToken: relayOutputToken,
          properties: properties,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }
```

- [ ] **Step 8: Generate code and run the tests.**

Run:
```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
dart run build_runner build --delete-conflicting-outputs
dart test test/soap_request_test.dart > /tmp/t1.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t1.log | tail -1
dart analyze 2>&1 | tail -1
```
Expected: all tests pass; `No issues found!`

- [ ] **Step 9: Commit**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
rtk git add lib/src/model/device_management/relay_output_settings.dart lib/src/model/device_management/relay_output_settings.g.dart lib/src/model/device_management/relay_output.dart lib/src/model/device_management/relay_output.g.dart lib/src/soap/device_management.dart lib/src/device_management.dart lib/device_management.dart test/soap_request_test.dart
rtk git commit -m "feat(device-management): relay output operations (get/set state/set settings)"
```


---

### Task 2: GeoLocation (`SetGeoLocation`, `DeleteGeoLocation`)

`GetGeoLocation` already exists. The reused `LocationEntity` model
(`lib/src/model/device_management/location_entity.dart`) is parse-only, so this
task adds a `buildXml` to it and exports it from the barrel.

**Files:**
- Modify: `lib/src/model/device_management/location_entity.dart`
- Modify: `lib/device_management.dart`
- Modify: `lib/src/soap/device_management.dart`
- Modify: `lib/src/device_management.dart`
- Test: `test/soap_request_test.dart`

- [ ] **Step 1: Write the failing tests.** Add to the Device Management group in `test/soap_request_test.dart`:

```dart
    test('setGeoLocation', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setGeoLocation([
          LocationEntity(geoLocation: GeoLocation(lat: 34.0, lon: 12.0)),
        ]),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetGeoLocation xmlns="http://www.onvif.org/ver10/device/wsdl"><Location><GeoLocation lon="12.0" lat="34.0"/></Location></SetGeoLocation></Test>',
      );
    });

    test('deleteGeoLocation', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.deleteGeoLocation([
          LocationEntity(geoLocation: GeoLocation(lat: 34.0, lon: 12.0)),
        ]),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><DeleteGeoLocation xmlns="http://www.onvif.org/ver10/device/wsdl"><Location><GeoLocation lon="12.0" lat="34.0"/></Location></DeleteGeoLocation></Test>',
      );
    });
```

- [ ] **Step 2: Run — verify FAIL.**

Run: `cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif && dart test test/soap_request_test.dart > /tmp/t2.log 2>&1; rtk grep -E "(All tests passed|Some tests failed|Error)" /tmp/t2.log | tail -1`

- [ ] **Step 3: Add `buildXml` to `LocationEntity`.** In `lib/src/model/device_management/location_entity.dart`:

Add imports (top of file):

```dart
import 'package:easy_onvif/src/model/common/xml_serializable.dart';
import 'package:xml/xml.dart';
```

Change the class declaration:

```dart
class LocationEntity implements XmlSerializable {
```

Add this method inside `class LocationEntity` (after `toString()`):

```dart
  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Location',
    String? namespace,
  }) => builder.element(
    tag,
    nest: () {
      if (namespace != null) builder.namespace(namespace);

      if (entity != null) builder.attribute('Entity', entity!);
      if (token != null) builder.attribute('Token', token!);
      if (fixed != null) builder.attribute('Fixed', fixed.toString());
      if (autoGeo != null) builder.attribute('AutoGeo', autoGeo.toString());

      final geo = geoLocation;
      if (geo != null) {
        builder.element('GeoLocation', nest: () {
          if (geo.lon != null) builder.attribute('lon', geo.lon.toString());
          if (geo.lat != null) builder.attribute('lat', geo.lat.toString());
          if (geo.elevation != null) {
            builder.attribute('elevation', geo.elevation.toString());
          }
        });
      }

      final orientation = geoOrientation;
      if (orientation != null) {
        builder.element('GeoOrientation', nest: () {
          if (orientation.roll != null) {
            builder.attribute('roll', orientation.roll.toString());
          }
          if (orientation.pitch != null) {
            builder.attribute('pitch', orientation.pitch.toString());
          }
          if (orientation.yaw != null) {
            builder.attribute('yaw', orientation.yaw.toString());
          }
        });
      }

      if (geoSource != null) geoSource!.buildXml(builder, tag: 'GeoSource');
    },
  );
```

- [ ] **Step 4: Export `location_entity.dart`** from `lib/device_management.dart` (alphabetical position):

```dart
export 'src/model/device_management/location_entity.dart';
```

- [ ] **Step 5: Add the request builders** to `lib/src/soap/device_management.dart`:

```dart
  /// XML for the [setGeoLocation]
  static XmlDocumentFragment setGeoLocation(List<LocationEntity> locations) {
    builder.element(
      'SetGeoLocation',
      nest: () {
        builder.namespace(Xmlns.tds);

        for (var location in locations) {
          location.buildXml(builder);
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [deleteGeoLocation]
  static XmlDocumentFragment deleteGeoLocation(List<LocationEntity> locations) {
    builder.element(
      'DeleteGeoLocation',
      nest: () {
        builder.namespace(Xmlns.tds);

        for (var location in locations) {
          location.buildXml(builder);
        }
      },
    );

    return builder.buildFragment();
  }
```

- [ ] **Step 6: Add the public methods** to `lib/src/device_management.dart`:

```dart
  /// This operation sets the geo location on the device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setGeoLocation(List<LocationEntity> locations) async {
    loggy.debug('setGeoLocation');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.setGeoLocation(locations)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation deletes the geo location on the device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> deleteGeoLocation(List<LocationEntity> locations) async {
    loggy.debug('deleteGeoLocation');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.deleteGeoLocation(locations)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }
```

- [ ] **Step 7: Run tests + analyze.**

Run:
```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
dart run build_runner build --delete-conflicting-outputs
dart test test/soap_request_test.dart > /tmp/t2.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t2.log | tail -1
dart analyze 2>&1 | tail -1
```
Expected: all tests pass; `No issues found!`

- [ ] **Step 8: Commit**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
rtk git add lib/src/model/device_management/location_entity.dart lib/device_management.dart lib/src/soap/device_management.dart lib/src/device_management.dart test/soap_request_test.dart
rtk git commit -m "feat(device-management): set/delete geo location operations"
```

---

### Task 3: Network setters (`SetHostname`, `SetHostnameFromDHCP`, `SetDNS`, `SetNTP`, `SetDynamicDNS`, `SetNetworkProtocols`)

These reuse existing models (`DnsInformation`/`DnsEntry`, `NtpInformation`/`Ntp`,
`DynamicDnsInformation`, `NetworkProtocol`); the builders construct XML from the
model fields inline (no model changes needed).

**Files:**
- Modify: `lib/src/soap/device_management.dart`
- Modify: `lib/src/device_management.dart`
- Test: `test/soap_request_test.dart`

- [ ] **Step 1: Write the failing tests.** Add to the Device Management group in `test/soap_request_test.dart`:

```dart
    test('setHostname', () {
      builder.element('Test', nest: DeviceManagementRequest.setHostname('camera1'));

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetHostname xmlns="http://www.onvif.org/ver10/device/wsdl"><Name>camera1</Name></SetHostname></Test>',
      );
    });

    test('setHostnameFromDhcp', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setHostnameFromDhcp(true),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetHostnameFromDHCP xmlns="http://www.onvif.org/ver10/device/wsdl"><FromDHCP>true</FromDHCP></SetHostnameFromDHCP></Test>',
      );
    });

    test('setDns', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setDns(
          DnsInformation(
            fromDhcp: false,
            searchDomain: ['example.com'],
            dnsManual: [
              DnsEntry(type: 'IPv4', ipv4Address: '8.8.8.8', ipv6Address: null),
            ],
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetDNS xmlns="http://www.onvif.org/ver10/device/wsdl"><FromDHCP>false</FromDHCP><SearchDomain>example.com</SearchDomain><DNSManual><Type>IPv4</Type><IPv4Address>8.8.8.8</IPv4Address></DNSManual></SetDNS></Test>',
      );
    });

    test('setNtp', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setNtp(
          NtpInformation(
            fromDhcp: false,
            ntpManual: [Ntp(type: 'IPv4', iPv4Address: '129.6.15.28')],
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetNTP xmlns="http://www.onvif.org/ver10/device/wsdl"><FromDHCP>false</FromDHCP><NTPManual><Type>IPv4</Type><IPv4Address>129.6.15.28</IPv4Address></NTPManual></SetNTP></Test>',
      );
    });

    test('setDynamicDns', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setDynamicDns(
          DynamicDnsInformation(
            type: DynamicDnsType.clientUpdates,
            name: 'host.example.com',
            ttl: 'PT1H',
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetDynamicDNS xmlns="http://www.onvif.org/ver10/device/wsdl"><Type>ClientUpdates</Type><Name>host.example.com</Name><TTL>PT1H</TTL></SetDynamicDNS></Test>',
      );
    });

    test('setNetworkProtocols', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setNetworkProtocols([
          NetworkProtocol(name: 'HTTP', enabled: true, port: 80),
        ]),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetNetworkProtocols xmlns="http://www.onvif.org/ver10/device/wsdl"><NetworkProtocols><Name>HTTP</Name><Enabled>true</Enabled><Port>80</Port></NetworkProtocols></SetNetworkProtocols></Test>',
      );
    });
```

- [ ] **Step 2: Run — verify FAIL.**

Run: `cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif && dart test test/soap_request_test.dart > /tmp/t3.log 2>&1; rtk grep -E "(All tests passed|Some tests failed|Error)" /tmp/t3.log | tail -1`

- [ ] **Step 3: Add the request builders** to `lib/src/soap/device_management.dart`:

```dart
  /// XML for the [setHostname]
  static XmlDocumentFragment setHostname(String name) {
    builder.element(
      'SetHostname',
      nest: () {
        builder.namespace(Xmlns.tds);

        name.buildXml(builder, tag: 'Name');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setHostnameFromDhcp]
  static XmlDocumentFragment setHostnameFromDhcp(bool fromDhcp) {
    builder.element(
      'SetHostnameFromDHCP',
      nest: () {
        builder.namespace(Xmlns.tds);

        fromDhcp.toString().buildXml(builder, tag: 'FromDHCP');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setDns]
  static XmlDocumentFragment setDns(DnsInformation dnsInformation) {
    builder.element(
      'SetDNS',
      nest: () {
        builder.namespace(Xmlns.tds);

        (dnsInformation.fromDhcp ?? false).toString().buildXml(
          builder,
          tag: 'FromDHCP',
        );

        for (var domain in dnsInformation.searchDomain ?? <String>[]) {
          domain.buildXml(builder, tag: 'SearchDomain');
        }

        for (var entry in dnsInformation.dnsManual ?? <DnsEntry>[]) {
          builder.element('DNSManual', nest: () {
            entry.type.buildXml(builder, tag: 'Type');

            if (entry.ipv4Address != null) {
              entry.ipv4Address!.buildXml(builder, tag: 'IPv4Address');
            }

            if (entry.ipv6Address != null) {
              entry.ipv6Address!.buildXml(builder, tag: 'IPv6Address');
            }
          });
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setNtp]
  static XmlDocumentFragment setNtp(NtpInformation ntpInformation) {
    builder.element(
      'SetNTP',
      nest: () {
        builder.namespace(Xmlns.tds);

        ntpInformation.fromDhcp.toString().buildXml(builder, tag: 'FromDHCP');

        for (var ntp in ntpInformation.ntpManual ?? <Ntp>[]) {
          builder.element('NTPManual', nest: () {
            ntp.type.buildXml(builder, tag: 'Type');

            if (ntp.iPv4Address != null) {
              ntp.iPv4Address!.buildXml(builder, tag: 'IPv4Address');
            }

            if (ntp.iPv6Address != null) {
              ntp.iPv6Address!.buildXml(builder, tag: 'IPv6Address');
            }

            if (ntp.dnsName != null) {
              ntp.dnsName!.buildXml(builder, tag: 'DNSname');
            }
          });
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setDynamicDns]
  static XmlDocumentFragment setDynamicDns(
    DynamicDnsInformation dynamicDnsInformation,
  ) {
    // ONVIF wire values for the tt:DynamicDNSType enumeration.
    const typeValues = {
      DynamicDnsType.noUpdate: 'NoUpdate',
      DynamicDnsType.clientUpdates: 'ClientUpdates',
      DynamicDnsType.serverUpdates: 'ServerUpdates',
    };

    builder.element(
      'SetDynamicDNS',
      nest: () {
        builder.namespace(Xmlns.tds);

        (typeValues[dynamicDnsInformation.type] ?? 'NoUpdate').buildXml(
          builder,
          tag: 'Type',
        );

        if (dynamicDnsInformation.name != null) {
          dynamicDnsInformation.name!.buildXml(builder, tag: 'Name');
        }

        if (dynamicDnsInformation.ttl != null) {
          dynamicDnsInformation.ttl!.buildXml(builder, tag: 'TTL');
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setNetworkProtocols]
  static XmlDocumentFragment setNetworkProtocols(
    List<NetworkProtocol> networkProtocols,
  ) {
    builder.element(
      'SetNetworkProtocols',
      nest: () {
        builder.namespace(Xmlns.tds);

        for (var protocol in networkProtocols) {
          builder.element('NetworkProtocols', nest: () {
            protocol.name.buildXml(builder, tag: 'Name');
            protocol.enabled.toString().buildXml(builder, tag: 'Enabled');
            protocol.port.toString().buildXml(builder, tag: 'Port');
          });
        }
      },
    );

    return builder.buildFragment();
  }
```

- [ ] **Step 4: Add the public methods** to `lib/src/device_management.dart`:

```dart
  /// This operation sets the hostname on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setHostname(String name) async {
    loggy.debug('setHostname');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.setHostname(name)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation controls whether the hostname shall be obtained via DHCP.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setHostnameFromDhcp(bool fromDhcp) async {
    loggy.debug('setHostnameFromDhcp');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.setHostnameFromDhcp(fromDhcp)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation sets the DNS settings on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setDns(DnsInformation dnsInformation) async {
    loggy.debug('setDns');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.setDns(dnsInformation)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation sets the NTP settings on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setNtp(NtpInformation ntpInformation) async {
    loggy.debug('setNtp');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.setNtp(ntpInformation)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation sets the dynamic DNS settings on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setDynamicDns(DynamicDnsInformation dynamicDnsInformation) async {
    loggy.debug('setDynamicDns');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.setDynamicDns(dynamicDnsInformation),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation configures one or more defined network protocols supported
  /// by the device (HTTP, HTTPS, RTSP).
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setNetworkProtocols(List<NetworkProtocol> networkProtocols) async {
    loggy.debug('setNetworkProtocols');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.setNetworkProtocols(networkProtocols),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }
```

- [ ] **Step 5: Run tests + analyze.**

Run:
```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
dart test test/soap_request_test.dart > /tmp/t3.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t3.log | tail -1
dart analyze 2>&1 | tail -1
```
Expected: all tests pass; `No issues found!`

- [ ] **Step 6: Commit**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
rtk git add lib/src/soap/device_management.dart lib/src/device_management.dart test/soap_request_test.dart
rtk git commit -m "feat(device-management): network setter operations (hostname/dns/ntp/dynamic-dns/protocols)"
```


---

### Task 4: Gateway + Zero-configuration (`GetNetworkDefaultGateway`, `SetNetworkDefaultGateway`, `GetZeroConfiguration`, `SetZeroConfiguration`)

**Files:**
- Create: `lib/src/model/device_management/network_gateway.dart`
- Create: `lib/src/model/device_management/network_zero_configuration.dart`
- Modify: `lib/device_management.dart`
- Modify: `lib/src/soap/device_management.dart`
- Modify: `lib/src/device_management.dart`
- Test: `test/soap_request_test.dart`

- [ ] **Step 1: Write the failing tests.** Add to the Device Management group in `test/soap_request_test.dart`:

```dart
    test('getNetworkDefaultGateway', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.getNetworkDefaultGateway(),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetNetworkDefaultGateway xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('setNetworkDefaultGateway', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setNetworkDefaultGateway(
          NetworkGateway(ipv4Addresses: ['192.168.0.1']),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetNetworkDefaultGateway xmlns="http://www.onvif.org/ver10/device/wsdl"><IPv4Address>192.168.0.1</IPv4Address></SetNetworkDefaultGateway></Test>',
      );
    });

    test('getZeroConfiguration', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.getZeroConfiguration(),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><GetZeroConfiguration xmlns="http://www.onvif.org/ver10/device/wsdl"/></Test>',
      );
    });

    test('setZeroConfiguration', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setZeroConfiguration(
          interfaceToken: 'eth0',
          enabled: true,
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetZeroConfiguration xmlns="http://www.onvif.org/ver10/device/wsdl"><InterfaceToken>eth0</InterfaceToken><Enabled>true</Enabled></SetZeroConfiguration></Test>',
      );
    });
```

- [ ] **Step 2: Run — verify FAIL.**

Run: `cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif && flutter test test/soap_request_test.dart > /tmp/t4.log 2>&1; rtk grep -E "(All tests passed|Some tests failed|Error)" /tmp/t4.log | tail -1`

- [ ] **Step 3: Create** `lib/src/model/device_management/network_gateway.dart`:

```dart
import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'network_gateway.g.dart';

/// Default gateway addresses (tt:NetworkGateway).
@JsonSerializable()
class NetworkGateway {
  @JsonKey(name: 'IPv4Address', fromJson: _parseUnboundString)
  final List<String> ipv4Addresses;

  @JsonKey(name: 'IPv6Address', fromJson: _parseUnboundString)
  final List<String> ipv6Addresses;

  NetworkGateway({
    this.ipv4Addresses = const [],
    this.ipv6Addresses = const [],
  });

  factory NetworkGateway.fromJson(Map<String, dynamic> json) =>
      _$NetworkGatewayFromJson(json);

  Map<String, dynamic> toJson() => _$NetworkGatewayToJson(this);

  @override
  String toString() => json.encode(toJson());

  static List<String> _parseUnboundString(dynamic json) {
    if (json == null) return [];

    if (json is List) {
      return json
          .map((e) => OnvifUtil.stringMappedFromXml(e as Map<String, dynamic>))
          .toList();
    }

    return [OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>)];
  }
}

/// Response for the GetNetworkDefaultGateway operation.
@JsonSerializable()
class GetNetworkDefaultGatewayResponse {
  @JsonKey(name: 'NetworkGateway')
  final NetworkGateway networkGateway;

  GetNetworkDefaultGatewayResponse(this.networkGateway);

  factory GetNetworkDefaultGatewayResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$GetNetworkDefaultGatewayResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GetNetworkDefaultGatewayResponseToJson(this);

  @override
  String toString() => json.encode(toJson());
}
```

- [ ] **Step 4: Create** `lib/src/model/device_management/network_zero_configuration.dart`:

```dart
import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'network_zero_configuration.g.dart';

/// Zero-configuration settings (tt:NetworkZeroConfiguration).
@JsonSerializable()
class NetworkZeroConfiguration {
  @JsonKey(name: 'InterfaceToken', fromJson: OnvifUtil.stringMappedFromXml)
  final String interfaceToken;

  @JsonKey(name: 'Enabled', fromJson: OnvifUtil.boolMappedFromXml)
  final bool enabled;

  @JsonKey(name: 'Addresses', fromJson: _parseUnboundString)
  final List<String> addresses;

  NetworkZeroConfiguration({
    required this.interfaceToken,
    required this.enabled,
    this.addresses = const [],
  });

  factory NetworkZeroConfiguration.fromJson(Map<String, dynamic> json) =>
      _$NetworkZeroConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$NetworkZeroConfigurationToJson(this);

  @override
  String toString() => json.encode(toJson());

  static List<String> _parseUnboundString(dynamic json) {
    if (json == null) return [];

    if (json is List) {
      return json
          .map((e) => OnvifUtil.stringMappedFromXml(e as Map<String, dynamic>))
          .toList();
    }

    return [OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>)];
  }
}

/// Response for the GetZeroConfiguration operation.
@JsonSerializable()
class GetZeroConfigurationResponse {
  @JsonKey(name: 'ZeroConfiguration')
  final NetworkZeroConfiguration zeroConfiguration;

  GetZeroConfigurationResponse(this.zeroConfiguration);

  factory GetZeroConfigurationResponse.fromJson(Map<String, dynamic> json) =>
      _$GetZeroConfigurationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetZeroConfigurationResponseToJson(this);

  @override
  String toString() => json.encode(toJson());
}
```

- [ ] **Step 5: Add barrel exports** to `lib/device_management.dart`:

```dart
export 'src/model/device_management/network_gateway.dart';
export 'src/model/device_management/network_zero_configuration.dart';
```

- [ ] **Step 6: Add the request builders** to `lib/src/soap/device_management.dart`:

```dart
  /// XML for the [getNetworkDefaultGateway]
  static XmlDocumentFragment getNetworkDefaultGateway() =>
      Transport.quickTag('GetNetworkDefaultGateway', Xmlns.tds);

  /// XML for the [setNetworkDefaultGateway]
  static XmlDocumentFragment setNetworkDefaultGateway(
    NetworkGateway networkGateway,
  ) {
    builder.element(
      'SetNetworkDefaultGateway',
      nest: () {
        builder.namespace(Xmlns.tds);

        for (var address in networkGateway.ipv4Addresses) {
          address.buildXml(builder, tag: 'IPv4Address');
        }

        for (var address in networkGateway.ipv6Addresses) {
          address.buildXml(builder, tag: 'IPv6Address');
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getZeroConfiguration]
  static XmlDocumentFragment getZeroConfiguration() =>
      Transport.quickTag('GetZeroConfiguration', Xmlns.tds);

  /// XML for the [setZeroConfiguration]
  static XmlDocumentFragment setZeroConfiguration({
    required String interfaceToken,
    required bool enabled,
  }) {
    builder.element(
      'SetZeroConfiguration',
      nest: () {
        builder.namespace(Xmlns.tds);

        interfaceToken.buildXml(builder, tag: 'InterfaceToken');
        enabled.toString().buildXml(builder, tag: 'Enabled');
      },
    );

    return builder.buildFragment();
  }
```

- [ ] **Step 7: Add the public methods** to `lib/src/device_management.dart`:

```dart
  /// This operation gets the default gateway settings from a device.
  ///
  /// Access Class: READ_SYSTEM
  Future<NetworkGateway> getNetworkDefaultGateway() async {
    loggy.debug('getNetworkDefaultGateway');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getNetworkDefaultGateway()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetNetworkDefaultGatewayResponse.fromJson(
      responseEnvelope.body.response!,
    ).networkGateway;
  }

  /// This operation sets the default gateway settings on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setNetworkDefaultGateway(NetworkGateway networkGateway) async {
    loggy.debug('setNetworkDefaultGateway');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.setNetworkDefaultGateway(
          networkGateway,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation gets the zero-configuration settings from a device.
  ///
  /// Access Class: READ_SYSTEM
  Future<NetworkZeroConfiguration> getZeroConfiguration() async {
    loggy.debug('getZeroConfiguration');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: DeviceManagementRequest.getZeroConfiguration()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetZeroConfigurationResponse.fromJson(
      responseEnvelope.body.response!,
    ).zeroConfiguration;
  }

  /// This operation sets the zero-configuration settings on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setZeroConfiguration({
    required String interfaceToken,
    required bool enabled,
  }) async {
    loggy.debug('setZeroConfiguration');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.setZeroConfiguration(
          interfaceToken: interfaceToken,
          enabled: enabled,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }
```

- [ ] **Step 8: Generate code, run tests + analyze.**

Run:
```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
dart run build_runner build --delete-conflicting-outputs
flutter test test/soap_request_test.dart > /tmp/t4.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t4.log | tail -1
dart analyze 2>&1 | tail -1
```
Expected: all tests pass; `No issues found!`

- [ ] **Step 9: Commit**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
rtk git add lib/src/model/device_management/network_gateway.dart lib/src/model/device_management/network_gateway.g.dart lib/src/model/device_management/network_zero_configuration.dart lib/src/model/device_management/network_zero_configuration.g.dart lib/device_management.dart lib/src/soap/device_management.dart lib/src/device_management.dart test/soap_request_test.dart
rtk git commit -m "feat(device-management): network default gateway and zero-configuration operations"
```

---

### Task 5: IP address filter (`SetIPAddressFilter`, `AddIPAddressFilter`, `RemoveIPAddressFilter`)

The `setIpAddressFilter` request builder already exists but has a namespace bug
(`Xmlns.trc` instead of `Xmlns.tds`) and no public method. This task fixes the
builder, adds `add`/`remove` builders, exposes all three public methods, and
fixes the `Type` enum so it serializes the correct ONVIF casing (`Allow`/`Deny`
rather than `allow`/`deny`).

**Files:**
- Modify: `lib/src/model/device_management/ipaddress_filter.dart`
- Modify: `lib/src/soap/device_management.dart`
- Modify: `lib/src/device_management.dart`
- Test: `test/soap_request_test.dart`

- [ ] **Step 1: Write the failing tests.** Add to the Device Management group in `test/soap_request_test.dart`:

```dart
    test('setIpAddressFilter', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.setIpAddressFilter(
          ipAddressFilter: IpAddressFilter(
            type: Type.allow,
            prefixedIpv4Addresses: [
              PrefixedIpv4Address(address: '192.168.0.10', prefixLength: 24),
            ],
            prefixedIpv6Addresses: [],
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><SetIPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><IPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><Type>Allow</Type><IPv4Address xmlns="http://www.onvif.org/ver10/device/wsdl"><Address>192.168.0.10</Address><PrefixLength>24</PrefixLength></IPv4Address></IPAddressFilter></SetIPAddressFilter></Test>',
      );
    });

    test('addIpAddressFilter', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.addIpAddressFilter(
          ipAddressFilter: IpAddressFilter(
            type: Type.deny,
            prefixedIpv4Addresses: [
              PrefixedIpv4Address(address: '10.0.0.5', prefixLength: 32),
            ],
            prefixedIpv6Addresses: [],
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><AddIPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><IPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><Type>Deny</Type><IPv4Address xmlns="http://www.onvif.org/ver10/device/wsdl"><Address>10.0.0.5</Address><PrefixLength>32</PrefixLength></IPv4Address></IPAddressFilter></AddIPAddressFilter></Test>',
      );
    });

    test('removeIpAddressFilter', () {
      builder.element(
        'Test',
        nest: DeviceManagementRequest.removeIpAddressFilter(
          ipAddressFilter: IpAddressFilter(
            type: Type.allow,
            prefixedIpv4Addresses: [
              PrefixedIpv4Address(address: '192.168.0.10', prefixLength: 24),
            ],
            prefixedIpv6Addresses: [],
          ),
        ),
      );

      expect(
        builder.buildDocument().toXmlString(),
        '<Test><RemoveIPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><IPAddressFilter xmlns="http://www.onvif.org/ver10/device/wsdl"><Type>Allow</Type><IPv4Address xmlns="http://www.onvif.org/ver10/device/wsdl"><Address>192.168.0.10</Address><PrefixLength>24</PrefixLength></IPv4Address></IPAddressFilter></RemoveIPAddressFilter></Test>',
      );
    });
```

> **Note on the expected XML:** `Transport.builder` is an `XmlBuilder` with
> `optimizeNamespaces=false`, so every element whose `buildXml` declares the
> `tds` namespace emits its own `xmlns="…/device/wsdl"` (hence the repeated
> declarations on `IPAddressFilter` and `IPv4Address`). Run the test first; if
> your `package:xml` version serializes the namespaces differently, adjust the
> expected string to the actual `buildDocument().toXmlString()` output.

- [ ] **Step 2: Run — verify FAIL** (`addIpAddressFilter`/`removeIpAddressFilter` undefined; `setIpAddressFilter` produces the wrong namespace/casing).

Run: `cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif && flutter test test/soap_request_test.dart > /tmp/t5.log 2>&1; rtk grep -E "(All tests passed|Some tests failed|Error)" /tmp/t5.log | tail -1`

- [ ] **Step 3: Fix the `Type` enum casing** in `lib/src/model/device_management/ipaddress_filter.dart`. Replace:

```dart
enum Type {
  @JsonValue("Allow")
  allow,
  @JsonValue("Deny")
  deny,
}
```

with:

```dart
enum Type {
  @JsonValue('Allow')
  allow('Allow'),
  @JsonValue('Deny')
  deny('Deny');

  /// The ONVIF wire value (e.g. `Allow`).
  final String value;
  const Type(this.value);
}
```

and in `IpAddressFilter.buildXml`, replace:

```dart
      type.name.buildXml(builder, tag: 'Type');
```

with:

```dart
      type.value.buildXml(builder, tag: 'Type');
```

- [ ] **Step 4: Fix + add the request builders** in `lib/src/soap/device_management.dart`. Replace the existing `setIpAddressFilter` builder:

```dart
  /// XML for the [setIpAddressFilter]
  static XmlDocumentFragment setIpAddressFilter({
    required IpAddressFilter ipAddressFilter,
  }) {
    builder.element(
      'SetIPAddressFilter',
      namespace: Xmlns.trc,
      nest: () => ipAddressFilter.buildXml(
        builder,
        tag: 'IPAddressFilter',
        namespace: Xmlns.tds,
      ),
    );

    return builder.buildFragment();
  }
```

with these three builders:

```dart
  /// XML for the [setIpAddressFilter]
  static XmlDocumentFragment setIpAddressFilter({
    required IpAddressFilter ipAddressFilter,
  }) => _ipAddressFilter('SetIPAddressFilter', ipAddressFilter);

  /// XML for the [addIpAddressFilter]
  static XmlDocumentFragment addIpAddressFilter({
    required IpAddressFilter ipAddressFilter,
  }) => _ipAddressFilter('AddIPAddressFilter', ipAddressFilter);

  /// XML for the [removeIpAddressFilter]
  static XmlDocumentFragment removeIpAddressFilter({
    required IpAddressFilter ipAddressFilter,
  }) => _ipAddressFilter('RemoveIPAddressFilter', ipAddressFilter);

  static XmlDocumentFragment _ipAddressFilter(
    String operation,
    IpAddressFilter ipAddressFilter,
  ) {
    builder.element(
      operation,
      nest: () {
        builder.namespace(Xmlns.tds);

        ipAddressFilter.buildXml(builder, tag: 'IPAddressFilter');
      },
    );

    return builder.buildFragment();
  }
```

- [ ] **Step 5: Add the public methods** to `lib/src/device_management.dart` (note: a commented-out `setIpAddressFilter` may exist near the bottom — replace/remove it):

```dart
  /// This operation sets the IP address filter on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> setIpAddressFilter({
    required IpAddressFilter ipAddressFilter,
  }) async {
    loggy.debug('setIpAddressFilter');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.setIpAddressFilter(
          ipAddressFilter: ipAddressFilter,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation adds an IP address filter entry on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> addIpAddressFilter({
    required IpAddressFilter ipAddressFilter,
  }) async {
    loggy.debug('addIpAddressFilter');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.addIpAddressFilter(
          ipAddressFilter: ipAddressFilter,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This operation removes an IP address filter entry on a device.
  ///
  /// Access Class: WRITE_SYSTEM
  Future<bool> removeIpAddressFilter({
    required IpAddressFilter ipAddressFilter,
  }) async {
    loggy.debug('removeIpAddressFilter');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: DeviceManagementRequest.removeIpAddressFilter(
          ipAddressFilter: ipAddressFilter,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }
```

- [ ] **Step 6: Generate code, run tests + analyze.**

Run:
```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
dart run build_runner build --delete-conflicting-outputs
flutter test test/soap_request_test.dart > /tmp/t5.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t5.log | tail -1
dart analyze 2>&1 | tail -1
```
Expected: all tests pass; `No issues found!`

- [ ] **Step 7: Commit**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
rtk git add lib/src/model/device_management/ipaddress_filter.dart lib/src/model/device_management/ipaddress_filter.g.dart lib/src/soap/device_management.dart lib/src/device_management.dart test/soap_request_test.dart
rtk git commit -m "feat(device-management): set/add/remove IP address filter operations"
```


---

### Task 6: README operations matrix + final verification

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update the Device Management table.** In `README.md`, replace the existing `### Device Management` operations table (the rows between the header separator and `### Imaging`) with the full table below, which adds the new operations (and documents the pre-existing `GetDynamicDNS`/`GetGeoLocation` that were previously unlisted):

```markdown
| Onvif Operation             | Dart Method                 | Dart Return Type                       | Test |
| --------------------------- | --------------------------- | -------------------------------------- | ---- |
| AddIPAddressFilter          | addIpAddressFilter          | `Future<bool>`                         | [x\] |
| CreateUsers                 | createUsers                 | `Future<bool>`                         | [x\] |
| DeleteGeoLocation           | deleteGeoLocation           | `Future<bool>`                         | [x\] |
| DeleteUsers                 | deleteUsers                 | `Future<bool>`                         | [x\] |
| GetCapabilities             | getCapabilities             | `Future<Capabilities>`                 | [x\] |
| GetDeviceInformation        | getDeviceInformation        | `Future<GetDeviceInformationResponse>` | [x\] |
| GetDiscoveryMode            | getDiscoveryMode            | `Future<String>`                       | [x\] |
| GetDNS                      | getDNS                      | `Future<DnsInformation>`               | [x\] |
| GetDynamicDNS               | getDynamicDns               | `Future<DynamicDnsInformation>`        | [ \] |
| GetEndpointReference        | getEndpointReference        | `Future<Map<String, dynamic>>`         | [ \] |
| GetGeoLocation              | getGeoLocation              | `Future<dynamic>`                      | [ \] |
| GetHostname                 | getHostname                 | `Future<HostnameInformation>`          | [x\] |
| GetIPAddressFilter          | getIPAddressFilter          | `Future<IpAddressFilter>`              | [ \] |
| GetNetworkDefaultGateway    | getNetworkDefaultGateway    | `Future<NetworkGateway>`               | [x\] |
| GetNetworkProtocols         | getNetworkProtocols         | `Future<List<NetworkProtocol>>`        | [x\] |
| GetNTP                      | getNtp                      | `Future<NtpInformation>`               | [x\] |
| GetRelayOutputs             | getRelayOutputs             | `Future<List<RelayOutput>>`            | [x\] |
| GetServiceCapabilities      | getServiceCapabilities      | `Future<DeviceServiceCapabilities>`    | [x\] |
| GetServices                 | getServices                 | `Future<List<Service>>`                | [x\] |
| GetStorageConfiguration     | getStorageConfiguration     | `Future<StorageConfiguration>`         | [ \] |
| GetStorageConfigurations    | getStorageConfigurations    | `Future<List<StorageConfiguration>>`   | [ \] |
| GetSystemDateAndTime        | getSystemDateAndTime        | `Future<SystemDateAndTime>`            | [x\] |
| GetSystemLog                | getSystemLog                | `Future<SystemInformation>`            | [ \] |
| GetSystemSupportInformation | getSystemSupportInformation | `Future<SystemInformation>`            | [ \] |
| GetSystemUris               | getSystemUris               | `Future<GetSystemUrisResponse>`        | [x\] |
| GetUsers                    | getUsers                    | `Future<List<User>>`                   | [x\] |
| GetZeroConfiguration        | getZeroConfiguration        | `Future<NetworkZeroConfiguration>`     | [x\] |
| RemoveIPAddressFilter       | removeIpAddressFilter       | `Future<bool>`                         | [x\] |
| SetDNS                      | setDns                      | `Future<bool>`                         | [x\] |
| SetDynamicDNS               | setDynamicDns               | `Future<bool>`                         | [x\] |
| SetGeoLocation              | setGeoLocation              | `Future<bool>`                         | [x\] |
| SetHostname                 | setHostname                 | `Future<bool>`                         | [x\] |
| SetHostnameFromDHCP         | setHostnameFromDhcp         | `Future<bool>`                         | [x\] |
| SetIPAddressFilter          | setIpAddressFilter          | `Future<bool>`                         | [x\] |
| SetNetworkDefaultGateway    | setNetworkDefaultGateway    | `Future<bool>`                         | [x\] |
| SetNetworkProtocols         | setNetworkProtocols         | `Future<bool>`                         | [x\] |
| SetNTP                      | setNtp                      | `Future<bool>`                         | [x\] |
| SetRelayOutputSettings      | setRelayOutputSettings      | `Future<bool>`                         | [x\] |
| SetRelayOutputState         | setRelayOutputState         | `Future<bool>`                         | [x\] |
| SetZeroConfiguration        | setZeroConfiguration        | `Future<bool>`                         | [x\] |
| SystemReboot                | systemReboot                | `Future<String>`                       | [ \] |
```

- [ ] **Step 2: Final verification — full test suite + analyze.**

Run:
```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
dart run build_runner build --delete-conflicting-outputs
dart analyze 2>&1 | tail -1
dart test > /tmp/t6.log 2>&1; rtk grep -E "(All tests passed|Some tests failed)" /tmp/t6.log | tail -1
```
Expected: `No issues found!`; all tests pass (existing suite plus the new request-construction tests).

- [ ] **Step 3: Commit**

```bash
cd /Users/chrisdavis/projects/my/easy_onvif_workspace/packages/easy_onvif
rtk git add README.md
rtk git commit -m "docs(device-management): document relay/geo/network operations in README matrix"
```

---

## Self-Review Notes

- **Spec coverage:** Design groups A–D are fully covered — A (Relay I/O) → Task 1; B (GeoLocation set/delete) → Task 2; C (network setters) → Task 3; D (gateway/zero-config/IP-filter) → Tasks 4–5. README matrix → Task 6. Deferred items (E network interfaces, F Dot11, Events service) are intentionally out of scope per the design doc.
- **Type consistency:** builder method names match the public methods and tests across all tasks (`getRelayOutputs`/`setRelayOutputState`/`setRelayOutputSettings`; `setGeoLocation`/`deleteGeoLocation`; `setHostname`/`setHostnameFromDhcp`/`setDns`/`setNtp`/`setDynamicDns`/`setNetworkProtocols`; `getNetworkDefaultGateway`/`setNetworkDefaultGateway`/`getZeroConfiguration`/`setZeroConfiguration`; `setIpAddressFilter`/`addIpAddressFilter`/`removeIpAddressFilter`). Models: `RelayOutput`/`RelayOutputSettings`/`RelayMode`/`RelayIdleState`/`RelayLogicalState`, `NetworkGateway`, `NetworkZeroConfiguration`, reused `LocationEntity`/`GeoLocation`, `DnsInformation`/`DnsEntry`, `NtpInformation`/`Ntp`, `DynamicDnsInformation`/`DynamicDnsType`, `NetworkProtocol`, `IpAddressFilter`/`PrefixedIpv4Address`.
- **Verified against source:** request element children from `devicemgmt.wsdl`; `tt:` type shapes from `onvif.xsd`; model/`buildXml`/`@token`/enum-`fromJson` patterns from the existing codebase; `XmlBuilder` namespace behavior (`optimizeNamespaces=false`) from `package:xml` source.
- **Known risk (flagged inline):** the IP-filter expected-XML strings (Task 5) depend on `package:xml` emitting a repeated `xmlns` on each nested `buildXml`; a verify-note instructs matching the actual serialization if a `package:xml` version differs.
- **Environment note:** `dart run build_runner build --delete-conflicting-outputs` must run after every model change to regenerate `.g.dart` before tests/analyze will pass.
