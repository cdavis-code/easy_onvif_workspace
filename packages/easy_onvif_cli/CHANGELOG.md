# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
