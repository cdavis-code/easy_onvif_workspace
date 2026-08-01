# Easy Onvif Command Line Interface (CLI)

![SDK version](https://flat.badgen.net/pub/sdk-version/easy_onvif_cli?style=for-the-badge)
![Supported platforms](https://flat.badgen.net/pub/flutter-platform/easy_onvif_cli?style=for-the-badge)
![Supported SDKs](https://flat.badgen.net/pub/dart-platform/easy_onvif_cli?style=for-the-badge)

A command line interface application for controlling an Onvif device through terminal commands.  This tool allows you to use O/S features like `cron` to automate Onvif device functionality.

<!-- [![Build Status](https://img.shields.io/github/actions/workflow/status/cdavis-code/easy_onvif_cli/dart.yml?branch=main&logo=github-actions&logoColor=white&style=for-the-badge)](https://github.com/cdavis-code/easy_onvif_cli/actions) -->
[![Pull Requests](https://img.shields.io/github/issues-pr/cdavis-code/easy_onvif_workspace?logo=github&logoColor=white&style=for-the-badge)](https://github.com/cdavis-code/easy_onvif_workspace/pulls)
[![Issues](https://img.shields.io/github/issues/cdavis-code/easy_onvif_workspace?logo=github&logoColor=white&style=for-the-badge)](https://github.com/cdavis-code/easy_onvif_workspace/issues)
[![github last commit](https://shields.io/github/last-commit/cdavis-code/easy_onvif_workspace?logo=github&logoColor=white&style=for-the-badge)](https://shields.io/github/last-commit/cdavis-code/easy_onvif_workspace)
[![Pub Score](https://img.shields.io/pub/points/easy_onvif_cli?logo=dart&logoColor=00b9fc&style=for-the-badge)](https://pub.dev/packages/easy_onvif_cli/score)

## Table of Contents
- [Easy Onvif Command Line Interface (CLI)](#easy-onvif-command-line-interface-cli)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Quick start](#quick-start)
  - [Commands](#commands)
    - [authorize](#authorize)
    - [device-management](#device-management)
      - [device-management create-users](#device-management-create-users)
      - [device-management delete-users](#device-management-delete-users)
      - [device-management get-capabilities](#device-management-get-capabilities)
      - [device-management get-device-information](#device-management-get-device-information)
      - [device-management get-discovery-mode](#device-management-get-discovery-mode)
      - [device-management get-dns](#device-management-get-dns)
      - [device-management get-endpoint-reference](#device-management-get-endpoint-reference)
      - [device-management get-hostname](#device-management-get-hostname)
      - [device-management get-network-protocols](#device-management-get-network-protocols)
      - [device-management get-ntp](#device-management-get-ntp)
      - [device-management get-service-capabilities](#device-management-get-service-capabilities)
      - [device-management get-services](#device-management-get-services)
      - [device-management get-storage-configuration](#device-management-get-storage-configuration)
      - [device-management get-storage-configurations](#device-management-get-storage-configurations)
      - [device-management get-system-date-and-time](#device-management-get-system-date-and-time)
      - [device-management get-system-log](#device-management-get-system-log)
      - [device-management get-system-support-information](#device-management-get-system-support-information)
      - [device-management get-system-uris](#device-management-get-system-uris)
      - [device-management get-users](#device-management-get-users)
      - [device-management get-dynamic-dns](#device-management-get-dynamic-dns)
      - [device-management get-geolocation](#device-management-get-geolocation)
      - [device-management get-ipaddress-filter](#device-management-get-ipaddress-filter)
      - [device-management system-reboot](#device-management-system-reboot)
      - [device-management add-ip-address-filter](#device-management-add-ip-address-filter)
      - [device-management delete-geolocation](#device-management-delete-geolocation)
      - [device-management get-network-default-gateway](#device-management-get-network-default-gateway)
      - [device-management get-relay-outputs](#device-management-get-relay-outputs)
      - [device-management get-zero-configuration](#device-management-get-zero-configuration)
      - [device-management remove-ip-address-filter](#device-management-remove-ip-address-filter)
      - [device-management set-dns](#device-management-set-dns)
      - [device-management set-dynamic-dns](#device-management-set-dynamic-dns)
      - [device-management set-geolocation](#device-management-set-geolocation)
      - [device-management set-hostname](#device-management-set-hostname)
      - [device-management set-hostname-from-dhcp](#device-management-set-hostname-from-dhcp)
      - [device-management set-ipaddress-filter](#device-management-set-ipaddress-filter)
      - [device-management set-network-default-gateway](#device-management-set-network-default-gateway)
      - [device-management set-network-protocols](#device-management-set-network-protocols)
      - [device-management set-ntp](#device-management-set-ntp)
      - [device-management set-relay-output-settings](#device-management-set-relay-output-settings)
      - [device-management set-relay-output-state](#device-management-set-relay-output-state)
      - [device-management set-zero-configuration](#device-management-set-zero-configuration)
    - [debug](#debug)
    - [media1](#media1)
      - [media1 get-audio-sources](#media1-get-audio-sources)
      - [media1 get-metadata-configuration](#media1-get-metadata-configuration)
      - [media1 get-metadata-configuration](#media1-get-metadata-configuration-1)
      - [media1 get-profile](#media1-get-profile)
      - [media1 get-profiles](#media1-get-profiles)
      - [media1 get-service-capabilities](#media1-get-service-capabilities)
        - [media1 get-snapshot-uri](#media1-get-snapshot-uri)
      - [media1 get-stream-uri](#media1-get-stream-uri)
      - [media1 get-video-sources](#media1-get-video-sources)
      - [media1 start-multicast-streaming](#media1-start-multicast-streaming)
      - [media1 stop-multicast-streaming](#media1-stop-multicast-streaming)
    - [media2](#media2)
      - [media2 get-metadata-configuration-options](#media2-get-metadata-configuration-options)
      - [media2 get-metadata-configurations](#media2-get-metadata-configurations)
      - [media2 get-profiles](#media2-get-profiles)
      - [media2 get-service-capabilities](#media2-get-service-capabilities)
      - [media2 get-snapshot-uri](#media2-get-snapshot-uri)
      - [media2 get-stream-uri](#media2-get-stream-uri)
      - [media2 get-video-encoder-instances](#media2-get-video-encoder-instances)
      - [media2 delete-profile](#media2-delete-profile)
      - [media2 get-webrtc-configurations](#media2-get-webrtc-configurations)
      - [media2 set-webrtc-configurations](#media2-set-webrtc-configurations)
      - [media2 start-multicast-streaming](#media2-start-multicast-streaming)
      - [media2 stop-multicast-streaming](#media2-stop-multicast-streaming)
    - [probe](#probe)
    - [ptz](#ptz)
      - [ptz absolute-move](#ptz-absolute-move)
      - [ptz continuous-move](#ptz-continuous-move)
    - [ptz get-compatible-configurations](#ptz-get-compatible-configurations)
      - [ptz get-configuration](#ptz-get-configuration)
      - [ptz get-configuration-options](#ptz-get-configuration-options)
      - [ptz get-configurations](#ptz-get-configurations)
      - [ptz get-current-preset](#ptz-get-current-preset)
      - [ptz get-preset-tour](#ptz-get-preset-tour)
      - [ptz get-preset-tours](#ptz-get-preset-tours)
      - [ptz get-presets](#ptz-get-presets)
      - [ptz get-presets-map](#ptz-get-presets-map)
      - [ptz get-service-capabilities](#ptz-get-service-capabilities)
      - [ptz get-status](#ptz-get-status)
      - [ptz goto-preset](#ptz-goto-preset)
      - [ptz move](#ptz-move)
      - [ptz move-down](#ptz-move-down)
      - [ptz move-left](#ptz-move-left)
      - [ptz move-right](#ptz-move-right)
      - [ptz move-up](#ptz-move-up)
      - [ptz relative-move](#ptz-relative-move)
      - [ptz remove-preset](#ptz-remove-preset)
      - [ptz set-home-position](#ptz-set-home-position)
      - [ptz set-preset](#ptz-set-preset)
      - [ptz stop](#ptz-stop)
      - [ptz zoom](#ptz-zoom)
      - [ptz zoom-in](#ptz-zoom-in)
      - [ptz zoom-out](#ptz-zoom-out)
    - [recordings](#recordings)
      - [recordings create-recording](#recordings-create-recording)
      - [recordings create-recording-job](#recordings-create-recording-job)
      - [recordings delete-recording-job](#recordings-delete-recording-job)
      - [recordings delete-recordings](#recordings-delete-recordings)
      - [recordings get-recording-job-state](#recordings-get-recording-job-state)
      - [recordings get-recording-jobs](#recordings-get-recording-jobs)
      - [recordings get-recording-options](#recordings-get-recording-options)
      - [recordings get-recordings](#recordings-get-recordings)
      - [recordings get-service-capabilities](#recordings-get-service-capabilities)
      - [recordings set-recording-job-mode](#recordings-set-recording-job-mode)
    - [replay](#replay)
      - [replay get-replay-configuration](#replay-get-replay-configuration)
      - [replay get-replay-uri](#replay-get-replay-uri)
      - [replay get-service-capabilities](#replay-get-service-capabilities)
      - [replay set-replay-configuration](#replay-set-replay-configuration)
    - [version](#version)

[![Buy me a coffee](https://www.buymeacoffee.com/assets/img/guidelines/download-assets-1.svg)](https://www.buymeacoffee.com/faithoflif2)

[![Pub Package](https://img.shields.io/pub/v/easy_onvif_cli.svg?logo=dart&logoColor=00b9fc&color=blue&style=for-the-badge)](https://pub.dartlang.org/packages/easy_onvif_cli)
[![Publisher](https://img.shields.io/pub/publisher/easy_onvif_cli?style=for-the-badge)](https://pub.dev/publishers/muayid.com)
[![GitHub License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

## Installation

Install using `dart pub`:

```sh
dart pub global activate easy_onvif_cli
```

<!-- Install using `brew`:

```sh
brew tap cdavis-code/easy_onvif
brew install onvif
``` -->

Run the following command to see help:

```sh
onvif --help
```

Result,

```text
A command line interface for controlling Onvif compliant devices

Usage: onvif <command> [arguments]

Global options:
-h, --help           Print this usage information.
    --config-file    (defaults to "$HOME/.onvif/credentials.json")
    --log-level      [all, debug, info, warning, error, off (default)]

Available commands:
  authorize           Generate an authentication file for an Onvif device.
  debug               Generate a debug bundle for an Onvif device.
  device-management   Device management commands.
  media1              Media ver10 commands.
  media2              Media ver20 commands.
  probe               Probe/device discovery command.
  ptz                 PTZ commands.
  recordings          Recordings commands.
  replay              Replay commands.
  search              Search commands.
  version             Display the package name and version.
```

| command | description |
| --- | --- |
| [authorize](#authorize) | Generate a credentials file used to authenticate the command line API requests |
| debug | Generate a debug bundle for an Onvif device. |
| [device-management](#device-management) | Onvif device management commands, [spec](https://www.onvif.org/onvif/ver10/device/wsdl/devicemgmt.wsdl) |
| [media1](#media1) | Onvif media ver10 commands, [spec](https://www.onvif.org/ver10/media/wsdl/media.wsdl) |
| [media2](#media2) | Onvif media ver20 commands, [spec](https://www.onvif.org/ver20/media/wsdl/media.wsdl) |
| probe | Probe/device discovery command | 
| [ptz](#ptz)|Onvif PTZ commands, [spec](https://www.onvif.org/ver20/ptz/wsdl/ptz.wsdl) |
| [recordings](#recordings) | Recordings commands, [spec](https://www.onvif.org/ver10/recording.wsdl) | 
| [replay](#replay) | Replay commands, [spec](https://www.onvif.org/ver10/replay.wsdl)| 
|version|Display the package name and version. |

Just like the main library, any responses provided by the above commands will be given in the JSON format.  So ideally, you will want to use a command line json parser to interpret the results.  The recommended json parser for this purpose is [_jq_](https://stedolan.github.io/jq/).  With _jq_ you can process the results of a command as follows:

## Quick start

```sh
#step 1
onvif authorize
#follow prompts

#step 2
onvif ptz get-presets --limit 3 --profile-token Profile_1 | jq -r '.[] | ."@token" + "\t" + .Name'
#output would be
1       Preset 1
2       Preset 2
3       Preset 3
```

## Commands

### authorize

```sh
onvif authorize --help
```

```text
Generate a refresh token used to authenticate the command line API requests

Usage: onvif authorize [arguments]
-h, --help    Print this usage information.
```

The authorize command is used to create the default "--config-file" that can be used as the default for all future commands.  In general this command will only need to be run if you want to connect to another onvif device or if the settings (host, username, password) have changed for the current device.  The file contents are as follows:

```json
{"host":"[host name or ip address of device]","username":"[device username]","password":"[device password]"}
```

### device-management

```sh
onvif device-management --help
```

```text
Device management commands.

Usage: onvif device-management <subcommand> [arguments]
-h, --help    Print this usage information.

Usage: onvif device-management <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  add-ip-address-filter            This operation adds an IP address filter entry on a device.
  create-users                     This operation creates new device users and corresponding credentials on a device for authentication purposes. The device shall support creation of device users and their credentials through the CreateUsers command. Either all users are created successfully or a fault message shall be returned without creating any user.
  delete-geolocation               This operation deletes the geo location on the device.
  delete-users                     This operation deletes the given storage configuration and configuration change shall always be persistent.
  get-capabilities                 This method has been replaced by the more generic GetServices method. For capabilities of individual services refer to the GetServiceCapabilities methods.
  get-device-information           This operation gets basic device information from the device.
  get-discovery-mode               This operation gets the discovery mode of a device. See Section 7.2 for the definition of the different device discovery modes. The device shall support retrieval of the discovery mode setting through the GetDiscoveryMode command.
  get-dns                          This operation gets the DNS settings from a device. The device shall return its DNS configurations through the GetDNS command.
  get-dynamic-dns                  This operation gets the dynamic DNS settings from a device. If the device supports dynamic DNS as specified in [RFC 2136] and [RFC 4702], it shall be possible to get the type, name and TTL through the GetDynamicDNS command.
  get-endpoint-reference           A client can ask for the device service endpoint reference address property that can be used to derive the password equivalent for remote user operation.
  get-geolocation                  This operation lists all existing geo location configurations for the device.
  get-hostname                     This operation is used by an endpoint to get the hostname from a device. The device shall return its hostname configurations through the GetHostname command.
  get-ipaddress-filter             This operation gets the IP address filter settings from a device. If the device supports device access control based on IP filtering rules (denied or accepted ranges of IP addresses), the device shall support the GetIPAddressFilter command.
  get-network-default-gateway      This operation gets the default gateway settings from a device.
  get-network-protocols            This operation gets defined network protocols from a device. The device shall support the GetNetworkProtocols command returning configured network protocols.
  get-ntp                          This operation gets defined network protocols from a device. The device shall support This operation gets the NTP settings from a device. If the device supports NTP, it shall be possible to get the NTP server settings through the GetNTP command.
  get-relay-outputs                This operation gets a list of all available relay outputs and their settings.
  get-service-capabilities         Returns the capabilities of the device service. The result is returned in a typed answer.
  get-services                     Returns information about services on the device.
  get-storage-configuration        This operation retrieves the Storage configuration associated with the given storage configuration token.
  get-storage-configurations       This operation retrieves the Storage configuration associated with the given storage configuration token.
  get-system-date-and-time         This operation gets the device system date and time. The device shall support the return of the daylight saving setting and of the manual system date and time (if applicable) or indication of NTP time (if applicable) through the GetSystemDateAndTime command.
  get-system-log                   This operation gets a system log from the device.
  get-system-support-information   This operation gets arbitrary device diagnostics information from the device.
  get-system-uris                  This operation is used to retrieve URIs from which system information may be downloaded using HTTP
  get-users                        This operation lists the registered users and corresponding credentials on a device. The device shall support retrieval of registered device users and their credentials for the user token through the GetUsers command.
  get-zero-configuration           This operation gets the zero-configuration settings from a device.
  remove-ip-address-filter         This operation removes an IP address filter entry on a device.
  set-dns                          This operation sets the DNS settings on a device.
  set-dynamic-dns                  This operation sets the dynamic DNS settings on a device.
  set-geolocation                  This operation sets the geo location on the device.
  set-hostname                     This operation sets the hostname on a device.
  set-hostname-from-dhcp           This operation controls whether the hostname shall be obtained via DHCP.
  set-ipaddress-filter             This operation sets the IP address filter settings on a device. If the device supports device access control based on IP filtering rules (denied or accepted ranges of IP addresses), the device shall support configuration of IP filtering rules through the SetIPAddressFilter command.
  set-network-default-gateway      This operation sets the default gateway settings on a device.
  set-network-protocols            This operation configures one or more defined network protocols supported by the device.
  set-ntp                          This operation sets the NTP settings on a device.
  set-relay-output-settings        This operation sets the settings of a relay output.
  set-relay-output-state           This operation sets the state of a relay output.
  set-zero-configuration           This operation sets the zero-configuration settings on a device.
  system-reboot                    This operation reboots the device.
```

#### device-management create-users

```sh
onvif device-management create-users --help
```

```text
This operation creates new device users and corresponding credentials on a device for authentication purposes. The device shall support creation of device users and their credentials through the CreateUsers command. Either all users are created successfully or a fault message shall be returned without creating any user.

Usage: onvif device-management create-users [arguments]
-h, --help                                   Print this usage information.
-f, --users-file=<yaml or json file path>    The path to the file that lists users to be created, cannot be used with other options.
-u, --username=<string>                      Username string.
-p, --password=<string>                      Password string.
-l, --user-level=<enum>                      User level string.
                                             [administrator, operator, user, anonymous, extended]
```

#### device-management delete-users

```sh
onvif device-management delete-users --help
```

```text
This operation creates new device users and corresponding credentials on a device for authentication purposes. The device shall support creation of device users and their credentials through the CreateUsers command. Either all users are created successfully or a fault message shall be returned without creating any user.

Usage: onvif device-management create-users [arguments]
-h, --help                                   Print this usage information.
-f, --users-file=<yaml or json file path>    The path to the file that lists users to be created, cannot be used with other options.
-u, --username=<string>                      Username string. 
-p, --password=<string>                      Password string.
-l, --user-level=<enum>                      User level string.
                                             [administrator, operator, user, anonymous, extended]
```

#### device-management get-capabilities

```sh
onvif device-management get-capabilities --help
```

```text
This method has been replaced by the more generic GetServices method. For capabilities of individual services refer to the GetServiceCapabilities methods.

Usage: onvif device-management get-capabilities [arguments]
-h, --help    Print this usage information.
```

#### device-management get-device-information

```sh
onvif device-management get-device-information --help
```

```text
This operation gets basic device information from the device.

Usage: onvif device-management get-device-information [arguments]
-h, --help    Print this usage information.
```

#### device-management get-discovery-mode

```sh
onvif device-management get-discovery-mode --help
```

```text
This operation gets the discovery mode of a device. See Section 7.2 for the definition of the different device discovery modes. The device shall support retrieval of the discovery mode setting through the GetDiscoveryMode command.

Usage: onvif device-management get-device-information [arguments]
-h, --help    Print this usage information.
```

#### device-management get-dns

```sh
onvif device-management get-dns --help
```

```text
This operation gets the DNS settings from a device. The device shall return its DNS configurations through the GetDNS command.

Usage: onvif device-management get-device-information [arguments]
-h, --help    Print this usage information.
```

#### device-management get-endpoint-reference

```sh
onvif device-management get-endpoint-reference --help
```

```text
A client can ask for the device service endpoint reference address property that can be used to derive the password equivalent for remote user operation.

Usage: onvif device-management get-endpoint-reference [arguments]
-h, --help    Print this usage information.
```

#### device-management get-hostname

```sh
onvif device-management get-hostname --help
```

```text
This operation is used by an endpoint to get the hostname from a device. The device shall return its hostname configurations through the GetHostname command.

Usage: onvif device-management get-hostname [arguments]
-h, --help    Print this usage information.

```

#### device-management get-network-protocols

```sh
onvif device-management get-network-protocols --help
```

```text
This operation gets defined network protocols from a device. The device shall support the GetNetworkProtocols command returning configured network protocols.

Usage: onvif device-management get-network-protocols [arguments]
-h, --help    Print this usage information.
```

#### device-management get-ntp

```sh
onvif device-management get-ntp --help
```

```text
This operation gets defined network protocols from a device. The device shall support This operation gets the NTP settings from a device. If the device supports NTP, it shall be possible to get the NTP server settings through the GetNTP command.

Usage: onvif device-management get-ntp [arguments]
-h, --help    Print this usage information.
```

#### device-management get-service-capabilities

```sh
onvif device-management get-service-capabilities --help
```

```text
Returns the capabilities of the device service. The result is returned in a typed answer.

Usage: onvif device-management get-service-capabilities [arguments]
-h, --help    Print this usage information.
```

#### device-management get-services

```sh
onvif device-management get-services --help
```

```text
Returns information about services on the device.

Usage: onvif device-management get-services [arguments]
-h, --help                       Print this usage information.
-i, --[no-]include-capability    Indicates if the service capabilities (untyped) should be included in the response.
```

#### device-management get-storage-configuration

```sh
onvif device-management get-storage-configuration --help
```

```text
This operation retrieves the Storage configuration associated with the given storage configuration token.

Usage: onvif device-management get-storage-configuration [arguments]
-h, --help                         Print this usage information.
-t, --storage-token (mandatory)    Unique identifier referencing the physical entity.
```
#### device-management get-storage-configurations

```sh
onvif device-management get-storage-configurations --help
```

```text
This operation lists all existing storage configurations for the device.

Usage: onvif device-management get-storage-configurations [arguments]
-h, --help    Print this usage information.
```

#### device-management get-system-date-and-time

```sh
onvif device-management get-system-date-and-time --help
```

```text
This operation gets the device system date and time. The device shall support the return of the daylight saving setting and of the manual system date and time (if applicable) or indication of NTP time (if applicable) through the GetSystemDateAndTime command.

A device shall provide the UTCDateTime information.

Usage: onvif device-management get-system-date-and-time [arguments]
-h, --help    Print this usage information.
```

#### device-management get-system-log

```sh
onvif device-management get-system-log --help
```

```text
This operation gets a system log from the device.

Usage: onvif device-management get-system-log [arguments]
-h, --help                      Print this usage information.
-t, --type                      Specifies the type of system log to get.

          [Access]              Indicates that a access log is requested.
          [System] (default)    Indicates that a system log is requested.
```

#### device-management get-system-support-information

```sh
onvif device-management get-system-support-information --help
```

```text
This operation gets arbitrary device diagnostics information from the device.

Usage: onvif device-management get-system-support-information [arguments]
-h, --help    Print this usage information.
```

#### device-management get-system-uris

```sh
onvif device-management get-system-uris --help
```

```text
This operation is used to retrieve URIs from which system information may be downloaded using HTTP

Usage: onvif device-management get-system-uris [arguments]
-h, --help    Print this usage information.
```

#### device-management get-users

```sh
onvif device-management get-users --help
```

```text
This operation lists the registered users and corresponding credentials on a device. The device shall support retrieval of registered device users and their credentials for the user token through the GetUsers command.

Usage: onvif device-management get-users [arguments]
-h, --help    Print this usage information.
```

#### device-management get-dynamic-dns

```sh
onvif device-management get-dynamic-dns --help
```

```text
This operation gets the dynamic DNS settings from a device. If the device supports dynamic DNS as specified in [RFC 2136] and [RFC 4702], it shall be possible to get the type, name and TTL through the GetDynamicDNS command.

Usage: onvif device-management get-dynamic-dns [arguments]
-h, --help    Print this usage information.
```

#### device-management get-geolocation

```sh
onvif device-management get-geolocation --help
```

```text
This operation lists all existing geo location configurations for the device.

Usage: onvif device-management get-geolocation [arguments]
-h, --help    Print this usage information.
```

#### device-management get-ipaddress-filter

```sh
onvif device-management get-ipaddress-filter --help
```

```text
This operation gets the IP address filter settings from a device. If the device supports device access control based on IP filtering rules (denied or accepted ranges of IP addresses), the device shall support the GetIPAddressFilter command.

Usage: onvif device-management get-ipaddress-filter [arguments]
-h, --help    Print this usage information.
```

#### device-management system-reboot

```sh
onvif device-management system-reboot --help
```

```text
This operation reboots the device.

Usage: onvif device-management system-reboot [arguments]
-h, --help    Print this usage information.
```

#### device-management add-ip-address-filter

```sh
onvif device-management add-ip-address-filter --help
```

```text
This operation adds an IP address filter entry on a device.

Usage: onvif device-management add-ip-address-filter [arguments]
-h, --help         Print this usage information.
-f, --json-file    Path to a JSON file containing the IpAddressFilter configuration.
```

#### device-management delete-geolocation

```sh
onvif device-management delete-geolocation --help
```

```text
This operation deletes the geo location on the device.

Usage: onvif device-management delete-geolocation [arguments]
-h, --help    Print this usage information.
```

#### device-management get-network-default-gateway

```sh
onvif device-management get-network-default-gateway --help
```

```text
This operation gets the default gateway settings from a device.

Usage: onvif device-management get-network-default-gateway [arguments]
-h, --help    Print this usage information.
```

#### device-management get-relay-outputs

```sh
onvif device-management get-relay-outputs --help
```

```text
This operation gets a list of all available relay outputs and their settings.

Usage: onvif device-management get-relay-outputs [arguments]
-h, --help    Print this usage information.
```

#### device-management get-zero-configuration

```sh
onvif device-management get-zero-configuration --help
```

```text
This operation gets the zero-configuration settings from a device.

Usage: onvif device-management get-zero-configuration [arguments]
-h, --help    Print this usage information.
```

#### device-management remove-ip-address-filter

```sh
onvif device-management remove-ip-address-filter --help
```

```text
This operation removes an IP address filter entry on a device.

Usage: onvif device-management remove-ip-address-filter [arguments]
-h, --help         Print this usage information.
-f, --json-file    Path to a JSON file containing the IpAddressFilter configuration.
```

#### device-management set-dns

```sh
onvif device-management set-dns --help
```

```text
This operation sets the DNS settings on a device.

Usage: onvif device-management set-dns [arguments]
-h, --help         Print this usage information.
-f, --json-file    Path to a JSON file containing the DnsInformation configuration.
```

#### device-management set-dynamic-dns

```sh
onvif device-management set-dynamic-dns --help
```

```text
This operation sets the dynamic DNS settings on a device.

Usage: onvif device-management set-dynamic-dns [arguments]
-h, --help         Print this usage information.
-f, --json-file    Path to a JSON file containing the DynamicDnsInformation configuration.
```

#### device-management set-geolocation

```sh
onvif device-management set-geolocation --help
```

```text
This operation sets the geo location on the device.

Usage: onvif device-management set-geolocation [arguments]
-h, --help         Print this usage information.
-f, --json-file    Path to a JSON file containing a list of LocationEntity objects.
```

#### device-management set-hostname

```sh
onvif device-management set-hostname --help
```

```text
This operation sets the hostname on a device.

Usage: onvif device-management set-hostname [arguments]
-h, --help                Print this usage information.
-n, --name (mandatory)    The hostname to set.
```

#### device-management set-hostname-from-dhcp

```sh
onvif device-management set-hostname-from-dhcp --help
```

```text
This operation controls whether the hostname shall be obtained via DHCP.

Usage: onvif device-management set-hostname-from-dhcp [arguments]
-h, --help              Print this usage information.
    --[no-]from-dhcp    Set to true to obtain hostname via DHCP.
                        (defaults to on)
```

#### device-management set-ipaddress-filter

```sh
onvif device-management set-ipaddress-filter --help
```

```text
This operation sets the IP address filter settings on a device. If the device supports device access control based on IP filtering rules (denied or accepted ranges of IP addresses), the device shall support configuration of IP filtering rules through the SetIPAddressFilter command.

Usage: onvif device-management set-ipaddress-filter [arguments]
-h, --help         Print this usage information.
-f, --json-file    Path to a JSON file containing the IpAddressFilter configuration.
```

#### device-management set-network-default-gateway

```sh
onvif device-management set-network-default-gateway --help
```

```text
This operation sets the default gateway settings on a device.

Usage: onvif device-management set-network-default-gateway [arguments]
-h, --help         Print this usage information.
-f, --json-file    Path to a JSON file containing the NetworkGateway configuration.
```

#### device-management set-network-protocols

```sh
onvif device-management set-network-protocols --help
```

```text
This operation configures one or more defined network protocols supported by the device.

Usage: onvif device-management set-network-protocols [arguments]
-h, --help         Print this usage information.
-f, --json-file    Path to a JSON file containing a list of NetworkProtocol objects.
```

#### device-management set-ntp

```sh
onvif device-management set-ntp --help
```

```text
This operation sets the NTP settings on a device.

Usage: onvif device-management set-ntp [arguments]
-h, --help         Print this usage information.
-f, --json-file    Path to a JSON file containing the NtpInformation configuration.
```

#### device-management set-relay-output-settings

```sh
onvif device-management set-relay-output-settings --help
```

```text
This operation sets the settings of a relay output.

Usage: onvif device-management set-relay-output-settings [arguments]
-h, --help                              Print this usage information.
-t, --relay-output-token (mandatory)    The relay output token.
-f, --json-file                         Path to a JSON file containing the RelayOutputSettings (Mode, DelayTime, IdleState).
```

#### device-management set-relay-output-state

```sh
onvif device-management set-relay-output-state --help
```

```text
This operation sets the state of a relay output.

Usage: onvif device-management set-relay-output-state [arguments]
-h, --help                              Print this usage information.
-t, --relay-output-token (mandatory)    The relay output token.
-s, --logical-state (mandatory)         The logical state of the relay.
                                        [active, inactive]
```

#### device-management set-zero-configuration

```sh
onvif device-management set-zero-configuration --help
```

```text
This operation sets the zero-configuration settings on a device.

Usage: onvif device-management set-zero-configuration [arguments]
-h, --help                           Print this usage information.
-t, --interface-token (mandatory)    The interface token.
    --[no-]enabled                   Enable or disable zero-configuration.
                                     (defaults to on)
```

###  debug

```sh
onvif debug --help
```

```text
Generate a debug bundle for an Onvif device.

Usage: onvif debug [arguments]
-h, --help                         Print this usage information.
-o, --output-folder=<file path>    destination folder for debug bundle
                                   (defaults to "debug")
```

### media1

```sh
onvif media --help
```

```text
Media1 commands.

Usage: onvif media1 <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  get-audio-sources             This command lists all available physical audio inputs of the device.
  get-metadata-configuration    The GetMetadataConfiguration command fetches the metadata configuration if the metadata token is known.
  get-metadata-configurations   This operation returns the available options (supported values and ranges for metadata configuration parameters) for changing the metadata configuration.
  get-profile                   If the profile token is already known, a profile can be fetched through the GetProfile command.
  get-profiles                  Any endpoint can ask for the existing media profiles of a device using the GetProfiles command. Pre-configured or dynamically configured profiles can be retrieved using this command. This command lists all configured profiles in a device. The client does not need to know the media profile in order to use the command.
  get-service-capabilities      Returns the capabilities of the media service. The result is returned in a typed answer.
  get-snapshot-uri              A client uses the GetSnapshotUri command to obtain a JPEG snapshot from the device.
  get-stream-uri                This operation requests a URI that can be used to initiate a live media stream using RTSP as the control protocol
  get-video-sources             This command lists all available physical video inputs of the device.
  start-multicast-streaming     This command starts multicast streaming using a specified media profile of a device.
  stop-multicast-streaming      This command stop multicast streaming using a specified media profile of a device.
```

#### media1 get-audio-sources

```sh
onvif media1 get-audio-sources --help
```

```text
This command lists all available physical audio inputs of the device.

Usage: onvif media1 get-audio-sources [arguments]
-h, --help    Print this usage information.
```

#### media1 get-metadata-configuration

```sh
onvif media1 get-metadata-configuration --help
```

```text
This command lists all available physical audio inputs of the device.

Usage: onvif media1 get-metadata-configuration [arguments]
-h, --help                                        Print this usage information.
-t, --configuration-token=<string> (mandatory)    Token of the requested metadata configuration.
```

#### media1 get-metadata-configuration

```sh
onvif media1 get-metadata-configurations --help
```

```text
This operation returns the available options (supported values and ranges for metadata configuration parameters) for changing the metadata configuration.

Usage: onvif media1 get-metadata-configurations [arguments]
-h, --help                            Print this usage information.
    --configuration-token=<string>    Optional metadata configuration token that specifies an existing configuration that the options are intended for.
    --profile-token=<string>          Optional ProfileToken that specifies an existing media profile that the options shall be compatible with.
```

#### media1 get-profile

```sh
onvif media1 get-profile --help
```

```text
If the profile token is already known, a profile can be fetched through the GetProfile command.

Usage: onvif media1 get-profile [arguments]
-h, --help                                  Print this usage information.
-t, --profile-token=<string> (mandatory)    Token of the requested media profile.
```

#### media1 get-profiles

```sh
onvif media1 get-profiles --help
```

```text
Any endpoint can ask for the existing media profiles of a device using the GetProfiles command. Pre-configured or dynamically configured profiles can be retrieved using this command. This command lists all configured profiles in a device. The client does not need to know the media profile in order to use the command.

Usage: onvif media1 get-profiles [arguments]
-h, --help    Print this usage information.
```

#### media1 get-service-capabilities

```sh
onvif media1 get-service-capabilities --help
```

```text
Returns the capabilities of the media service. The result is returned in a typed answer.

Usage: onvif media1 get-service-capabilities [arguments]
-h, --help    Print this usage information.
```

##### media1 get-snapshot-uri

```sh
onvif media1 get-snapshot-uri --help
```

```text
A client uses the GetSnapshotUri command to obtain a JPEG snapshot from the device.

Usage: onvif media1 get-snapshot-uri [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.

```

#### media1 get-stream-uri

```sh
onvif media1 get-stream-uri  --help
```

```text
This operation requests a URI that can be used to initiate a live media stream using RTSP as the control protocol.

Usage: onvif media1 get-stream-uri [arguments]
-h, --help                                                    Print this usage information.
-t, --profile-token=<token> (mandatory)                       The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
    --stream-setup-stream=<stream type>                       Defines if a multicast or unicast stream is requested
                                                              [RTP-Unicast, RTP-Multicast (default)]
    --stream-setup-transport-protocol=<transport protocol>    Defines the network protocol for streaming, either UDP=RTP/UDP, RTSP=RTP/RTSP/TCP or HTTP=RTP/RTSP/HTTP/TCP
                                                              [UDP, TCP, RTSP (default), HTTP]

```

#### media1 get-video-sources

```sh
onvif media1 get-video-sources  --help
```

```text
This command lists all available physical video inputs of the device.

Usage: onvif media1 get-video-sources [arguments]
```

#### media1 start-multicast-streaming

```sh
onvif media1 start-multicast-streaming --help
```

```text
This command starts multicast streaming using a specified media profile of a device.

Usage: onvif media1 start-multicast-streaming [arguments]
-h, --help    Print this usage information.
```

#### media1 stop-multicast-streaming

```sh
onvif media1 stop-multicast-streaming --help
```

```text
This command stop multicast streaming using a specified media profile of a device.

Usage: onvif media1 stop-multicast-streaming [arguments]
-h, --help    Print this usage information.
```

### media2

```sh
onvif media2 --help
```

```text
Media2 commands.

Usage: onvif media2 <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  delete-profile                   This operation deletes a profile. Deletion of a profile is only possible for non-fixed profiles.
  get-metadata-configuration-options   This operation returns the available options (supported values and ranges for metadata configuration parameters) for changing the metadata configuration.
  get-metadata-configurations          By default this operation lists all existing metadata configurations for a device. Provide a profile token to list only configurations that are compatible with the profile. If a configuration token is provided only a single configuration will be returned.
  get-profiles                         Retrieve the profile with the specified token or all defined media profiles.
  get-service-capabilities             Returns the capabilities of the media service. The result is returned in a typed answer.
  get-snapshot-uri                     A client uses the GetSnapshotUri command to obtain a JPEG snapshot from the device.
  get-stream-uri                       This operation requests a URI that can be used to initiate a live media stream using RTSP as the control protocol
  get-video-encoder-instances          The GetVideoEncoderInstances command can be used to request the minimum number of guaranteed video encoder instances (applications) per Video Source Configuration.
  get-webrtc-configurations            This operation retrieves the WebRTC signaling configurations of a device.
  set-webrtc-configurations            This operation configures the WebRTC signaling configurations of a device. Passing an empty list deletes the existing configurations.
  start-multicast-streaming            This command starts multicast streaming using a specified media profile of a device.
  stop-multicast-streaming             This command stop multicast streaming using a specified media profile of a device.
  ```

#### media2 get-metadata-configuration-options

```sh
onvif media2 get-metadata-configuration-options --help
```

```text
This operation returns the available options (supported values and ranges for metadata configuration parameters) for changing the metadata configuration.

Usage: onvif media2 get-metadata-configuration-options [arguments]
-h, --help                            Print this usage information.
    --configuration-token=<string>    Token of the requested configuration.
    --profile-token=<string>          Contains the token of an existing media profile the configurations shall be compatible with.
```

#### media2 get-metadata-configurations

```sh
onvif media2 get-metadata-configurations --help
```

```text
By default this operation lists all existing metadata configurations for a device. Provide a profile token to list only configurations that are compatible with the profile. If a configuration token is provided only a single configuration will be returned.

Usage: onvif media2 get-metadata-configurations [arguments]
-h, --help                            Print this usage information.
    --configuration-token=<string>    Token of the requested configuration.
    --profile-token=<string>          Contains the token of an existing media profile the configurations shall be compatible with.
```

#### media2 get-profiles

```sh
onvif media2 get-profiles --help
```

```text
Retrieve the profile with the specified token or all defined media profiles.

Usage: onvif media2 get-profiles [arguments]
-h, --help                             Print this usage information.
    --reference-token=<string>         Optional token of the requested profile.
    --type=<comma delimited string>    The types shall be provided as defined by tr2:ConfigurationEnumeration.
                                       [All, Analytics, AudioSource, AudioDecoder, AudioEncoder, AudioOutput, Metadata, VideoEncoder, VideoSource, PTZ]
```

#### media2 get-service-capabilities

```sh
onvif media2 get-service-capabilities --help
```

```text
Returns the capabilities of the media service. The result is returned in a typed answer.

Usage: onvif media2 get-service-capabilities [arguments]
-h, --help    Print this usage information.
```


#### media2 get-snapshot-uri

```sh
onvif media2 get-snapshot-uri --help
```

```text
A client uses the GetSnapshotUri command to obtain a JPEG snapshot from the device.

Usage: onvif media2 get-snapshot-uri [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
```

#### media2 get-stream-uri

```sh
onvif media2 get-stream-uri --help
```

```text
This operation requests a URI that can be used to initiate a live media stream using RTSP as the control protocol.

Usage: onvif media2 get-stream-uri [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
    --protocol=<transport protocol>        The Protocol defines how the encoded data is expected to be streamed to the client
                                           [RtspUnicast, RtspMulticast, RTSP (default), RtspsUnicast, RtspsMulticast, RtspOverHttp]
```

#### media2 get-video-encoder-instances

```sh
onvif media2 get-video-encoder-instances --help
```

```text
The get-video-encoder-instances command can be used to request the minimum number of guaranteed video encoder instances (applications) per Video Source Configuration.

Usage: onvif media2 get-video-encoder-instances [arguments]
-h, --help                                        Print this usage information.
    --configuration-token=<string> (mandatory)    Token of the video source configuration
```

#### media2 delete-profile

```sh
onvif media2 delete-profile --help
```

```text
This operation deletes a profile. Deletion of a profile is only possible for non-fixed profiles.

Usage: onvif media2 delete-profile [arguments]
-h, --help                                   Print this usage information.
-t, --reference-token=<token> (mandatory)    The token of the profile to delete.
```

#### media2 get-webrtc-configurations

```sh
onvif media2 get-webrtc-configurations --help
```

```text
This operation retrieves the WebRTC signaling configurations of a device.

Usage: onvif media2 get-webrtc-configurations [arguments]
-h, --help    Print this usage information.
```

#### media2 set-webrtc-configurations

```sh
onvif media2 set-webrtc-configurations --help
```

```text
This operation configures the WebRTC signaling configurations of a device. Passing an empty list deletes the existing configurations.

Usage: onvif media2 set-webrtc-configurations [arguments]
-h, --help         Print this usage information.
-f, --json-file    Path to a JSON file containing a list of WebrtcConfiguration objects.
```

#### media2 start-multicast-streaming

```sh
onvif media2 start-multicast-streaming --help
```

```text
This command starts multicast streaming using a specified media profile of a device.

Usage: onvif media2 start-multicast-streaming [arguments]
-h, --help    Print this usage information.
```

#### media2 stop-multicast-streaming

```sh
onvif media2 stop-multicast-streaming --help
```

```text
This command stop multicast streaming using a specified media profile of a device.

Usage: onvif media2 stop-multicast-streaming [arguments]
-h, --help    Print this usage information.
```

### probe

```sh
onvif probe --help
```

```text
Probe/device discovery command.

Usage: onvif probe [arguments]
-h, --help                Print this usage information.
-t, --timeout=<number>    The number of seconds to accept probe responses from devices.
                          (defaults to "2")
```

### ptz

```sh
onvif ptz --help
```

```text
PTZ commands.

Usage: onvif ptz <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  absolute-move                   Operation to move pan,tilt or zoom to a absolute destination.
  continuous-move                 Operation for continuous Pan/Tilt and Zoom movements.
  get-compatible-configurations   Contains the token of an existing media profile the configurations shall be compatible with.
  get-configuration               Get a specific PTZconfiguration from the device, identified by its reference token or name.
  get-configuration-options       Token of an existing configuration that the options are intended for.
  get-configurations              Get all the existing PTZConfigurations from the device.
  get-current-preset              Helper function to get the matching preset for the current PtzPosition and Zoom if there is a match
  get-preset-tour                 Operation to request a specific PTZ preset tour in the selected media profile.
  get-preset-tours                Operation to request PTZ preset tours in the selected media profiles.
  get-presets                     Operation to request all PTZ presets for the PTZNode in the selected profile.
  get-presets-map                 Helper method to get presets as a map keyed by token.
  get-service-capabilities        Returns the capabilities of the PTZ service. The result is returned in a typed answer.
  get-status                      Operation to request PTZ status for the Node in the selected profile.
  goto-home-position              Operation to move the PTZ device to it's "home" position. The operation is supported if the HomeSupported element in the PTZNode is true.
  goto-preset                     Operation to go to a saved preset position for the PTZNode in the selected profile.
  move                            Operation for Relative Pan/Tilt Move without Zoom.
  move-down                       Operation for a single step tilt down operation.
  move-left                       Operation for a single step pan left operation.
  move-right                      Operation for a single step pan right operation
  move-up                         Operation for a single step tilt upwards operation.
  relative-move                   Operation for Relative Pan/Tilt and Zoom Move.
  remove-preset                   Operation to remove a PTZ preset for the Node in the selected profile.
  set-home-position               Operation to save current position as the home position. The SetHomePosition command returns with a failure if the “home” position is fixed and cannot be overwritten. If the SetHomePosition is successful, it is possible to recall the Home Position with the GotoHomePosition command.
  set-preset                      The SetPreset command saves the current device position parameters so that the device can move to the saved preset position through the GotoPreset operation.
  stop                            Operation to stop ongoing pan, tilt and zoom movements of absolute relative and continuous type.
  zoom                            Operation for zoom.
  zoom-in                         Operation for a single step zoom in operation.
  zoom-out                        Operation for a single step zoom out operation.
```

#### ptz absolute-move

```sh
onvif ptz absolute-move --help
```

```text
Operation to move pan,tilt or zoom to a absolute destination.

Usage: onvif ptz absolute-move [arguments]
-h, --help                                  Print this usage information.
-t, --profile-token=<token> (mandatory)     The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
    --pan-tilt-x=<double> (mandatory)       A Position vector specifying the absolute target position x-axis.
    --pan-tilt-y=<double> (mandatory)       A Position vector specifying the absolute target position y-axis.
    --pan-tilt-zoom=<double> (mandatory)    A Position vector specifying the absolute target position zoom.
```

#### ptz continuous-move

```sh
onvif ptz continuous-move --help
```

```text
Operation for continuous Pan/Tilt and Zoom movements.

Usage: onvif ptz continuous-move [arguments]
-h, --help                                  Print this usage information.
-t, --profile-token=<token> (mandatory)     The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
    --pan-tilt-x=<double> (mandatory)       A Position vector specifying the absolute target position x-axis.
    --pan-tilt-y=<double> (mandatory)       A Position vector specifying the absolute target position y-axis.
    --pan-tilt-zoom=<double> (mandatory)    A Position vector specifying the absolute target position zoom.
```

### ptz get-compatible-configurations

```sh
onvif ptz get-compatible-configurations --help
```

```text
Contains the token of an existing media profile the configurations shall be compatible with.

Usage: onvif ptz get-compatible-configurations [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
```

#### ptz get-configuration

```sh
onvif ptz get-configuration --help
```

```text
Option ptz-configuration-token is mandatory.

Usage: onvif ptz get-configuration [arguments]
-h, --help                                           Print this usage information.
-t, --ptz-configuration-token=<token> (mandatory)    Token of the requested PTZConfiguration.
```

#### ptz get-configuration-options

```sh
onvif ptz get-configuration-options --help
```

```text
List supported coordinate systems including their range limitations.

Usage: onvif ptz get-configuration-options [arguments]
-h, --help                                       Print this usage information.
-t, --configuration-token=<token> (mandatory)    Token of an existing configuration that the options are intended for.
```

#### ptz get-configurations

```sh
onvif ptz get-configurations --help
```

```text
Get all the existing PTZConfigurations from the device.

Usage: onvif ptz get-configurations [arguments]
-h, --help    Print this usage information.
```

#### ptz get-current-preset

```sh
onvif ptz get-current-preset --help
```

```text
Helper function to get the matching preset for the current PtzPosition and Zoom if there is a match

Usage: onvif ptz get-current-preset [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
```

#### ptz get-preset-tour

```sh
onvif ptz get-preset-tour --help
```

```text
Operation to request a specific PTZ preset tour in the selected media profile.

Usage: onvif ptz get-preset-tour [arguments]
-h, --help                                     Print this usage information.
-t, --profile-token=<token> (mandatory)        A reference to the MediaProfile where the operation should take place.
    --preset-tour-token=<token> (mandatory)    A requested preset tour token.
```

#### ptz get-preset-tours

```sh
onvif ptz get-preset-tours --help
```

```text
Operation to request PTZ preset tours in the selected media profiles.

Usage: onvif ptz get-preset-tours [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    A reference to the MediaProfile where the operation should take place.
```

#### ptz get-presets

```sh
onvif ptz get-presets --help
```

```text
Operation to request all PTZ presets for the PTZNode in the selected profile.

Usage: onvif ptz get-presets [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    A reference to the MediaProfile where the operation should take place.
    --limit=<int>                          Limit the number of presets returned
```

#### ptz get-presets-map

```sh
onvif ptz get-presets-map --help
```

```text
Helper method to get presets as a map keyed by token.

Usage: onvif ptz get-presets-map [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
```

#### ptz get-service-capabilities

```sh
onvif ptz get-service-capabilities --help
```

```text
Returns the capabilities of the PTZ service. The result is returned in a typed answer.

Usage: onvif ptz get-service-capabilities [arguments]
```

#### ptz get-status

```sh
onvif ptz get-status --help
```

```text
Operation to request PTZ status for the Node in the selected profile.

Usage: onvif ptz get-status [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    A reference to the MediaProfile where the PTZStatus should be requested.
```

#### ptz goto-preset

```sh
onvif ptz goto-preset --help
```

```text
Option profile-token is mandatory.

Usage: onvif ptz goto-preset [arguments]
-h, --help                                         Print this usage information.
-t, --profile-token=<profile-token> (mandatory)    A reference to the MediaProfile where the operation should take place.
    --preset-token=<preset-token> (mandatory)      A requested preset token.
```

#### ptz move

```sh
onvif ptz move --help
```

```text
Operation for Relative Pan/Tilt Move without Zoom.

Usage: onvif ptz move [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
    --x=<double> (mandatory)               The x component corresponds to pan.
    --y=<double> (mandatory)               The y component corresponds to tilt.
```

#### ptz move-down

```sh
onvif ptz goto-preset --help
```

```text
Operation for a single step tilt down operation.

Usage: onvif ptz goto-preset [arguments]
-h, --help                                         Print this usage information.
-t, --profile-token=<profile-token> (mandatory)    A reference to the MediaProfile where the operation should take place.
    --preset-token=<preset-token> (mandatory)      A requested preset token.
```

#### ptz move-left

```sh
onvif ptz goto-preset --help
```

```text
Operation for a single step pan left operation

Usage: onvif ptz goto-preset [arguments]
-h, --help                                         Print this usage information.
-t, --profile-token=<profile-token> (mandatory)    A reference to the MediaProfile where the operation should take place.
    --preset-token=<preset-token> (mandatory)      A requested preset token.
```

#### ptz move-right

```sh
onvif ptz goto-preset --help
```

```text
Operation for a single step pan right operation

Usage: onvif ptz goto-preset [arguments]
-h, --help                                         Print this usage information.
-t, --profile-token=<profile-token> (mandatory)    A reference to the MediaProfile where the operation should take place.
    --preset-token=<preset-token> (mandatory)      A requested preset token.
```

#### ptz move-up

```sh
onvif ptz move-up --help
```

```text
Operation for a single step tilt upwards operation.

Usage: onvif ptz move-up [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
    --step=<int>                           The amount of movement for the step.
```

#### ptz relative-move

```sh
onvif ptz relative-move --help
```

```text
Operation for Relative Pan/Tilt and Zoom Move.

Usage: onvif ptz relative-move [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
    --translation-x=<double>               Pan and tilt speed. The x component corresponds to pan. If omitted in a request, the current (if any) PanTilt movement should not be affected.
    --translation-y=<double>               Pan and tilt speed. The y component corresponds to tilt. If omitted in a request, the current (if any) PanTilt movement should not be affected.
    --translation-zoom=<double>            A zoom speed. If omitted in a request, the current (if any) Zoom movement should not be affected.
```

#### ptz remove-preset

```sh
onvif ptz remove-preset --help
```

```text
Operation to remove a PTZ preset for the Node in the selected profile.

Usage: onvif ptz remove-preset [arguments]
-h, --help                                         Print this usage information.
-t, --profile-token=<profile-token> (mandatory)    A reference to the MediaProfile where the operation should take place.
    --preset-token=<preset-token> (mandatory)      A requested preset token.
```

#### ptz set-home-position

```sh
onvif ptz set-home-position --help
```

```text
Operation to save current position as the home position. The SetHomePosition command returns with a failure if the “home” position is fixed and cannot be overwritten. If the SetHomePosition is successful, it is possible to recall the Home Position with the GotoHomePosition command.

Usage: onvif ptz set-home-position [arguments]
-h, --help                                         Print this usage information.
-t, --profile-token=<profile-token> (mandatory)    A reference to the MediaProfile where the operation should be set.
```

#### ptz set-preset

```sh
onvif ptz set-preset --help
```

```text
The SetPreset command saves the current device position parameters so that the device can move to the saved preset position through the GotoPreset operation.

Usage: onvif ptz set-preset [arguments]
-h, --help                                         Print this usage information.
-t, --profile-token=<profile-token> (mandatory)    A reference to the MediaProfile where the operation should take place.
    --preset-token=<preset-token> (mandatory)      A requested preset token.
    --preset-name=<name> (mandatory)    
```

#### ptz stop

```sh
onvif ptz stop --help
```

```text
Operation to stop ongoing pan, tilt and zoom movements of absolute relative and continuous type.

Usage: onvif ptz stop [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
    --[no-]pan-tilt                        Set true when we want to stop ongoing pan and tilt movements.If PanTilt arguments are not present, this command stops these movements.
                                           (defaults to on)
    --[no-]zoom                            Set true when we want to stop ongoing zoom movement.If Zoom arguments are not present, this command stops ongoing zoom movement.
                                           (defaults to on) 
```

#### ptz zoom

```sh
onvif ptz zoom --help
```

```text
Operation for zoom.

Usage: onvif ptz zoom [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
    --zoom=<double> (mandatory)            The speed for the zoom operation
```

#### ptz zoom-in

```sh
onvif ptz zoom-in --help
```

```text
Operation for a single step zoom in operation.

Usage: onvif ptz zoom-in [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
    --step=<int>                           The amount of movement for the step.
```

#### ptz zoom-out

```sh
onvif ptz zoom-out --help
Operation for a single step zoom out operation.

Usage: onvif ptz zoom-out [arguments]
-h, --help                                 Print this usage information.
-t, --profile-token=<token> (mandatory)    The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.
    --step=<int>                           The amount of movement for the step.
```

### recordings

```sh
onvif recordings --help
```

```text
Recordings commands.

Usage: onvif recordings <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  create-recording           create-recording shall create a new recording.
  create-recording-job       create-recording-job shall create a new recording job.
  delete-recording-job       delete-recordings removes a recording job.
  delete-recordings          delete-recording shall delete a recording object.
  get-recording-job-state    get-recording-job-state returns the state of a recording job. It includes an aggregated state, and state for each track of the recording job.
  get-recording-jobs         get-recording-jobs shall return a description of all the recordings in the device.
  get-recording-options      get-recording-options returns information for a recording identified by the RecordingToken.
  get-recordings             get-recordings shall return a description of all the recordings in the device.
  get-service-capabilities   Returns the capabilities of the recording service. The result is returned in a typed answer.
  set-recording-job-mode     get-recording-job-mode shall change the mode of the recording job.
```

#### recordings create-recording

```sh
onvif recordings create-recording --help
```

```text
create-recording shall create a new recording.

Usage: onvif recordings create-recording [arguments]
-h, --help                                       Print this usage information.
    --source-source-id=<string> (mandatory)      Identifier for the source chosen by the client that creates the structure. This identifier is opaque to the device. Clients may use any type of URI for this field. A device shall support at least 128 characters.
    --source-name=<string> (mandatory)           Informative user readable name of the source, e.g. "Camera23". A device shall support at least 20 characters.
    --source-location=<string> (mandatory)       Informative description of the physical location of the source, e.g. the coordinates on a map.
    --source-description=<string> (mandatory)    Informative description of the source.
    --source-address=<string> (mandatory)        URI provided by the service supplying data to be recorded. A device shall support at least 128 characters.
    --content=<string> (mandatory)               Informative description of the source.
    --maximum-retention-time=<duration>          Specifies the maximum time that data in any track within the recording shall be stored. The device shall delete any data older than the maximum retention time. Such data shall not be accessible anymore. If the MaximumRetentionPeriod is set to 0, the device shall not limit the retention time of stored data, except by resource constraints. Whatever the value of MaximumRetentionTime, the device may automatically delete recordings to free up storage space for new recordings.
                                                 (defaults to "PT0S")
```

#### recordings create-recording-job

```sh
onvif recordings create-recording-job --help
```

```text
create-recording-job shall create a new recording job.

Usage: onvif recordings create-recording-job [arguments]
-h, --help                                                      Print this usage information.
    --job-configuration-schedule-token=<string>                 This attribute adds an additional requirement for activating the recording job. If this optional field is provided the job shall only record if the schedule exists and is active.
    --job-configuration-recording-token=<string> (mandatory)    Identifies the recording to which this job shall store the received data.
    --job-configuration-mode=<string>                           The mode of the job. If it is idle, nothing shall happen. If it is active, the device shall try to obtain data from the receivers. A client shall use GetRecordingJobState to determine if data transfer is really taking place.
                                                                
                                                                The only valid values for Mode shall be “Idle” and “Active”.
                                                                [Idle, Active]
    --job-configuration-priority=<int> (mandatory)              This shall be a non-negative number. If there are multiple recording jobs that store data to the same track, the device will only store the data for the recording job with the highest priority. The priority is specified per recording job, but the device shall determine the priority of each track individually. If there are two recording jobs with the same priority, the device shall record the data corresponding to the recording job that was activated the latest.
```

#### recordings delete-recording-job

```sh
onvif recordings delete-recording-job --help
```

```text
delete-recording shall delete a recording object.

Usage: onvif recordings delete-recording-job [arguments]
-h, --help                             Print this usage information.
-t, --job-token=<token> (mandatory)    The token of the job to be deleted.
```

#### recordings delete-recordings

```sh
onvif recordings delete-recordings --help
```

```text
Option recording-token is mandatory.

Usage: onvif recordings delete-recordings [arguments]
-h, --help                                   Print this usage information.
-t, --recording-token=<token> (mandatory)    The reference of the recording to be deleted.
```

#### recordings get-recording-job-state

```sh
onvif recordings get-recording-job-state --help
```

```text
get-recording-job-state returns the state of a recording job. It includes an aggregated state, and state for each track of the recording job.

Usage: onvif recordings get-recording-job-state [arguments]
-h, --help                             Print this usage information.
-t, --job-token=<token> (mandatory)    The token of the job to be deleted.
```

#### recordings get-recording-jobs

```sh
onvif recordings get-recording-jobs --help
```

```text
get-recording-jobs shall return a description of all the recordings in the device.

Usage: onvif recordings get-recording-jobs [arguments]
-h, --help                             Print this usage information.
```

#### recordings get-recording-options

```sh
onvif recordings get-recording-options --help
```

```text
get-recording-options returns information for a recording identified by the RecordingToken.

Usage: onvif recordings get-recording-options [arguments]
-h, --help                             Print this usage information.
-t, --recording-token=<token> (mandatory)    Token of the recording.
```

#### recordings get-recordings

```sh
onvif recordings get-recordings --help
```

```text
get-recordings shall return a description of all the recordings in the device.

Usage: onvif recordings get-recordings [arguments]
-h, --help                             Print this usage information.
```

#### recordings get-service-capabilities

```sh
onvif recordings get-service-capabilities --help
```

```text
Returns the capabilities of the recording service. The result is returned in a typed answer.

Usage: onvif recordings get-service-capabilities [arguments]
-h, --help    Print this usage information.
```

#### recordings set-recording-job-mode

```sh
onvif recordings set-recording-job-mode --help
```

```text
set-recording-job-mode shall change the mode of the recording job.

Usage: onvif recordings set-recording-job-mode [arguments]
-h, --help                             Print this usage information.
-t, --job-token=<token> (mandatory)    Token of the recording job.
    --mode=<string> (mandatory)        The new mode for the recording job.
                                       [Idle, Active]
```

### replay

```sh
onvif replay --help
```

```text
Replay commands.

Usage: onvif replay <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  get-replay-configuration   Returns the current configuration of the replay service. 
  get-replay-uri             Requests a URI that can be used to initiate playback of a recorded stream using RTSP as the control protocol
  get-service-capabilities   Returns the capabilities of the replay service.
  set-replay-configuration   Returns the capabilities of the replay service.
```

#### replay get-replay-configuration

```sh
onvif replay get-replay-configuration --help
```

```text
Returns the current configuration of the replay service. 

Usage: onvif replay get-replay-configuration [arguments]
-h, --help    Print this usage information.
```

#### replay get-replay-uri

```sh
onvif replay get-replay-uri --help
```

```text
Requests a URI that can be used to initiate playback of a recorded stream using RTSP as the control protocol

Usage: onvif replay get-replay-uri [arguments]
-h, --help                                                    Print this usage information.
-t, --recording-token=<token> (mandatory)                     The identifier of the recording to be streamed.
    --stream-setup-stream=<stream type>                       Defines if a multicast or unicast stream is requested
                                                              [RTP-Unicast (default), RTP-Multicast]
    --stream-setup-transport-protocol=<transport protocol>    Defines the network protocol for streaming, either UDP=RTP/UDP, RTSP=RTP/RTSP/TCP or HTTP=RTP/RTSP/HTTP/TCP
                                                              [UDP, TCP, RTSP (default), HTTP]
```

#### replay get-service-capabilities

```sh
onvif replay get-service-capabilities --help
```

```text
Returns the capabilities of the replay service.

Usage: onvif replay get-service-capabilities [arguments]
-h, --help    Print this usage information.
```

#### replay set-replay-configuration

```sh
onvif replay set-replay-configuration --help
```

```text
Changes the current configuration of the replay service.

Usage: onvif replay set-replay-configuration [arguments]
-h, --help                        Print this usage information.
-t, --session-timeout=<string>    The RTSP session timeout.
                                  (defaults to "PT60S")
```

### version

```sh
onvif version --help
```

```text
Display the package name and version.

Usage: onvif version [arguments]
-h, --help    Print this usage information.
```