import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:easy_onvif/ptz.dart';
import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/util.dart';

import 'onvif_helper_command.dart';

class OnvifPtzCommand extends Command {
  @override
  String get description => 'PTZ commands.';

  @override
  String get name => 'ptz';

  OnvifPtzCommand() {
    addSubcommand(OnvifAbsoluteMovePtzCommand());
    addSubcommand(OnvifContinuousMovePtzCommand());
    addSubcommand(OnvifGetCompatibleConfigurationsPtzCommand());
    addSubcommand(OnvifGetConfigurationPtzCommand());
    addSubcommand(OnvifGetConfigurationOptionsPtzCommand());
    addSubcommand(OnvifGetConfigurationsPtzCommand());
    addSubcommand(OnvifGetCurrentPresetPtzCommand());
    addSubcommand(OnvifGetPresetsPtzCommand());
    addSubcommand(OnvifGetPresetTourPtzCommand());
    addSubcommand(OnvifGetPresetToursPtzCommand());
    addSubcommand(OnvifGetServiceCapabilitiesPtzCommand());
    addSubcommand(OnvifGetStatusPtzCommand());
    addSubcommand(OnvifGotoHomePositionPtzCommand());
    addSubcommand(OnvifGotoPresetPtzCommand());
    addSubcommand(OnvifRelativeMovePtzCommand());
    addSubcommand(OnvifRemovePresetPtzCommand());
    addSubcommand(OnvifSetHomePositionPtzCommand());
    addSubcommand(OnvifSetPresetPtzCommand());
    addSubcommand(OnvifStopPtzCommand());
    addSubcommand(OnvifMovePtzCommand());
    addSubcommand(OnvifMoveDownPtzCommand());
    addSubcommand(OnvifMoveLeftPtzCommand());
    addSubcommand(OnvifMoveRightPtzCommand());
    addSubcommand(OnvifMoveUpPtzCommand());
    addSubcommand(OnvifZoomPtzCommand());
    addSubcommand(OnvifZoomInPtzCommand());
    addSubcommand(OnvifZoomOutPtzCommand());
  }
}

/// Operation to move pan,tilt or zoom to a absolute destination.
///
/// The speed argument is optional. If an x/y speed value is given it is up to
/// the device to either use the x value as absolute resulting speed vector or
/// to map x and y to the component speed. If the speed argument is omitted, the
/// default speed set by the PTZConfiguration will be used.
class OnvifAbsoluteMovePtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation to move pan,tilt or zoom to a absolute destination.';

  @override
  String get name => 'absolute-move';

  OnvifAbsoluteMovePtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'pan-tilt-x',
        valueHelp: 'double',
        help:
            'A Position vector specifying the absolute target position x-axis.',
      )
      ..addOption(
        'pan-tilt-y',
        valueHelp: 'double',
        help:
            'A Position vector specifying the absolute target position y-axis.',
      )
      ..addOption(
        'pan-tilt-zoom',
        valueHelp: 'double',
        help: 'A Position vector specifying the absolute target position zoom.',
      );
  }

  @override
  void run() async {
    if (argResults?['pan-tilt-x'] == null &&
        argResults?['pan-tilt-y'] == null &&
        argResults?['pan-tilt-zoom'] == null) {
      throw UsageException(
        'API usage error:',
        'Either pan-tilt (both x and y values) or pan-tilt-zoom must be specified.',
      );
    } else if ((argResults?['pan-tilt-x'] != null &&
            argResults?['pan-tilt-y'] == null) ||
        (argResults?['pan-tilt-x'] == null &&
            argResults?['pan-tilt-y'] != null)) {
      throw UsageException(
        'API usage error:',
        'When using pan-tilt, both pan-tilt-x or pan-tilt-y must be specified.',
      );
    }

    Vector2D? panTilt;

    Vector1D? zoom;

    if (argResults?['pan-tilt-x'] != null &&
        argResults?['pan-tilt-y'] != null) {
      panTilt = Vector2D.fromString(
        x: argResults!['pan-tilt-x'],
        y: argResults!['pan-tilt-y'],
      );
    }

    if (argResults?['pan-tilt-zoom'] != null) {
      zoom = Vector1D.fromString(x: argResults!['pan-tilt-zoom']);
    }

    await initializeOnvif();

    try {
      final place = PtzVector(panTilt: panTilt, zoom: zoom);

      await ptz.absoluteMove(argResults!['profile-token'], position: place);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation for continuous Pan/Tilt and Zoom movements. The operation is
/// supported if the PTZNode supports at least one continuous Pan/Tilt or Zoom
/// space. If the space argument is omitted, the default space set by the
/// PTZConfiguration will be used.
class OnvifContinuousMovePtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation for continuous Pan/Tilt and Zoom movements.';

  @override
  String get name => 'continuous-move';

  OnvifContinuousMovePtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'pan-tilt-x',
        mandatory: true,
        valueHelp: 'double',
        help:
            'A Position vector specifying the absolute target position x-axis.',
      )
      ..addOption(
        'pan-tilt-y',
        mandatory: true,
        valueHelp: 'double',
        help:
            'A Position vector specifying the absolute target position y-axis.',
      )
      ..addOption(
        'pan-tilt-zoom',
        mandatory: true,
        valueHelp: 'double',
        help: 'A Position vector specifying the absolute target position zoom.',
      )
      ..addOption(
        'timeout',
        mandatory: false,
        valueHelp: 'int',
        help:
            'The timeout parameter specifies how long the PTZ node continues to move.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      int? timeout = argResults?['timeout'] != null
          ? int.parse(argResults?['timeout'])
          : null;

      final velocity = PtzSpeed(
        panTilt: Vector2D.fromString(
          x: argResults!['pan-tilt-x'],
          y: argResults!['pan-tilt-y'],
        ),
        zoom: Vector1D.fromString(x: argResults!['pan-tilt-zoom']),
      );

      await ptz.continuousMove(
        argResults!['profile-token'],
        velocity: velocity,
        timeout: timeout,
      );
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation to get all available PTZConfigurations that can be added to the
/// referenced media profile.
///
/// A device providing more than one PTZConfiguration or more than one
/// VideoSourceConfiguration or which has any other resource interdependency
/// between PTZConfiguration entities and other resources listable in a media
/// profile should implement this operation. PTZConfiguration entities returned
/// by this operation shall not fail on adding them to the referenced media
/// profile.
class OnvifGetCompatibleConfigurationsPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Contains the token of an existing media profile the configurations shall be compatible with.';

  @override
  String get name => 'get-compatible-configurations';

  OnvifGetCompatibleConfigurationsPtzCommand() {
    argParser.addOption(
      'profile-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help:
          'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final ptzConfigurations = await ptz.getCompatibleConfigurations(
        argResults!['profile-token'],
      );

      print(ptzConfigurations);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Get a specific PTZconfiguration from the device, identified by its reference
/// token or name.
///
/// The default Position/Translation/Velocity Spaces are introduced to allow
/// NVCs sending move requests without the need to specify a certain coordinate
/// system. The default Speeds are introduced to control the speed of move
/// requests (absolute, relative, preset), where no explicit speed has been set.
///
/// The allowed pan and tilt range for Pan/Tilt Limits is defined by a
/// two-dimensional space range that is mapped to a specific Absolute Pan/Tilt
/// Position Space. At least one Pan/Tilt Position Space is required by the
/// PTZNode to support Pan/Tilt limits. The limits apply to all supported
/// absolute, relative and continuous Pan/Tilt movements. The limits shall be
/// checked within the coordinate system for which the limits have been
/// specified. That means that even if movements are specified in a different
/// coordinate system, the requested movements shall be transformed to the
/// coordinate system of the limits where the limits can be checked. When a
/// relative or continuous movements is specified, which would leave the
/// specified limits, the PTZ unit has to move along the specified limits. The
/// Zoom Limits have to be interpreted accordingly.
class OnvifGetConfigurationPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Get a specific PTZconfiguration from the device, identified by its reference token or name.';

  @override
  String get name => 'get-configuration';

  OnvifGetConfigurationPtzCommand() {
    argParser.addOption(
      'ptz-configuration-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help: 'Token of the requested PTZConfiguration.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final ptzConfiguration = await ptz.getConfiguration(
        argResults!['ptz-configuration-token'],
      );

      print(ptzConfiguration);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// List supported coordinate systems including their range limitations.
/// Therefore, the options MAY differ depending on whether the PTZ Configuration
/// is assigned to a Profile containing a Video Source Configuration. In that
/// case, the options may additionally contain coordinate systems referring to
/// the image coordinate system described by the Video Source Configuration. If
/// the PTZ Node supports continuous movements, it shall return a Timeout Range
/// within which Timeouts are accepted by the PTZ Node.
class OnvifGetConfigurationOptionsPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'List supported coordinate systems including their range limitations.';

  @override
  String get name => 'get-configuration-options';

  OnvifGetConfigurationOptionsPtzCommand() {
    argParser.addOption(
      'configuration-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help:
          'Token of an existing configuration that the options are intended for.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final ptzConfigurationOptions = await ptz.getConfigurationOptions(
        argResults!['configuration-token'],
      );

      print(ptzConfigurationOptions);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Get all the existing PTZConfigurations from the device.
///
/// The default Position/Translation/Velocity Spaces are introduced to allow
/// NVCs sending move requests without the need to specify a certain coordinate
/// system. The default Speeds are introduced to control the speed of move
/// requests (absolute, relative, preset), where no explicit speed has been set.
///
/// The allowed pan and tilt range for Pan/Tilt Limits is defined by a
/// two-dimensional space range that is mapped to a specific Absolute Pan/Tilt
/// Position Space. At least one Pan/Tilt Position Space is required by the
/// PTZNode to support Pan/Tilt limits. The limits apply to all supported
/// absolute, relative and continuous Pan/Tilt movements. The limits shall be
/// checked within the coordinate system for which the limits have been
/// specified. That means that even if movements are specified in a different
/// coordinate system, the requested movements shall be transformed to the
/// coordinate system of the limits where the limits can be checked. When a
/// relative or continuous movements is specified, which would leave the
/// specified limits, the PTZ unit has to move along the specified limits. The
/// Zoom Limits have to be interpreted accordingly.
class OnvifGetConfigurationsPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Get all the existing PTZConfigurations from the device.';

  @override
  String get name => 'get-configurations';

  @override
  void run() async {
    await initializeOnvif();

    try {
      final ptzConfigurations = await ptz.getConfigurations();

      print(ptzConfigurations);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation to request a specific PTZ preset tour in the selected media profile.
class OnvifGetPresetTourPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation to request a specific PTZ preset tour in the selected media profile.';

  @override
  String get name => 'get-preset-tour';

  OnvifGetPresetTourPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'A reference to the MediaProfile where the operation should take place.',
      )
      ..addOption(
        'preset-tour-token',
        valueHelp: 'token',
        mandatory: true,
        help: 'A requested preset tour token.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final presetTour = await ptz.getPresetTour(
        argResults!['profile-token'],
        presetTourToken: argResults!['preset-tour-token'],
      );

      print(presetTour);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation to request PTZ preset tours in the selected media profiles.
class OnvifGetPresetToursPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation to request PTZ preset tours in the selected media profiles.';

  @override
  String get name => 'get-preset-tours';

  OnvifGetPresetToursPtzCommand() {
    argParser.addOption(
      'profile-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help:
          'A reference to the MediaProfile where the operation should take place.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final presetTours = await ptz.getPresetTours(
        argResults!['profile-token'],
      );

      print(presetTours);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation to request all PTZ presets for the PTZNode in the selected
/// profile. The operation is supported if there is support for at least on PTZ
/// preset by the PTZNode.
class OnvifGetPresetsPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation to request all PTZ presets for the PTZNode in the selected profile.';

  @override
  String get name => 'get-presets';

  OnvifGetPresetsPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'A reference to the MediaProfile where the operation should take place.',
      )
      ..addOption(
        'limit',
        defaultsTo: '10',
        valueHelp: 'int',
        help: 'Limit the number of presets returned',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final presets = await ptz.getPresets(
        argResults!['profile-token'],
        limit: int.tryParse(argResults?['limit']),
      );

      print(presets);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Returns the capabilities of the PTZ service. The result is returned in a
/// typed answer.
class OnvifGetServiceCapabilitiesPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Returns the capabilities of the PTZ service. The result is returned in a typed answer.';

  @override
  String get name => 'get-service-capabilities';

  @override
  void run() async {
    await initializeOnvif();

    try {
      final capabilities = await ptz.getServiceCapabilities();

      print(capabilities);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation to request PTZ status for the Node in the selected profile.
class OnvifGetStatusPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation to request PTZ status for the Node in the selected profile.';

  @override
  String get name => 'get-status';

  OnvifGetStatusPtzCommand() {
    argParser.addOption(
      'profile-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help:
          'A reference to the MediaProfile where the PTZStatus should be requested.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final ptzStatus = await ptz.getStatus(argResults!['profile-token']);

      print(ptzStatus);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation to move the PTZ device to it's "home" position. The operation is
/// supported if the HomeSupported element in the PTZNode is true.
class OnvifGotoHomePositionPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation to move the PTZ device to it\'s "home" position. The operation is supported if the HomeSupported element in the PTZNode is true.';

  @override
  String get name => 'goto-home-position';

  OnvifGotoHomePositionPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'profile-token',
        mandatory: true,
        help:
            'A reference to the MediaProfile where the operation should take place.',
      )
      ..addOption(
        'pan-tilt-x',
        valueHelp: 'double',
        help:
            'Pan and tilt speed. The x component corresponds to pan. If omitted in a request, the current (if any) Vector2D movement should not be affected.',
      )
      ..addOption(
        'pan-tilt-y',
        valueHelp: 'double',
        help:
            'Pan and tilt speed. The y component corresponds to tilt. If omitted in a request, the current (if any) Vector2D movement should not be affected.',
      )
      ..addOption(
        'zoom',
        valueHelp: 'double',
        help:
            'A zoom speed. If omitted in a request, the current (if any) Zoom movement should not be affected.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final profileToken = argResults!['profile-token'];

      await ptz.gotoHomePosition(
        profileToken,
        speed:
            argResults?['pan-tilt-x'] != null &&
                argResults?['pan-tilt-y'] != null
            ? PtzSpeed(
                panTilt: Vector2D.fromString(
                  x: argResults!['pan-tilt-x'],
                  y: argResults!['pan-tilt-y'],
                ),
                zoom: argResults?['zoom'] != null
                    ? Vector1D.fromString(x: argResults!['zoom'])
                    : null,
              )
            : null,
      );
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation to go to a saved preset position for the PTZNode in the selected
/// profile. The operation is supported if there is support for at least on PTZ
/// preset by the PTZNode.
class OnvifGotoPresetPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation to go to a saved preset position for the PTZNode in the selected profile.';

  @override
  String get name => 'goto-preset';

  OnvifGotoPresetPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'profile-token',
        mandatory: true,
        help:
            'A reference to the MediaProfile where the operation should take place.',
      )
      ..addOption(
        'preset-token',
        valueHelp: 'preset-token',
        mandatory: true,
        help: 'A requested preset token.',
      )
      ..addOption(
        'pan-tilt-x',
        valueHelp: 'double',
        help:
            'Pan and tilt speed. The x component corresponds to pan. If omitted in a request, the current (if any) Vector2D movement should not be affected.',
      )
      ..addOption(
        'pan-tilt-y',
        valueHelp: 'double',
        help:
            'Pan and tilt speed. The y component corresponds to tilt. If omitted in a request, the current (if any) Vector2D movement should not be affected.',
      )
      ..addOption(
        'zoom',
        valueHelp: 'double',
        help:
            'A zoom speed. If omitted in a request, the current (if any) Zoom movement should not be affected.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final profileToken = argResults!['profile-token'];

      await ptz.gotoPreset(
        profileToken,
        presetToken: argResults!['preset-token'],
        speed:
            argResults?['pan-tilt-x'] != null &&
                argResults?['pan-tilt-y'] != null
            ? PtzSpeed(
                panTilt: Vector2D.fromString(
                  x: argResults!['pan-tilt-x'],
                  y: argResults!['pan-tilt-y'],
                ),
                zoom: argResults?['zoom'] != null
                    ? Vector1D.fromString(x: argResults!['zoom'])
                    : null,
              )
            : null,
      );
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation for Relative Pan/Tilt and Zoom Move. The operation is supported if
/// the PTZNode supports at least one relative Pan/Tilt or Zoom space.
///
/// The speed argument is optional. If an x/y speed value is given it is up to
/// the device to either use the x value as absolute resulting speed vector or
/// to map x and y to the component speed. If the speed argument is omitted, the
/// default speed set by the PTZConfiguration will be used.
class OnvifRelativeMovePtzCommand extends OnvifHelperCommand {
  @override
  String get description => 'Operation for Relative Pan/Tilt and Zoom Move.';

  @override
  String get name => 'relative-move';

  OnvifRelativeMovePtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'translation-x',
        valueHelp: 'double',
        mandatory: true,
        help:
            'Pan and tilt speed. The x component corresponds to pan. If omitted in a request, the current (if any) Vector2D movement should not be affected.',
      )
      ..addOption(
        'translation-y',
        valueHelp: 'double',
        mandatory: true,
        help:
            'Pan and tilt speed. The y component corresponds to tilt. If omitted in a request, the current (if any) Vector2D movement should not be affected.',
      )
      ..addOption(
        'translation-zoom',
        valueHelp: 'double',
        mandatory: true,
        help:
            'A zoom speed. If omitted in a request, the current (if any) Zoom movement should not be affected.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      var translation = PtzVector(
        panTilt: Vector2D.fromString(
          x: argResults!['translation-x'],
          y: argResults!['translation-y'],
        ),
        zoom: Vector1D.fromString(x: argResults!['translation-zoom']),
      );

      await ptz.relativeMove(
        argResults!['profile-token'],
        translation,
        PtzSpeed(),
      );
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

///Operation to remove a PTZ preset for the Node in the selected profile. The
///operation is supported if the PresetPosition capability exists for teh Node
///in the selected profile.
class OnvifRemovePresetPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation to remove a PTZ preset for the Node in the selected profile.';

  @override
  String get name => 'remove-preset';

  OnvifRemovePresetPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'profile-token',
        mandatory: true,
        help:
            'A reference to the MediaProfile where the operation should take place.',
      )
      ..addOption(
        'preset-token',
        valueHelp: 'preset-token',
        mandatory: true,
        help: 'A requested preset token.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await ptz.removePreset(
        argResults!['profile-token'],
        preset: Preset.fromToken(argResults!['preset-token']),
      );
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation to save current position as the home position. The SetHomePosition
/// command returns with a failure if the “home” position is fixed and cannot be
/// overwritten. If the SetHomePosition is successful, it is possible to recall
/// the Home Position with the GotoHomePosition command.
class OnvifSetHomePositionPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation to save current position as the home position. The SetHomePosition command returns with a failure if the “home” position is fixed and cannot be overwritten. If the SetHomePosition is successful, it is possible to recall the Home Position with the GotoHomePosition command.';

  @override
  String get name => 'set-home-position';

  OnvifSetHomePositionPtzCommand() {
    argParser.addOption(
      'profile-token',
      abbr: 't',
      valueHelp: 'profile-token',
      mandatory: true,
      help:
          'A reference to the MediaProfile where the operation should be set.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await ptz.setHomePosition(argResults!['profile-token']);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// The SetPreset command saves the current device position parameters so that
/// the device can move to the saved preset position through the GotoPreset
/// operation. In order to create a new preset, the SetPresetRequest contains no
/// PresetToken. If creation is successful, the Response contains the
/// PresetToken which uniquely identifies the Preset. An existing Preset can be
/// overwritten by specifying the PresetToken of the corresponding Preset. In
/// both cases overwriting or creation) an optional PresetName can be specified.
/// The operation fails if the PTZ device is moving during the SetPreset
/// operation. The device MAY internally save additional states such as imaging
/// properties in the PTZ Preset which then should be recalled in the GotoPreset
/// operation.
class OnvifSetPresetPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'The SetPreset command saves the current device position parameters so that the device can move to the saved preset position through the GotoPreset operation.';

  @override
  String get name => 'set-preset';

  OnvifSetPresetPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'profile-token',
        mandatory: true,
        help:
            'A reference to the MediaProfile where the operation should take place.',
      )
      ..addOption(
        'preset-token',
        valueHelp: 'preset-token',
        help: 'A requested preset token.',
      )
      ..addOption(
        'preset-name',
        valueHelp: 'name',
        help: 'The name of the new preset.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    final profileToken = argResults!['profile-token'];

    try {
      final token = await ptz.setPreset(
        profileToken,
        presetName: argResults?['preset-name'],
        presetToken: argResults?['preset-token'],
      );

      print(token);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation to stop ongoing pan, tilt and zoom movements of absolute relative
/// and continuous type. If no stop argument for pan, tilt or zoom is set, the
/// device will stop all ongoing pan, tilt and zoom movements.
class OnvifStopPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation to stop ongoing pan, tilt and zoom movements of absolute relative and continuous type.';

  @override
  String get name => 'stop';

  OnvifStopPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addFlag(
        'pan-tilt',
        defaultsTo: true,
        help:
            'Set true when we want to stop ongoing pan and tilt movements.If Vector2D arguments are not present, this command stops these movements.',
      )
      ..addFlag(
        'zoom',
        defaultsTo: true,
        help:
            'Set true when we want to stop ongoing zoom movement.If Zoom arguments are not present, this command stops ongoing zoom movement.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await ptz.stop(
        argResults!['profile-token'],
        panTilt: argResults!['pan-tilt'],
        zoom: argResults!['zoom'],
      );
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation for Relative Pan/Tilt Move without Zoom.
class OnvifMovePtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation for Relative Pan/Tilt Move without Zoom.';

  @override
  String get name => 'move';

  OnvifMovePtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'x',
        mandatory: true,
        valueHelp: 'double',
        help: 'The x component corresponds to pan.',
      )
      ..addOption(
        'y',
        mandatory: true,
        valueHelp: 'double',
        help: 'The y component corresponds to tilt.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await ptz.move(
        argResults!['profile-token'],
        direction: Vector2D.fromString(
          x: argResults!['x'],
          y: argResults!['y'],
        ),
      );
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation for a single step tilt down operation.
class OnvifMoveDownPtzCommand extends OnvifHelperCommand {
  @override
  String get description => 'Operation for a single step tilt down operation.';

  @override
  String get name => 'move-down';

  OnvifMoveDownPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'step',
        defaultsTo: '0.005',
        valueHelp: 'double',
        help: 'The amount of movement for the step.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    final step = argResults?['step'] != null
        ? double.parse(argResults!['step'])
        : 0.005;

    try {
      await ptz.moveDown(argResults!['profile-token'], step * -1.0);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation for a single step pan left operation.
class OnvifMoveLeftPtzCommand extends OnvifHelperCommand {
  @override
  String get description => 'Operation for a single step pan left operation.';

  @override
  String get name => 'move-left';

  OnvifMoveLeftPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'step',
        defaultsTo: '0.005',
        valueHelp: 'double',
        help: 'The amount of movement for the step.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    final step = argResults?['step'] != null
        ? double.parse(argResults!['step'])
        : 0.005;

    try {
      await ptz.moveLeft(argResults!['profile-token'], step * -1.0);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation for a single step pan right operation.
class OnvifMoveRightPtzCommand extends OnvifHelperCommand {
  @override
  String get description => 'Operation for a single step pan right operation';

  @override
  String get name => 'move-right';

  OnvifMoveRightPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'step',
        defaultsTo: '0.005',
        valueHelp: 'double',
        help: 'The amount of movement for the step.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    final step = argResults?['step'] != null
        ? double.parse(argResults!['step'])
        : 0.005;

    try {
      await ptz.moveRight(argResults!['profile-token'], step);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation for a single step tilt upwards operation.
class OnvifMoveUpPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Operation for a single step tilt upwards operation.';

  @override
  String get name => 'move-up';

  OnvifMoveUpPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'step',
        defaultsTo: '0.005',
        valueHelp: 'double',
        help: 'The amount of movement for the step.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    final step = argResults?['step'] != null
        ? double.parse(argResults!['step'])
        : 0.005;

    try {
      await ptz.moveUp(argResults!['profile-token'], step);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation for zoom.
class OnvifZoomPtzCommand extends OnvifHelperCommand {
  @override
  String get description => 'Operation for zoom.';

  @override
  String get name => 'zoom';

  OnvifZoomPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'zoom',
        mandatory: true,
        valueHelp: 'double',
        help: 'The speed for the zoom operation',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await ptz.zoom(
        argResults!['profile-token'],
        Vector1D.fromString(x: argResults!['zoom']),
      );
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation for a single step zoom in operation.
class OnvifZoomInPtzCommand extends OnvifHelperCommand {
  @override
  String get description => 'Operation for a single step zoom in operation.';

  @override
  String get name => 'zoom-in';

  OnvifZoomInPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'step',
        defaultsTo: '0.025',
        valueHelp: 'double',
        help: 'The amount of movement for the step.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    final step = argResults?['step'] != null
        ? double.parse(argResults!['step'])
        : 0.025;

    try {
      await ptz.zoomIn(argResults!['profile-token'], step);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Operation for a single step zoom out operation.
class OnvifZoomOutPtzCommand extends OnvifHelperCommand {
  @override
  String get description => 'Operation for a single step zoom out operation.';

  @override
  String get name => 'zoom-out';

  OnvifZoomOutPtzCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'step',
        defaultsTo: '0.025',
        valueHelp: 'double',
        help: 'The amount of movement for the step.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    final step = argResults?['step'] != null
        ? double.parse(argResults!['step'])
        : 0.005;

    try {
      await ptz.zoomOut(argResults!['profile-token'], step);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

class OnvifGetCurrentPresetPtzCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Helper function to get the matching preset for the current PtzVector and Zoom if there is a match';

  @override
  String get name => 'get-current-preset';

  OnvifGetCurrentPresetPtzCommand() {
    argParser.addOption(
      'profile-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help:
          'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    final preset = await ptz.getCurrentPreset(argResults!['profile-token']);

    print(preset);
  }
}
