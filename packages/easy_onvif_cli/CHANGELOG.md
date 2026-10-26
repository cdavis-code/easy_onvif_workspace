# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [3.3.0] - 2026-10-26

* Credentials are read through `easy_onvif`'s encrypted bundle; plaintext files
  keep working. New global options `--device` and `--key-file`, plus `--prompt`
  to seal writes with a passphrase.
* New `onvif credentials` command group: `init`, `add`, `remove`, `list`
  (`--site`/`--tag`), `default`, `migrate`, `key init`, `key rotate`.
* `onvif authorize` is now an alias for `credentials init` and never writes a
  plaintext file.
* `ONVIF_HOST` / `ONVIF_USERNAME` / `ONVIF_PASSWORD` still override any file;
  setting only some of them is now an error instead of a mix of sources.

## [3.2.0] - 2026-10-26

* No CLI changes; version bumped to stay locked with `easy_onvif` 3.2.0, which moved the Node.js host bindings into `package:easy_onvif/node.dart`.

## [3.1.6] - 2026-10-25

### Changed
- Repository metadata now points at the `cdavis-code` GitHub organization, clearing the pub.dev repository-URL verification failure
- Released in lock-step with `easy_onvif 3.1.6` (the two packages are version-locked); the dependency constraint stays `^3.1.5` so resolution works before 3.1.6 is on pub.dev

## [3.1.5] - 2026-07-28

### Added
- 18 new `device-management` subcommands covering relay I/O, geo-location, hostname, DNS, NTP, dynamic DNS, network protocols, default gateway, zero-configuration, and IP address filter add/remove
- `ptz get-presets-map` helper command
- `media2 delete-profile` command
- `media2 get-webrtc-configurations` command
- `media2 set-webrtc-configurations` command

### Fixed
- `device-management set-ipaddress-filter` now correctly calls `setIpAddressFilter()` instead of `getUsers()`

## [3.1.4] - 2025-04-28

### Added
- `issue_tracker` to pubspec.yaml for improved user support
- `topics` to pubspec.yaml for better pub.dev discoverability

### Changed
- Updated dependency to `easy_onvif ^3.1.4`
- Removed tracked `.iml` files from git (now properly ignored via `.gitignore`)

## [3.1.3+1]

### Changed
- Dependency bump

## [3.1.3]

### Changed
- Dependency bump

## [3.1.2]

### Added
- GetDynamicDnsDevice command support

## [3.1.1+6]

### Added
- GetDynamicDnsDevice command support

## [3.1.0+4]

### Fixed
- Probe proxy bug fix
- Log-level options no longer case sensitive

## [3.1.0+3]

### Fixed
- Fix axis usage in ptz zoom-out method (#64)

## [3.1.0+2]

### Changed
- Extracted CLI into a separate package from easy_onvif

## [3.1.0]

### Changed
- Extracted CLI into a separate package from easy_onvif
