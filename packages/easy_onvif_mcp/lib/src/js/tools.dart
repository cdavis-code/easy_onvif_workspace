/// The Node.js tool registry.
///
/// The Dart VM binary registers the dispatcher generated from the `@Tool`
/// annotations on [EasyOnvifMcpServer]; this registry is what the compiled
/// `npx easy-onvif-mcp` bundle serves instead, because the generated code
/// imports `dart:io`. Both call the same annotated methods, so the behaviour
/// of a tool lives in one place and only its name/schema is repeated here.
///
/// Deliberately omitted: device-mutating operations (reboot, user management,
/// hostname / DNS / NTP / network-protocol / IP-filter writes). A stdio server
/// holding live camera credentials should not hand a model a `system_reboot`
/// button by default.
library;

import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:easy_onvif/media1.dart' as m1;
import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/ptz.dart';
import 'package:easy_onvif/shared.dart';

import '../easy_onvif_mcp_server.dart';
import 'tool_defs.dart';

/// The complete tool list, grouped by ONVIF service.
List<ToolDef> buildOnvifTools() => [
  // ==========================================================================
  // Connection lifecycle
  // ==========================================================================
  ToolDef(
    name: 'onvif_connect',
    description:
        'Connect to an ONVIF device and discover its services. Required before '
        'any other tool unless ONVIF_HOST / ONVIF_USERNAME / ONVIF_PASSWORD (or '
        '~/.onvif/credentials.json) are set, in which case the first call '
        'connects automatically.',
    inputSchema: deviceArgs,
    // Carries a credential: validate in the handler (requiredString) rather
    // than letting dart_mcp echo a rejected value back into the transcript.
    validateArguments: false,
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.connectTo(
        host: requiredString(args, 'host'),
        username: requiredString(args, 'username'),
        password: requiredString(args, 'password'),
      );
      return {
        'connected': true,
        'host': onvif.authInfo.host,
        'services': onvif.serviceMap.keys.toList(),
      };
    },
  ),

  ToolDef.noArgs(
    name: 'onvif_disconnect',
    description: 'Close the current device connection.',
    dispatch: (args) async {
      await EasyOnvifMcpServer.disconnectDevice();
      return {'connected': false};
    },
  ),

  ToolDef.noArgs(
    name: 'onvif_is_connected',
    description: 'Return whether a device connection is currently held.',
    dispatch: (args) => {'connected': EasyOnvifMcpServer.hasClient},
  ),

  ToolDef.noArgs(
    name: 'onvif_status',
    description:
        'Report whether a device is connected and which services were discovered.',
    dispatch: (args) async {
      if (!EasyOnvifMcpServer.hasClient) return {'connected': false};
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      return {
        'connected': true,
        'host': onvif.authInfo.host,
        'services': onvif.serviceMap.keys.toList(),
      };
    },
  ),

  ToolDef(
    name: 'onvif_probe',
    description:
        'WS-Discovery multicast probe. Finds ONVIF devices on the local network '
        'without needing credentials.',
    inputSchema: ObjectSchema(
      properties: {
        'timeout': Schema.int(
          description: 'Seconds to listen for probe responses (default 2).',
          minimum: 1,
          maximum: 120,
        ),
      },
    ),
    dispatch: (args) async {
      final timeout = optionalInt(args, 'timeout') ?? 2;
      final devices = await EasyOnvifMcpServer.probeDevices(timeout);
      return {'devices': devices, 'count': devices.length};
    },
  ),

  // ==========================================================================
  // Device management (read-only)
  // ==========================================================================
  _device(
    'onvif_get_device_information',
    'Manufacturer, model, firmware, serial number and hardware id of the device.',
    (onvif) => onvif.deviceManagement.getDeviceInformation(),
  ),

  _device(
    'onvif_get_services',
    'The services the device implements, with their endpoint URLs.',
    (onvif) => onvif.deviceManagement.getServices(includeCapability: true),
  ),

  _device(
    'onvif_get_capabilities',
    'The full device capability report (all categories).',
    (onvif) => onvif.deviceManagement.getCapabilities(),
  ),

  _device(
    'onvif_get_system_date_and_time',
    'The device clock, including whether it is NTP or manually set.',
    (onvif) => onvif.deviceManagement.getSystemDateAndTime(),
  ),

  _device(
    'onvif_get_hostname',
    'The device hostname and whether it is DHCP-assigned.',
    (onvif) => onvif.deviceManagement.getHostname(),
  ),

  _device(
    'onvif_get_dns',
    'The device DNS configuration.',
    (onvif) => onvif.deviceManagement.getDns(),
  ),

  _device(
    'onvif_get_ntp',
    'The device NTP configuration.',
    (onvif) => onvif.deviceManagement.getNtp(),
  ),

  _device(
    'onvif_get_dynamic_dns',
    'The device dynamic DNS settings (type, name, TTL).',
    (onvif) => onvif.deviceManagement.getDynamicDns(),
  ),

  _device(
    'onvif_get_network_protocols',
    'Configured network protocols with ports and enabled flags.',
    (onvif) => onvif.deviceManagement.getNetworkProtocols(),
  ),

  _device(
    'onvif_get_users',
    'The registered device users and their access levels.',
    (onvif) => onvif.deviceManagement.getUsers(),
  ),

  _device(
    'onvif_get_relay_outputs',
    'The available relay outputs and their settings.',
    (onvif) => onvif.deviceManagement.getRelayOutputs(),
  ),

  _device(
    'onvif_get_storage_configurations',
    'The storage configurations (SD cards, mounts) the device reports.',
    (onvif) => onvif.deviceManagement.getStorageConfigurations(),
  ),

  _device(
    'onvif_get_discovery_mode',
    'The discovery mode of the device (e.g. `Discoverable` / `DiscoverableInUse`).',
    (onvif) => onvif.deviceManagement.getDiscoveryMode(),
  ),

  _device(
    'onvif_get_endpoint_reference',
    'The device service endpoint reference, used to derive the password '
        'equivalent for remote user operation.',
    (onvif) => onvif.deviceManagement.getEndpointReference(),
  ),

  // ==========================================================================
  // Media
  // ==========================================================================
  ToolDef(
    name: 'onvif_get_profiles',
    description:
        'All media profiles. Every other media and PTZ tool needs a '
        '`profile_token` from this list.',
    inputSchema: ObjectSchema(
      properties: {
        'reference_token': Schema.string(
          description: 'Optional profile token to fetch a single profile.',
        ),
      },
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      return onvif.media.getProfiles(
        referenceToken: optionalString(args, 'reference_token'),
      );
    },
  ),

  ToolDef(
    name: 'onvif_get_profile',
    description:
        'A single media profile by token, as reported by the Media1 service of '
        'the device. Use onvif_get_profiles on Media2-only devices.',
    inputSchema: profileTokenArgs,
    dispatch: _profile(
      (onvif, profileToken) => onvif.media.getProfile(profileToken),
    ),
  ),

  ToolDef(
    name: 'onvif_get_stream_uri',
    description:
        'The RTSP URI for a live stream from the given profile, with credentials '
        'embedded where the device allows it.',
    inputSchema: profileTokenArgs,
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      final uri = await onvif.media.getStreamUri(
        requiredString(args, 'profile_token'),
      );
      return {'uri': uri};
    },
  ),

  ToolDef(
    name: 'onvif_get_snapshot_uri',
    description: 'The URI that returns a JPEG snapshot for the given profile.',
    inputSchema: profileTokenArgs,
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      // The Media facade already reconciles Media1 (MediaUri) and Media2
      // (bare string) responses.
      final uri = await onvif.media.getSnapshotUri(
        requiredString(args, 'profile_token'),
      );
      return {'uri': uri};
    },
  ),

  _device(
    'onvif_get_video_sources',
    'The physical video inputs available on the device (Media1 only).',
    (onvif) => onvif.media.getVideoSources(),
  ),

  _device(
    'onvif_get_audio_sources',
    'The physical audio inputs available on the device (Media1 only).',
    (onvif) => onvif.media.getAudioSources(),
  ),

  _device(
    'onvif_get_media_service_capabilities',
    'The capabilities of the device Media service.',
    (onvif) => onvif.media.getServiceCapabilities(),
  ),

  // ==========================================================================
  // PTZ
  // ==========================================================================
  ToolDef(
    name: 'onvif_ptz_get_status',
    description: 'The current PTZ position and movement state.',
    inputSchema: profileTokenArgs,
    dispatch: _profile(
      (onvif, profileToken) => onvif.ptz.getStatus(profileToken),
    ),
  ),

  ToolDef(
    name: 'onvif_ptz_get_presets',
    description: 'All saved PTZ presets for the profile, with their tokens.',
    inputSchema: ObjectSchema(
      properties: {
        'profile_token': Schema.string(description: 'Media profile token.'),
        'limit': Schema.int(
          description: 'Maximum presets to return (default 100).',
          minimum: 1,
        ),
      },
      required: ['profile_token'],
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      return onvif.ptz.getPresets(
        requiredString(args, 'profile_token'),
        limit: optionalInt(args, 'limit'),
      );
    },
  ),

  ToolDef(
    name: 'onvif_ptz_get_configurations',
    description: 'All PTZ configurations defined on the device.',
    inputSchema: ObjectSchema(properties: const {}),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      return onvif.ptz.getConfigurations();
    },
  ),

  ToolDef(
    name: 'onvif_ptz_goto_preset',
    description: 'Move the camera to a saved preset.',
    inputSchema: ObjectSchema(
      properties: {
        'profile_token': Schema.string(description: 'Media profile token.'),
        'preset_token': Schema.string(
          description: 'Preset token, from onvif_ptz_get_presets.',
        ),
      },
      required: ['profile_token', 'preset_token'],
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      await onvif.ptz.gotoPreset(
        requiredString(args, 'profile_token'),
        presetToken: requiredString(args, 'preset_token'),
      );
      return {'ok': true};
    },
  ),

  ToolDef(
    name: 'onvif_ptz_set_preset',
    description:
        'Save the current camera position as a preset. Returns the preset token.',
    inputSchema: ObjectSchema(
      properties: {
        'profile_token': Schema.string(description: 'Media profile token.'),
        'preset_name': Schema.string(
          description: 'Human readable preset name.',
        ),
        'preset_token': Schema.string(
          description: 'Existing token to overwrite instead of creating one.',
        ),
      },
      required: ['profile_token'],
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      final token = await onvif.ptz.setPreset(
        requiredString(args, 'profile_token'),
        presetName: optionalString(args, 'preset_name'),
        presetToken: optionalString(args, 'preset_token'),
      );
      return {'preset_token': token};
    },
  ),

  ToolDef(
    name: 'onvif_ptz_remove_preset',
    description: 'Delete a saved preset.',
    inputSchema: ObjectSchema(
      properties: {
        'profile_token': Schema.string(description: 'Media profile token.'),
        'preset_token': Schema.string(description: 'Preset token to remove.'),
      },
      required: ['profile_token', 'preset_token'],
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      final preset = Preset.fromToken(requiredString(args, 'preset_token'));
      await onvif.ptz.removePreset(
        requiredString(args, 'profile_token'),
        preset: preset,
      );
      return {'ok': true};
    },
  ),

  ToolDef(
    name: 'onvif_ptz_absolute_move',
    description:
        'Move pan/tilt/zoom to an absolute position in the profile\'s coordinate '
        'space (typically -1.0 to 1.0 for pan/tilt).',
    inputSchema: _vectorSchema(
      'Absolute target position for pan, tilt and zoom.',
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      await onvif.ptz.absoluteMove(
        requiredString(args, 'profile_token'),
        position: _ptzVector(args),
      );
      return {'ok': true};
    },
  ),

  ToolDef(
    name: 'onvif_ptz_relative_move',
    description:
        'Move pan/tilt/zoom by a relative amount from the current position.',
    inputSchema: _vectorSchema('Relative translation to apply.'),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      await onvif.ptz.relativeMove(
        requiredString(args, 'profile_token'),
        _ptzVector(args),
        null,
      );
      return {'ok': true};
    },
  ),

  ToolDef(
    name: 'onvif_ptz_continuous_move',
    description:
        'Move at a constant velocity until stopped. Pair with '
        'onvif_ptz_stop (or pass a timeout where the device honours one).',
    inputSchema: ObjectSchema(
      properties: {
        'profile_token': Schema.string(description: 'Media profile token.'),
        'pan_tilt_x': Schema.num(description: 'Pan velocity (-1.0 to 1.0).'),
        'pan_tilt_y': Schema.num(description: 'Tilt velocity (-1.0 to 1.0).'),
        'zoom': Schema.num(description: 'Zoom velocity (-1.0 to 1.0).'),
        'timeout': Schema.int(
          description: 'Optional device-side timeout, seconds.',
        ),
      },
      required: ['profile_token'],
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      await onvif.ptz.continuousMove(
        requiredString(args, 'profile_token'),
        velocity: PtzSpeed(
          panTilt: Vector2D(
            x: optionalNumber(args, 'pan_tilt_x') ?? 0,
            y: optionalNumber(args, 'pan_tilt_y') ?? 0,
          ),
          zoom: optionalNumber(args, 'zoom') == null
              ? null
              : Vector1D(x: optionalNumber(args, 'zoom')!),
        ),
        timeout: optionalInt(args, 'timeout'),
      );
      return {'ok': true};
    },
  ),

  ToolDef(
    name: 'onvif_ptz_stop',
    description: 'Stop ongoing pan/tilt and/or zoom movement.',
    inputSchema: ObjectSchema(
      properties: {
        'profile_token': Schema.string(description: 'Media profile token.'),
        'pan_tilt': Schema.bool(description: 'Stop pan/tilt (default true).'),
        'zoom': Schema.bool(description: 'Stop zoom (default true).'),
      },
      required: ['profile_token'],
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      await onvif.ptz.stop(
        requiredString(args, 'profile_token'),
        panTilt: optionalBool(args, 'pan_tilt', fallback: true),
        zoom: optionalBool(args, 'zoom', fallback: true),
      );
      return {'ok': true};
    },
  ),

  ToolDef(
    name: 'onvif_ptz_move',
    description:
        'One small step in a direction, with automatic fallback when the device '
        'rejects relative moves. Use for "pan left a little" style commands.',
    inputSchema: ObjectSchema(
      properties: {
        'profile_token': Schema.string(description: 'Media profile token.'),
        'x': Schema.num(
          description: 'Pan delta; positive pans right (default 0.025).',
        ),
        'y': Schema.num(
          description: 'Tilt delta; positive tilts up (default 0.025).',
        ),
        'zoom': Schema.num(description: 'Zoom delta (default 0).'),
      },
      required: ['profile_token'],
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      await onvif.ptz.move(
        requiredString(args, 'profile_token'),
        direction: Vector2D(
          x: optionalNumber(args, 'x') ?? 0.025,
          y: optionalNumber(args, 'y') ?? 0.025,
        ),
        zoom: optionalNumber(args, 'zoom') == null
            ? null
            : Vector1D(x: optionalNumber(args, 'zoom')!),
      );
      return {'ok': true};
    },
  ),

  _stepTool(
    'onvif_ptz_move_up',
    'Tilt the camera up by one step.',
    (ptz, token, step) =>
        step == null ? ptz.moveUp(token) : ptz.moveUp(token, step),
  ),
  _stepTool(
    'onvif_ptz_move_down',
    'Tilt the camera down by one step.',
    (ptz, token, step) =>
        step == null ? ptz.moveDown(token) : ptz.moveDown(token, step),
  ),
  _stepTool(
    'onvif_ptz_move_left',
    'Pan the camera left by one step.',
    (ptz, token, step) =>
        step == null ? ptz.moveLeft(token) : ptz.moveLeft(token, step),
  ),
  _stepTool(
    'onvif_ptz_move_right',
    'Pan the camera right by one step.',
    (ptz, token, step) =>
        step == null ? ptz.moveRight(token) : ptz.moveRight(token, step),
  ),

  ToolDef(
    name: 'onvif_ptz_zoom',
    description: 'One zoom step. Positive zooms in, negative zooms out.',
    inputSchema: ObjectSchema(
      properties: {
        'profile_token': Schema.string(description: 'Media profile token.'),
        'x': Schema.num(description: 'Zoom step (default 0.025).'),
      },
      required: ['profile_token'],
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      await onvif.ptz.zoom(
        requiredString(args, 'profile_token'),
        Vector1D(x: optionalNumber(args, 'x') ?? 0.025),
      );
      return {'ok': true};
    },
  ),

  _device(
    'onvif_ptz_get_service_capabilities',
    'The capabilities of the device PTZ service.',
    (onvif) => onvif.ptz.getServiceCapabilities(),
  ),

  // ==========================================================================
  // Imaging (read-only)
  // ==========================================================================
  ToolDef(
    name: 'onvif_imaging_get_status',
    description: 'The current imaging settings for a video source.',
    inputSchema: _videoSourceSchema('The current imaging settings.'),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      return onvif.imaging.getStatus(
        requiredString(args, 'video_source_token'),
      );
    },
  ),

  ToolDef(
    name: 'onvif_imaging_get_presets',
    description: 'The imaging presets available for a video source.',
    inputSchema: _videoSourceSchema('The imaging presets.'),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      return onvif.imaging.getPresets(
        requiredString(args, 'video_source_token'),
      );
    },
  ),

  ToolDef(
    name: 'onvif_imaging_get_current_preset',
    description: 'The imaging preset currently applied to a video source.',
    inputSchema: _videoSourceSchema('The imaging in use.'),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      return onvif.imaging.getCurrentPreset(
        requiredString(args, 'video_source_token'),
      );
    },
  ),

  // ==========================================================================
  // Recordings, replay and search
  // ==========================================================================
  _device(
    'onvif_get_recordings',
    'The recordings stored on the device.',
    (onvif) => onvif.recordings.getRecordings(),
  ),

  _device(
    'onvif_get_recording_jobs',
    'The recording jobs configured on the device.',
    (onvif) => onvif.recordings.getRecordingJobs(),
  ),

  ToolDef(
    name: 'onvif_get_replay_uri',
    description: 'The RTSP URI to replay a stored recording.',
    inputSchema: ObjectSchema(
      properties: {
        'recording_token': Schema.string(
          description: 'Recording token, from onvif_get_recordings.',
        ),
      },
      required: ['recording_token'],
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      final uri = await onvif.replay.getReplayUri(
        requiredString(args, 'recording_token'),
        streamSetup: _unicastStreamSetup(),
      );
      return {'uri': uri};
    },
  ),

  _device(
    'onvif_get_recording_summary',
    'A summary of the recordings available on the device.',
    (onvif) => onvif.search.getRecordingSummary(),
  ),

  ToolDef(
    name: 'onvif_find_recordings',
    description:
        'Starts a recording search and returns the search token. Poll '
        'onvif_get_recording_search_results with that token for matches.',
    inputSchema: ObjectSchema(
      properties: {
        'keep_alive_time': Schema.int(
          description: 'How long the search stays alive, in seconds (e.g. 5).',
          minimum: 1,
        ),
        'max_matches': Schema.int(
          description: 'Upper bound on matches the device should return.',
          minimum: 1,
        ),
      },
      required: ['keep_alive_time'],
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      final token = await onvif.search.findRecordings(
        keepAliveTime: optionalInt(args, 'keep_alive_time') ?? 5,
        maxMatches: optionalInt(args, 'max_matches'),
      );
      return {'search_token': token};
    },
  ),

  ToolDef(
    name: 'onvif_get_recording_search_results',
    description:
        'Fetches results for a search token from onvif_find_recordings, waiting '
        'up to `wait_time` seconds for more matches to arrive.',
    inputSchema: ObjectSchema(
      properties: {
        'search_token': Schema.string(
          description: 'Token from onvif_find_recordings.',
        ),
        'wait_time': Schema.string(
          description: 'ISO 8601 duration to wait for results, e.g. `PT5S`.',
        ),
      },
      required: ['search_token'],
    ),
    dispatch: (args) async {
      final onvif = await EasyOnvifMcpServer.ensureConnected();
      return onvif.search.getRecordingSearchResults(
        requiredString(args, 'search_token'),
        waitTime: optionalString(args, 'wait_time') ?? 'PT5S',
      );
    },
  ),
];

// ---------------------------------------------------------------------------
// Registry helpers
// ---------------------------------------------------------------------------

/// A no-argument tool that reads from the connected device.
ToolDef _device(
  String name,
  String description,
  FutureOr<Object?> Function(Onvif onvif) call,
) => ToolDef.noArgs(
  name: name,
  description: description,
  dispatch: (args) async => call(await EasyOnvifMcpServer.ensureConnected()),
);

/// A tool that takes a profile token and nothing else.
FutureOr<Object?> Function(Map<String, dynamic>) _profile(
  FutureOr<Object?> Function(Onvif onvif, String profileToken) call,
) => (args) async {
  final onvif = await EasyOnvifMcpServer.ensureConnected();
  return call(onvif, requiredString(args, 'profile_token'));
};

/// The unicast RTP / RTSP stream setup Media1 and Replay insist on.
m1.StreamSetup _unicastStreamSetup() => m1.StreamSetup(
  stream: 'RTP-Unicast',
  transport: m1.Transport(protocol: 'RTSP'),
);

/// A schema for the pan/tilt/zoom vector tools.
ObjectSchema _vectorSchema(String what) => ObjectSchema(
  properties: {
    'profile_token': Schema.string(description: 'Media profile token.'),
    'pan_tilt_x': Schema.num(description: '$what — pan axis.'),
    'pan_tilt_y': Schema.num(description: '$what — tilt axis.'),
    'zoom': Schema.num(description: '$what — zoom axis.'),
  },
  required: ['profile_token', 'pan_tilt_x', 'pan_tilt_y'],
);

/// Builds the pan/tilt/zoom vector shared by the move tools.
PtzVector _ptzVector(Map<String, dynamic> args) => PtzVector(
  panTilt: Vector2D(
    x: requiredNumber(args, 'pan_tilt_x'),
    y: requiredNumber(args, 'pan_tilt_y'),
  ),
  zoom: optionalNumber(args, 'zoom') == null
      ? null
      : Vector1D(x: optionalNumber(args, 'zoom')!),
);

/// A one-step PTZ helper tool. [move] chooses the device method so each entry
/// keeps the API's own signed default step when the caller omits one.
ToolDef _stepTool(
  String name,
  String description,
  Future<void> Function(Ptz ptz, String profileToken, double? step) move,
) => ToolDef(
  name: name,
  description: description,
  inputSchema: ObjectSchema(
    properties: {
      'profile_token': Schema.string(description: 'Media profile token.'),
      'step': Schema.num(
        description: 'Magnitude of the step; omit to use the device default.',
      ),
    },
    required: ['profile_token'],
  ),
  dispatch: (args) async {
    final onvif = await EasyOnvifMcpServer.ensureConnected();
    await move(
      onvif.ptz,
      requiredString(args, 'profile_token'),
      optionalNumber(args, 'step'),
    );
    return {'ok': true};
  },
);

/// A schema for the video-source-scoped imaging tools.
ObjectSchema _videoSourceSchema(String what) => ObjectSchema(
  properties: {
    'video_source_token': Schema.string(
      description: 'Video source token, from onvif_get_video_sources. $what',
    ),
  },
  required: ['video_source_token'],
);
