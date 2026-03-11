# Dart Implementation of ONVIF IP Camera Client

<p align="center" width="100%">
<img src="https://github.com/faithoflifedev/easy_onvif/blob/main/logo/easy_onvif_logo_640.png?raw=true" width="200" />
</p>

[![Pub Package](https://img.shields.io/pub/v/easy_onvif.svg)](https://pub.dev/packages/easy_onvif)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/faithoflifedev/easy_onvif/blob/main/LICENSE)

This package works with a variety of ONVIF compatible devices allowing for IP Cameras and NVRs (network video recorders) to be integrated into Dart and Flutter applications.  The package includes the ability to control the PTZ (pan-tilt-zoom) movements of a device along with managing presets as well as controlling how video and audio is being streamed from the device.  Review the documentation below to get more details on available features.

## Table of contents
- [Dart Implementation of ONVIF IP Camera Client](#dart-implementation-of-onvif-ip-camera-client)
  - [Table of contents](#table-of-contents)
  - [Getting Started](#getting-started)
    - [Dependency](#dependency)
    - [Usage Example](#usage-example)
    - [Interacting with a device through Onvif operations](#interacting-with-a-device-through-onvif-operations)
  - [Lower level requests](#lower-level-requests)
  - [Onvif cli (Onvif at the command prompt)](#onvif-cli-onvif-at-the-command-prompt)
  - [Supported Onvif Operations](#supported-onvif-operations)
    - [Device Management](#device-management)
    - [Imaging](#imaging)
    - [Media 10](#media-10)
    - [Media 20](#media-20)
    - [PTZ](#ptz)
    - [PTZ Helper Methods](#ptz-helper-methods)
    - [Recording](#recording)
    - [Replay](#replay)
    - [Search](#search)
  - [Onvif Probe](#onvif-probe)
  - [Tested Onvif Devices](#tested-onvif-devices)
  - [New for version 3.1.3](#new-for-version-313)
  - [New for version 3.1.0](#new-for-version-310)
  - [New for version 3.0.0-dev.0](#new-for-version-300-dev0)
  - [New for version 2.2.x](#new-for-version-22x)
  - [Onvif specifications and documentation](#onvif-specifications-and-documentation)
  - [Features and bugs](#features-and-bugs)
  - [Possible unexpected behavior](#possible-unexpected-behavior)
  - [Known Issues](#known-issues)
    - [Issue #45](#issue-45)
  - [Breaking changes](#breaking-changes)
    - [v3.1.0](#v310)
    - [v3.0.0-dev.0](#v300-dev0)
    - [v2.3.0](#v230)
  - [Contributors](#contributors)
  - [Contributing](#contributing)

[![Build Status](https://github.com/faithoflifedev/easy_onvif/workflows/Dart/badge.svg)](https://github.com/faithoflifedev/easy_onvif/actions) [![github last commit](https://shields.io/github/last-commit/faithoflifedev/easy_onvif)](https://shields.io/github/last-commit/faithoflifedev/easy_onvif) [![github build](https://img.shields.io/github/actions/workflow/status/faithoflifedev/easy_onvif/dart.yml?branch=main)](https://shields.io/github/workflow/status/faithoflifedev/easy_onvif/Dart) [![github issues](https://shields.io/github/issues/faithoflifedev/easy_onvif)](https://shields.io/github/issues/faithoflifedev/easy_onvif)

[![Buy me a coffee](https://github.com/faithoflifedev/easy_onvif/blob/main/logo/buy_me_a_coffee.svg?raw=true)](https://www.buymeacoffee.com/faithoflif2)

## Getting Started

### Dependency

To use this package in your code, first add the dependency to your project:

```yml
dependencies:
  ...
  easy_onvif: ^3.1.3+1
```

If you need additional help getting started with dart, check out these [guides](https://dart.dev/guides).

### Usage Example

Import the easy_onvif library.

```dart
import 'package:easy_onvif/onvif.dart';

final onvif = await Onvif.connect(
 host: [hostname or ip address],
 username: [username],
 password: [password]);
```

### Interacting with a device through Onvif operations

It's important to understand that all Onvif commands have an associated `Access Policy` assigned to them based on the table below:

|    | Administrator | Operator | User | Anonymous |
| -- | ------------- | -------- | ---- | --------- |
| PRE_AUTH | X | X | X | X |
| READ_SYSTEM | X | X | X | |
| READ_SYSTEM_SENSITIVE | X | X | | |
| READ_SYSTEM_SECRET | X | | | |
| WRITE_SYSTEM | X | | | |
| UNRECOVERABLE | X | | | |
| READ_MEDIA | X | X | X | |
| ACTUATE | X | X | | |

You can find the command and it's `Access Policy` in the [API reference](https://pub.dev/documentation/easy_onvif/latest/easy_onvif/easy_onvif-library.html) or in the spec PDF (links in the table below).  As shown in the above table, a user with `Administrator` access can use all Onvif commands.  It is recommended that you authenticate with an `Administrator` while using this package to avoid unexpected errors when sending your device different Onvif commands.

Through the `deviceManagement` operations you can get information about the connected device.

```dart
var deviceInfo = await onvif.deviceManagement.getDeviceInformation(); // Access Class: READ_SYSTEM

print(deviceInfo.model);
```

Many operations require you to supply a `profileToken` which can be retrieved through `media` operations.

```dart
var profiles = await onvif.media.getProfiles(); // Access Class: READ_MEDIA

profiles.forEach((element) {
 print('${element.name}  ${element.token}');
});

var profileToken = profiles.first.token;
```

With the `ptz` operations you can get a list of camera presets from the connected device.

```dart
var presets = await onvif.ptz.getPresets(profileToken); // ACCESS CLASS: READ_MEDIA

//get a specific preset
var preset = presets[11];

//print the preset values
print(
 'preset: ${preset.position?.panTilt?.x}  ${preset?.position.panTilt?.y}  ${preset?.position.zoom?.x}');

//use the GotoPreset operation to point the camera to the given preset
await onvif.ptz.gotoPreset(profileToken, preset); // ACCESS CLASS: ACTUATE
```

Be sure to look through the [API Reference](https://pub.dev/documentation/easy_onvif/latest/) for information about the parameters required for the supported Onvif operations.

## Lower level requests

In cases where there is no helper method for a specific Onvif operation, a low-level call can be used to make the request to the device.  The code below performs the `GetAudioOutputs` Media1 operation.  All responses take the form of a hashmap `Map<String,dynamic>`.

```dart
// code fragment for a sample low level request
//
// build a xml fragment for the specific Onvif operation
Transport.builder.element('GetAudioOutputs', nest: () { // ACCESS CLASS: READ_MEDIA
  Transport.builder.namespace(Xmlns.trt);
});

// using the connected onvif object from the earlier example
final transport = onvif.transport;

// build the soap request envelope and send the request
// since this is a media1 request, send to the media1 endpoint
final responseEnvelope = await transport.securedRequest( // include a Security header in the request
    onvif.ptz.uri,
    soap.Body(
      request: Transport.builder.buildFragment(),
    ));

print(responseEnvelope.body.response);
```

## Onvif cli (Onvif at the command prompt)

A command line interface for controlling an Onvif device with cli commands is now available as a separate package.

Install using `dart pub`:

```sh
dart pub global activate easy_onvif_cli
```

<!-- Install using `brew`:

```sh
brew tap faithoflifedev/easy_onvif
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
    --config-file    (defaults to "/Users/chris/.onvif/credentials.json")
    --log-level      [all, debug, info, warning, error, off (default)]

Available commands:
  authorize           Generate an authentication file for an Onvif device.
  debug               Generate a debug bundle for an Onvif device.
  device-management   Device management commands.
  imaging             Imaging commands.
  media1              Media ver10 commands.
  media2              Media ver20 commands.
  probe               Probe/device discovery command.
  ptz                 PTZ commands.
  recordings          Recordings commands.
  replay              Replay commands.
  search              Search commands.
  version             Display the package name and version.

Run "onvif help <command>" for more information about a command.
```

Please see the cli documentation [README.md](https://github.com/faithoflifedev/easy_onvif/blob/main/bin/README.md) for more detailed usage information.

## Supported Onvif Operations

### Device Management 

  * [Specification PDF](https://www.onvif.org/specs/core/ONVIF-Core-Specification.pdf)
  * [wsdl](https://www.onvif.org/onvif/ver10/device/wsdl/devicemgmt.wsdl) 

| Onvif Operation             | Dart Method                 | Dart Return Type                       | Test |
| --------------------------- | --------------------------- | -------------------------------------- | ---- |
| CreateUsers                 | createUsers                 | `Future<bool>`                         | [x\] |
| DeleteUsers                 | deleteUsers                 | `Future<bool>`                         | [x\] |
| GetCapabilities             | getCapabilities             | `Future<Capabilities>`                 | [x\] |
| GetDeviceInformation        | getDeviceInformation        | `Future<GetDeviceInformationResponse>` | [x\] |
| GetDiscoveryMode            | getDiscoveryMode            | `Future<String>`                       | [x\] |
| GetDNS                      | getDNS                      | `Future<DnsInformation>`               | [x\] |
| GetEndpointReference        | getEndpointReference        | `Future<Map<String, dynamic>>`         | [ \] |
| GetHostname                 | getHostname                 | `Future<HostnameInformation>`          | [x\] |
| GetIPAddressFilter          | getIPAddressFilter          | `Future<IpAddressFilter>`              | [ \] |
| GetNetworkProtocols         | getNetworkProtocols         | `Future<List<NetworkProtocol>>`        | [x\] |
| GetNTP                      | getNtp                      | `Future<NtpInformation>`               | [x\] |
| GetServiceCapabilities      | getServiceCapabilities      | `Future<DeviceServiceCapabilities>`    | [x\] |
| GetServices                 | getServices                 | `Future<List<Service>>`                | [x\] |
| GetStorageConfiguration     | getStorageConfiguration     | `Future<StorageConfiguration>`         | [ \] |
| GetStorageConfigurations    | getStorageConfigurations    | `Future<List<StorageConfiguration>>`   | [ \] |
| GetSystemDateAndTime        | getSystemDateAndTime        | `Future<SystemDateAndTime>`            | [x\] |
| GetSystemUris               | getSystemUris               | `Future<GetSystemUrisResponse>`        | [x\] |
| GetSystemLog                | getSystemLog                | `Future<SystemInformation>`            | [ \] |
| GetSystemSupportInformation | getSystemSupportInformation | `Future<SystemInformation>`            | [ \] |
| GetUsers                    | getUsers                    | `Future<List<User>>`                   | [x\] |
| SystemReboot                | systemReboot                | `Future<String>`                       | [ \] |

### Imaging

  * [Specification PDF](https://www.onvif.org/specs/srv/img/ONVIF-Imaging-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver20/imaging/wsdl/imaging.wsdl)

| Onvif Operation                 | Dart Method                     | Dart Return Type                       | Test |
| ------------------------------- | ------------------------------- | -------------------------------------- | ---- |
| GetCurrentPreset                | getCurrentPreset                | `Future<ImagingPreset>`                | [ \] |
| GetPresets                      | getPresets                      | `Future<List<ImagingPreset>>`          | [ \] |
| GetServiceCapabilities          | getServiceCapabilities          | `Future<Capabilities>`                 | [ \] |
| GetStatus                       | getStatus                       | `Future<Status>`                       | [ \] |
| SetCurrentPreset                | setCurrentPreset                | `Future<bool>`                         | [ \] |

### Media 10

  * [Specification PDF](https://www.onvif.org/specs/srv/media/ONVIF-Media-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver10/media/wsdl/media.wsdl)
  
| Onvif Operation                 | Dart Method                     | Dart Return Type                       | Test |
| ------------------------------- | ------------------------------- | -------------------------------------- | ---- |
| GetAudioSources                 | getAudioSources                 | `Future<List<AudioSource>>`            | [x\] |
| GetMetadataConfiguration        | getMetadataConfiguration        | `Future<MetadataConfiguration>`        | [x\] |
| GetMetadataConfigurations       | getMetadataConfigurations       | `Future<List<MetadataConfiguration>>`  | [x\] |
| GetProfile                      | getProfile                      | `Future<Profile>`                      | [x\] |
| GetProfiles                     | getProfiles                     | `Future<List<Profile>?>`               | [x\] |
| GetServiceCapabilities          | getServiceCapabilities          | `Future<Capabilities1>`			           | [x\] |
| GetSnapshotUri                  | getSnapshotUri                  | `Future<MediaUri>`                     | [x\] |
| GetStreamUri                    | getStreamUri                    | `Future<MediaUri>`                     | [x\] |
| GetVideoSources                 | getVideoSources                 | `Future<VideoSources>`                 | [x\] |
| StartMulticastStreaming         | startMulticastStreaming         | `Future<bool>`                         | [x\] |
| StopMulticastStreaming          | stopMulticastStreaming          | `Future<bool>`                         | [x\] |

### Media 20

  * [Specification PDF](https://www.onvif.org/specs/srv/media/ONVIF-Media2-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver20/media/wsdl/media.wsdl)

| Onvif Operation                    | Dart Method                        | Dart Return Type                           | Test |
| ---------------------------------- | ---------------------------------- | ------------------------------------------ | ---- |
| GetMetadataConfigurationOptions    | getMetadataConfigurationOptions    | `Future<MetadataConfigurationOptions>`     | [x\] |
| GetMetadataConfigurations          | getMetadataConfigurations          | `Future<List<MetadataConfiguration>>`      | [x\] |
| GetProfiles                        | getProfiles                        | `Future<List<MediaProfile>?>`              | [x\] |
| GetServiceCapabilities             | getServiceCapabilities             | `Future<Capabilities2>`                    | [x\] |
| GetSnapshotUri                     | getSnapshotUri                     | `Future<String>`                           | [x\] |
| GetStreamUri                       | getStreamUri                       | `Future<String>`                           | [x\] |
| GetVideoEncoderInstances           | getVideoEncoderInstances           | `Future<Info>`                             | [ \] |
| GetVideoSourceConfigurationOptions | getVideoSourceConfigurationOptions | `Future<VideoSourceConfigurationOptions>`  | [x\] |
| GetVideoEncoderConfigurations      | getVideoEncoderConfigurations      | `Future<List<VideoEncoder2Configuration>>` | [ \] |
| StartMulticastStreaming            | startMulticastStreaming            | `Future<bool>`                             | [x\] |
| StopMulticastStreaming             | stopMulticastStreaming             | `Future<bool>`                             | [x\] |

### PTZ 

  * [Specification PDF](https://www.onvif.org/specs/srv/ptz/ONVIF-PTZ-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver20/ptz/wsdl/ptz.wsdl) 

| Onvif Operation             | Dart Method                 | Dart Return Type                  | Test |
| --------------------------- | --------------------------- | --------------------------------- | ---- |
| AbsoluteMove                | absoluteMove                | `Future<bool>`                    | [x\] |
| ContinuousMove              | continuousMove              | `Future<bool>`                    | [x\] |
| GetCompatibleConfigurations | getCompatibleConfigurations | `Future<List<PtzConfiguration>>`  | [x\] |
| GetConfiguration            | getConfiguration            | `Future<PtzConfiguration>`        | [x\] |
| GetConfigurationOptions     | getConfigurationOptions     | `Future<PtzConfigurationOptions>` | [x\] |
| GetConfigurations           | getConfigurations           | `Future<List<PtzConfiguration>>`  | [x\] |
| GetPresets                  | getPresets                  | `Future<List<Preset>>`            | [x\] |
| GetPresetTour               | getPresetTour               | `Future<PresetTour>`              | [ \] |
| GetPresetTours              | getPresetTours              | `Future<List<PresetTours>>`       | [ \] |
| GetServiceCapabilities      | getServiceCapabilities      | `Future<Capabilities>`            | [x\] |
| GetStatus                   | getStatus                   | `Future<PtzStatus>`               | [x\] |
| GotoHomePosition            | gotoHomePosition            | `Future<bool>`                    | [x\] |
| GotoPreset                  | gotoPreset                  | `Future<bool>`                    | [x\] |
| RelativeMove                | relativeMove                | `Future<bool>`                    | [x\] |
| RemovePreset                | removePreset                | `Future<bool>`                    | [x\] |
| SetHomePosition             | setHomePosition             | `Future<bool>`                    | [x\] |
| SetPreset                   | setPreset                   | `Future<String>`                  | [x\] |
| Stop                        | stop                        | `Future<bool>`                    | [x\] |

### PTZ Helper Methods

| Onvif Operation | Dart Method      | Return Type       |
| --------------- | ---------------- | ----------------- |
| N/A             | move             | `Future<void>`    |
| N/A             | moveDown         | `Future<void>`    |
| N/A             | moveLeft         | `Future<void>`    |
| N/A             | moveRight        | `Future<void>`    |
| N/A             | moveUp           | `Future<void>`    |
| N/A             | zoomIn           | `Future<void>`    |
| N/A             | zoomOut          | `Future<void>`    |
| N/A             | getCurrentPreset | `Future<Preset?>` |

### Recording

  * [Specification PDF](https://www.onvif.org/specs/srv/rec/ONVIF-RecordingControl-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver10/recording.wsdl) 

| Onvif Operation             | Dart Method                 | Dart Return Type                             | Test |
| --------------------------- | --------------------------- | -------------------------------------------- | ---- |
| CreateRecording             | createRecording             | `Future<String>`                             | [ \] |
| CreateRecordingJob          | createRecordingJob          | `Future<CreateRecordingJobResponse>`         | [ \] |
| DeleteRecording             | deleteRecording             | `Future<bool>`                               | [ \] |
| DeleteRecordingJob          | deleteRecordingJo           | `Future<bool>`                               | [ \] |
| GetRecordingJobs            | getRecordingJobs            | `Future<List<GetRecordingJobsResponseItem>>` | [ \] |
| GetRecordingJobState        | getRecordingJobState        | `Future<List<RecordingJobStateInformation>>` | [ \] |
| GetRecordingOptions         | getRecordingOptions         | `Future<List<RecordingOptions>>`             | [ \] |
| GetRecordings               | getRecordings               | `Future<List<GetRecordingsResponseItem>>`    | [ \] |
| GetServiceCapabilities      | getServiceCapabilities      | `Future<Capabilities>`                       | [ \] |
| setRecordingJobMode         | setRecordingJobMode         | `Future<bool>`                               | [ \] |

### Replay 

  * [Specification PDF](https://www.onvif.org/specs/srv/replay/ONVIF-ReplayControl-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver10/replay.wsdl)

| Onvif Operation             | Dart Method                 | Dart Return Type                             | Test |
| --------------------------- | --------------------------- | -------------------------------------------- | ---- |
| GetReplayConfiguration      | getReplayConfiguration      | `Future<ReplayConfiguration>`                | [ \] |
| GetReplayUri                | getReplayUri                | `Future<String>`                             | [ \] |
| GetServiceCapabilities      | getServiceCapabilities      | `Future<Capabilities>`                       | [ \] |
| SetReplayConfiguration      | setReplayConfiguration      | `Future<bool>`                               | [ \] |

### Search

  * [Specification PDF](https://www.onvif.org/specs/srv/rsrch/ONVIF-RecordingSearch-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver10/search.wsdl)

| Onvif Operation           | Dart Method               | Dart Return Type                             | Test |
| ------------------------- | --------------------------| -------------------------------------------- | ---- |
| FindRecordings            | findRecordings            | `Future<String>`                             | [ \] |
| GetRecordingSearchResults | getRecordingSearchResults | `Future<List<FindRecordingResult>>`          | [ \] |
| GetRecordingInformation   | getRecordingInformation   | `Future<RecordingInformation>`               | [ \] |
| GetRecordingSummary       | getRecordingSummary       | `Future<RecordingSummary>`                   | [ \] |

## Onvif Probe

Uses Web Services Dynamic Discovery (WSDiscovery) Version 1.1 - https://docs.oasis-open.org/ws-dd/discovery/1.1/os/wsdd-discovery-1.1-spec-os.pdf - probes are sent to a multicast group, and target services that match return a response directly to the requester. To scale to a large number of endpoints and to extend the reach of the protocol, this protocol defines a managed mode of operation and a multicast suppression behavior if a discovery proxy is available on the network. To minimize the need for polling, target services that wish to be discovered send an announcement when they join and leave the network.

```dart
final multicastProbe = MulticastProbe();

await multicastProbe.probe();

print(multicastProbe.onvifDevices);
```

## Tested Onvif Devices

The values returned by the Onvif API `GetDeviceInformation` call.

| Manufacturer       | Model              | Firmware Version                             | Known Issue                      |
| ------------------ | ------------------ | -------------------------------------------- | -------------------------------- |
| Happytimesoft      | IPCamera           |                                              | limited capabilities             |
| ONVIF              | ENP1A14-IR/25X     |                                              | commands not implemented&#x00B9; |
| D-Link Corporation | DCS-6511           |                                              | commands not implemented&#x00B2; |
| [empty\]           | GX728MF-IR28       |                                              | commands not implemented&#x00B3; |
| LOREX              | LNB4421SB          |                                              | testing in progress              |
| ONVIF_IPNC         | IPG-8150PSS        | 1.3.0-20210203CN-PT                          | commands not implemented&#x2074; |
| SUNBA              | Performance-Series | IPC-B2202.3.73.C06290.NB.230628              | commands not implemented&#x2075; |
| SUNBA              | XM530_50X50-WG_8M  | V5.00.R02.L5330747.10010.349917..ONVIF 16.12 | commands not implemented&#x2076; |
| [empty\]           | IPD-H4K8M05-BS     | V1.04.10-190309                              | commands not implemented&#x2077; |

&#x00B9; The ENP1A14-IR/25X does not support the following commands:
* Recordings
  * `CreateRecording`
  * `DeleteRecording`

&#x00B2; The DCS-6511 does not support the following commands: 
* Device Management:
  * `GetServices`
  * `GetServiceCapabilities`
* Media1:
  * `GetMetadataConfiguration`
  * `GetProfile`
  * `GetServiceCapabilities`
* Media2:
  * is not supported by this device
* PTZ:
  * not tested

&#x00B3; The GX728MF-IR28 does not support the following commands: 
* Device Management:
  * `GetSystemUris`
* Media1:
  * `GetMetadataConfiguration`
  * `GetProfile`
  * `GetStreamUri`
  * `StartMulticastStreaming`
  * `StopMulticastStreaming`
* Media2:
  * `GetStreamUri`
  * `StartMulticastStreaming`
  * `StopMulticastStreaming`
* PTZ:
  * not supported

&#x2074; The IPG-8150PSS does not support the following commands: 
* Device Management:
  * `GetStorageConfigurations`
  * `GetStorageConfiguration`
  * `GetEndpointReference`
  * `GetSystemSupportInformation`
* PTZ
  * `GetPresetTours`
  * `GetPresetTour`
  * `GotoHomePosition` - supported but not functioning
  * `SetHomePosition` - supported but not functioning

&#x2075; The SUNBA does not support the following commands: 
* Device Management:
  * `CreateUsers`
  * `DeleteUsers`
  * `GetStorageConfigurations`
  * `GetStorageConfiguration`
  * `GetSystemUris`
* Media1:
  * `GetStreamUri` - but it works in Media2
* PTZ:
  * `GotoHomePosition` - No Home Position
  * `RelativeMove` - work-around available with the `move` helper
  * `SetHomePosition`

&#x2076; The SUNBA-405 does not support the following commands: 
* Device Management:
  * `CreateUsers`
  * `DeleteUsers`
  * `GetStorageConfigurations`
  * `GetStorageConfiguration`
  * `GetSystemUris`
* Media1: 
  * `GetSnapshotUri` - device provides an incorrect value, see [What is the HTTP Snapshot URL for Sunba IP cameras?](https://www.sunbatech.com/faq/what-is-the-http-snapshot-url-for-sunba-ip-cameras/)
  * `GetStreamUri` - device provides an incorrect value, see [What is the RTSP stream URL for Sunba IP cameras?](https://www.sunbatech.com/faq/what-is-the-rtsp-stream-url-for-sunba-ip-cameras/)
* Media2:
  * `GetSnapshotUri` - device provides an incorrect value, see [What is the HTTP Snapshot URL for Sunba IP cameras?](https://www.sunbatech.com/faq/what-is-the-http-snapshot-url-for-sunba-ip-cameras/)
  * `GetStreamUri` - device provides an incorrect value, see [What is the RTSP stream URL for Sunba IP cameras?](https://www.sunbatech.com/faq/what-is-the-rtsp-stream-url-for-sunba-ip-cameras/)
* PTZ:
  * `GetCompatibleConfigurations`
  * `GetCurrentPreset`
  * `GetPresetTours`
  * `GotoHomePosition` - supported but not functional
  * `RelativeMove` - work-around available with the `move` helper
  * `SetHomePosition` - supported but not functional
  * `Stop` - package v3.1.3 uses `ContinuousMove` with velocity set to 0 as an alternative to the Stop command.

&#x2077; IPD-H4K8M05-BS does not support the following commands: 
* Device Management:
  * `CreateUsers`
  * `DeleteUsers` - supported but not functional
  * `GetStorageConfigurations`
  * `GetStorageConfiguration`
* Media1:
  * `GetAudioSourcesResponse` - device has no audio support 
  * `StartMulticastStreamingResponse`
  * `StopMulticastStreamingResponse` - supported but not functional
* Media2:
  * is not supported by this device
* PTZ:
  * `AbsoluteMove` - supported but not functional
  * `GetStatus` - supported but not functional
  * `GotoHomePosition` - supported but not functional
  * `GotoPreset` - supported but not functional
  * `RelativeMove` - work-around available with the `move` helper
  * `RemovePreset` - supported but not functional
  * `SetHomePosition` - supported but not functional
  
## New for version 3.1.3
The Onvif spec supports an alternative to the `Stop` command that instead uses the `ContinuousMove` command with velocity settings to zero.  This alternative appears to be compatible with more devices.  As such, the `Stop` API call has been replaces with a zero velocity `ContinuousMove` command as of the v3.1.3 release.

## New for version 3.1.0

See the [Breaking changes](#breaking-changes) section.

## New for version 3.0.0-dev.0

Bug fixes for a number of small bugs that got introduced through adding some experimental features in some of the previous releases.  The main issues identified and resolved where in the areas of Authentication [Issue #58](https://github.com/faithoflifedev/easy_onvif/issues/58), PTZ [Issue #54](https://github.com/faithoflifedev/easy_onvif/issues/54) and the Media2 module (no issue reported).  In addition all currently supported SOAP requests now have unit tests to confirm that the package continues to create the requests properly as the code evolves.  Finally, there have been extensive code revisions to help with the long term maintenance of the package.  As part of this a number of method signatures have changed as well as some of the objects in the object model have been renamed.  For the most part these changes are in the lower level interfaces within the package and should not affect many users.

## New for version 2.2.x

A new `cli` command has been added that will hopefully ease in debugging issues with this library when it comes to the vast variety of Onvif devices that are out in the wild.  Once the `cli` utility has been installed and authorized per the [quick start instructions](https://github.com/faithoflifedev/easy_onvif/blob/main/bin/README.md#quick-start), the command `onvif debug` will create a debug folder with a `debug.txt` and `debug.zip` that can be added to an [issue](https://github.com/faithoflifedev/easy_onvif/issues) to help to debug and resolve that issue.

## Onvif specifications and documentation

https://www.onvif.org/profiles/specifications/

## Features and bugs

Please file feature requests and bugs with [the issue tracker](https://github.com/faithoflifedev/easy_onvif/issues).

## Possible unexpected behavior

The helper method `move` in the PTZ module will fallback to `AbsoluteMove` if `RelativeMove` is not supported by the device.  The `move` command is not currently aware of the device bounds , so using the command to change the `x` position of the device hen the device has already at max `x` will have no affect.  The same would go for the `y` position and for `zoom`.

## Known Issues

### Issue #45

Github Issue [#45](https://github.com/faithoflifedev/easy_onvif/issues/45), when using **v2.1.2+13** (and likely earlier) on Windows 11 (and probably 10) the following error will the displayed when attempting to use the `Multicast.probe` method.  

```text
Unhandled exception:
SocketException: Failed to create datagram socket (OS Error: The requested address is not valid in its context., errno = 10049), address = 239.255.255.250, port = 3702
```

This is due to a bug in the underlying Dart SDK [#53477](https://github.com/flutter/flutter/issues/53477).

With the help of [Viper-Bit](https://github.com/Viper-Bit) (who has supplied a c++ workaround that uses Dart FFI) and [Add00](https://github.com/Add00) (building and testing the c++ code on Windows 11) version *2.1.3* and up of the package now uses Dart FFI to resolve this issue on the Windows platform.  For Flutter Windows applications there is a supplied `discovery.dll` file that must be placed in the `assets` folder and referenced in the `pubspec.yaml`, for Windows Dart (cli) apps the `discovery.dll` defaults to the folder derived as `join(Directory.current.path, 'bin', 'discovery.dll')`.  Alternatively, cli apps on Windows can use the `ONVIF_DISCOVERY_DLL` environment variable to override the default path for instance:

```text
$env:ONVIF_DISCOVERY_DLL="example/flutter_model/assets/discovery.dll"

dart run bin/onvif.dart probe list-devices
```

The `discovery.dll` file can be found in the [bin](https://github.com/faithoflifedev/easy_onvif/tree/win-ffi/bin) folder of the project on GitHub.

## Breaking changes

### v3.1.0

This version adds `web` platform support to the package.  To accomplish this any dependencies on `dart:io` had to be removed from the main package.  In most cases this was appropriate since the file operations typically were used by the supplied `cli` utility, so the code was moved there.  However there are some cases like Onvif device system logs that work best with files so the API signatures for these have changed.

In addition, it's important to keep in mind that when code operates within a browser there are typically security restrictions in place, so you've now been warned that your milage may vary when you attempt to use this package on the web platform.  To get the most out of the included sample app you can run it with the following command:

```sh
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-renderer html
```

Which disables chrome's security and allows it to make the networking call necessary to connect with an Onvif device.  If anyone knows of a better method to achieve this, please open an [issue](https://github.com/faithoflifedev/easy_onvif/issues) and let me know.  Also keep in mind that the browser may limit access to things like snapshot images from the device due to security restrictions.


### v3.0.0-dev.0

There have been extensive code revisions to help with the long term maintenance of the package.  As part of this a number of method signatures have changed as well as some of the objects in the object model have been renamed.  For the most part these changes are in the lower level interfaces within the package and should not affect too many users.

### v2.3.0

For this release a number of `Common` classes where given name changes to better reflect the Onvif spec.  Since these classes are used fairly deep in the API it's unlikely that if will affect many users.  In addition in the current release these changes are limits to the `PTZ` module, so if the changes cause issue, it would only be in this section of the code.

## Contributors

- <img src="https://avatars.githubusercontent.com/u/923202?v=4" width="25" height="25"> [faithoflifedev](https://github.com/faithoflifedev)
- <img src="https://avatars.githubusercontent.com/u/38936462?v=4" width="25" height="25"> [LODYZ](https://github.com/LODYZ)
- <img src="https://avatars.githubusercontent.com/u/60050879?v=4" width="25" height="25"> [Add00](https://github.com/Add00)
- <img src="https://avatars.githubusercontent.com/u/24822764?v=4" width="25" height="25"> [Viper-Bit](https://github.com/Viper-Bit)
- <img src="https://avatars.githubusercontent.com/u/53707700?v=4" width="25" height="25"> [itsparth](https://github.com/itsparth)
- <img src="https://avatars.githubusercontent.com/u/26508767?v=4" width="25" height="25"> [momshaddinury](https://github.com/momshaddinury)
 
## Contributing

Any help from the open-source community is always welcome and needed:
- Found an issue?
    - Please fill a bug report with details.
- Need a feature?
    - Open a feature request with use cases.
- Are you using and liking the project?
    - Promote the project: create an article or post about it
    - Make a donation
- Do you have a project that uses this package
    - let's cross promote, let me know and I'll add a link to your project
- Are you a developer?
    - Fix a bug and send a pull request.
    - Implement a new feature.
    - Improve the Unit Tests.
- Have you already helped in any way?
    - **Many thanks from me, the contributors and everybody that uses this project!**

*If you donate 1 hour of your time, you can contribute a lot,
because others will do the same, just be part and start with your 1 hour.*