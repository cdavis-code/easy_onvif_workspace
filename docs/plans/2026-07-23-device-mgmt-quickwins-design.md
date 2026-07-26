# Device Management Quick-Wins — Design

## Goal

Close the highest-value gaps in the `easy_onvif` client's **Device Management**
(`tds`) coverage, grounded in the ONVIF Core Specification (Ch. 8) and the
`devicemgmt.wsdl`. Add the missing **Relay I/O**, **GeoLocation**, and
**Network configuration** operations that real devices expose and that the
client currently lacks.

## Scope

**In scope (groups A–D):**

| Group | Operations |
|-------|-----------|
| **A — Relay I/O** | `GetRelayOutputs`, `SetRelayOutputState`, `SetRelayOutputSettings` |
| **B — GeoLocation** | `SetGeoLocation`, `DeleteGeoLocation` (`GetGeoLocation` already exists) |
| **C — Network setters** | `SetHostname`, `SetHostnameFromDHCP`, `SetDNS`, `SetNTP`, `SetDynamicDNS`, `SetNetworkProtocols` |
| **D — Network gateway / zero-config / IP filter** | `GetNetworkDefaultGateway`, `SetNetworkDefaultGateway`, `GetZeroConfiguration`, `SetZeroConfiguration`, `SetIPAddressFilter`, `AddIPAddressFilter`, `RemoveIPAddressFilter` |

**Deferred (explicitly out of scope):**
- **E — Network interfaces** (`Get/SetNetworkInterfaces`) — deep `tt:NetworkInterface` type hierarchy; large effort.
- **F — Dot11/Wi-Fi** (`GetDot11Capabilities`, `GetDot11Status`, `ScanAvailableDot11Networks`) — niche.
- The **Events service** (Ch. 9) — separate, larger effort (recommended next after this).

## Per-operation implementation pattern

Every operation follows the codebase's established 6-step pattern:

1. **SOAP request builder** — static method on `DeviceManagementRequest`
   (`lib/src/soap/device_management.dart`) returning an `XmlDocumentFragment`
   (`Transport.quickTag(...)` for no-arg Gets; nested `builder.element(...)`
   otherwise). Namespace is `Xmlns.tds`.
2. **Model classes** — json_serializable response wrapper + any new entity types
   in `lib/src/model/device_management/`, then `dart run build_runner build` to
   generate `.g.dart`.
3. **Public method** — async method on `DeviceManagement`
   (`lib/src/device_management.dart`): `transport.securedRequest(uri,
   soap.Body(request: ...))`, throw on `hasFault`, parse with
   `XxxResponse.fromJson(...)`.
4. **Barrel export** — add new model files to `lib/device_management.dart`.
5. **Request-construction test** — in `test/soap_request_test.dart`, wrap the
   builder fragment in a `<Test>` element and assert the exact XML string (no
   device required — the codebase's standard gate).
6. **README matrix** — add rows to the Device Management table in
   `packages/easy_onvif/README.md`.

## Return types

- **Get** operations return typed results:
  - `getRelayOutputs` → `Future<List<RelayOutput>>`
  - `getNetworkDefaultGateway` → `Future<NetworkGateway>`
  - `getZeroConfiguration` → `Future<NetworkZeroConfiguration>`
- **Set / Add / Remove / Delete** operations return `Future<bool>` (throw on
  SOAP fault), matching `createUsers`/`deleteUsers`.

## New model classes

| Model | Shape (from `onvif.xsd`) |
|-------|--------------------------|
| `RelayOutputSettings` | `Mode` (`RelayMode`: Monostable/Bistable), `DelayTime` (duration string), `IdleState` (`RelayIdleState`: closed/open) |
| `RelayOutput` | `token` attr + `Properties` (`RelayOutputSettings`) |
| `GetRelayOutputsResponse` | `RelayOutputs` → `List<RelayOutput>` |
| `NetworkGateway` | `IPv4Address` list, `IPv6Address` list |
| `GetNetworkDefaultGatewayResponse` | `NetworkGateway` |
| `NetworkZeroConfiguration` | `InterfaceToken`, `Enabled`, `Addresses` (IPv4 list) |
| `GetZeroConfigurationResponse` | `ZeroConfiguration` (`NetworkZeroConfiguration`) |

**Reused as-is:** `LocationEntity`, `GetGeoLocationResponse`, `DnsInformation`,
`NtpInformation`/`Ntp`, `DynamicDnsInformation`, `NetworkProtocol`,
`HostnameInformation`, `IpAddressFilter`, `PrefixIpAddress`/`PrefixIPv4Address`/
`PrefixIPv6Address`.

## Request element children (from `devicemgmt.wsdl`)

| Operation | Request children |
|-----------|------------------|
| `SetHostname` | `Name` (token) |
| `SetHostnameFromDHCP` | `FromDHCP` (boolean) |
| `SetDNS` | `FromDHCP` (bool), `SearchDomain` (token\*), `DNSManual` (IPAddress\*) |
| `SetNTP` | `FromDHCP` (bool), `NTPManual` (NetworkHost\*) |
| `SetDynamicDNS` | `Type` (DynamicDNSType), `Name` (DNSName?), `TTL` (duration?) |
| `SetNetworkProtocols` | `NetworkProtocols` (NetworkProtocol+) |
| `SetRelayOutputState` | `RelayOutputToken` (ReferenceToken), `LogicalState` (RelayLogicalState: active/inactive) |
| `SetRelayOutputSettings` | `RelayOutputToken` (ReferenceToken), `Properties` (RelayOutputSettings) |
| `SetGeoLocation` / `DeleteGeoLocation` | `Location` (LocationEntity+) |
| `SetNetworkDefaultGateway` | `IPv4Address`\*, `IPv6Address`\* |
| `SetZeroConfiguration` | `InterfaceToken` (ReferenceToken), `Enabled` (bool) |
| `SetIPAddressFilter` / `AddIPAddressFilter` / `RemoveIPAddressFilter` | `IPAddressFilter` (IPAddressFilter) |

## Access classes

Set/Add/Remove/Delete and relay-actuation operations are `WRITE_SYSTEM`
(Administrator only); Get operations are `READ_SYSTEM`. Documented per method
doc comment, matching the existing style.

## Testing strategy

- **Primary gate:** request-construction tests in `test/soap_request_test.dart`
  asserting exact XML for every new builder (no device needed).
- **Response parsing:** for new Get response models (`RelayOutput`,
  `NetworkGateway`, `NetworkZeroConfiguration`), add `fromJson` tests using
  small hand-crafted XML envelopes consistent with the WSDL types.
- Run `dart run build_runner build` after adding models; `dart analyze` and
  `dart test` must stay green.

## Notes

- `getGeoLocation` currently returns `Future<dynamic>`; this design leaves it as
  is (out of scope) but the new `SetGeoLocation`/`DeleteGeoLocation` reuse the
  existing `LocationEntity` model.
- The existing `setIpAddressFilter` builder uses `namespace: Xmlns.trc` (likely
  a copy/paste bug); the IP-filter task corrects it to `Xmlns.tds` and exposes
  the public method (currently commented out).
