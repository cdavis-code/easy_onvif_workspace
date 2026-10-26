import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../hardware/hardware_adapter.dart';
import '../settings.dart';
import '../settings_store.dart';

/// Full-schema settings editor pushed from the main screen's gear icon.
///
/// Edits a draft of the passed-in [ServerSettings]; Save validates, persists
/// through the [SettingsStore], and pops with the saved settings (null on
/// cancel). Device pickers are populated by capability discovery where the
/// platform supports it and fall back to free-text fields elsewhere.
class SettingsScreen extends StatefulWidget {
  final ServerSettings settings;
  final SettingsStore store;

  const SettingsScreen({
    required this.settings,
    required this.store,
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// One selectable capture device: the raw platform identifier persisted in
/// settings plus a human-readable label for the dropdown.
class _DeviceOption {
  final String id;
  final String label;

  const _DeviceOption(this.id, this.label);
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _permissionsChannel = MethodChannel(
    'easy_onvif_server/permissions',
  );
  static const _audioChannel = MethodChannel('easy_onvif_server/audio_capture');
  static const _screenChannel = MethodChannel(
    'easy_onvif_server/screen_capture',
  );

  final _formKey = GlobalKey<FormState>();

  // Device
  late final TextEditingController _manufacturer;
  late final TextEditingController _model;
  late final TextEditingController _firmware;
  late final TextEditingController _serial;
  late final TextEditingController _hardwareId;
  late final TextEditingController _hostname;

  // Network
  late final TextEditingController _httpPort;
  late final TextEditingController _rtspPort;

  // Auth
  late final TextEditingController _username;
  late final TextEditingController _password;
  bool _showPassword = false;

  // Media
  late VideoSourceKind _videoSource;
  late String _videoDevice;
  late bool _audioEnabled;
  late String _audioDevice;

  // Services
  late bool _recordingService;
  late bool _replayService;
  late bool _searchService;
  late bool _imagingService;

  // Recording
  late final TextEditingController _recordingDirectory;
  late final TextEditingController _segmentSeconds;
  late final TextEditingController _maxRetentionMinutes;

  // Imaging presets (draft rows; controllers owned per row).
  late final List<_PresetDraft> _presets;

  // Location
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _elevation;

  /// Discovered devices; null while discovery runs or when unavailable (the
  /// UI then shows a free-text field instead of a dropdown).
  List<_DeviceOption>? _cameras;
  List<_DeviceOption>? _displays;
  List<_DeviceOption>? _audioInputs;

  /// True when the user enabled audio but macOS reported the microphone
  /// grant as denied; shows an inline warning under the toggle.
  bool _micDenied = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final settings = widget.settings;
    final config = settings.config;

    _manufacturer = TextEditingController(text: config.manufacturer);
    _model = TextEditingController(text: config.model);
    _firmware = TextEditingController(text: config.firmwareVersion);
    _serial = TextEditingController(text: config.serialNumber);
    _hardwareId = TextEditingController(text: config.hardwareId);
    _hostname = TextEditingController(text: config.hostname);
    _httpPort = TextEditingController(text: '${config.httpPort}');
    _rtspPort = TextEditingController(text: '${config.rtspPort}');
    _username = TextEditingController(text: config.username);
    _password = TextEditingController(text: config.password);

    _videoSource = settings.media.videoSource;
    _videoDevice = settings.media.videoDevice;
    _audioEnabled = settings.media.audioEnabled;
    _audioDevice = settings.media.audioDevice;

    _recordingService = settings.services.recording;
    _replayService = settings.services.replay;
    _searchService = settings.services.search;
    _imagingService = settings.services.imaging;

    _recordingDirectory = TextEditingController(
      text: settings.recordingDirectory ?? '',
    );
    _segmentSeconds = TextEditingController(text: '${settings.segmentSeconds}');
    _maxRetentionMinutes = TextEditingController(
      text: settings.maxRetentionMinutes?.toString() ?? '',
    );

    _presets = [
      for (final preset in settings.imagingPresets) _PresetDraft.from(preset),
    ];

    final geo = settings.geoFallback;
    _latitude = TextEditingController(text: geo?.latitude.toString() ?? '');
    _longitude = TextEditingController(text: geo?.longitude.toString() ?? '');
    _elevation = TextEditingController(text: geo?.elevation?.toString() ?? '');

    _discoverDevices();
  }

  @override
  void dispose() {
    for (final controller in [
      _manufacturer,
      _model,
      _firmware,
      _serial,
      _hardwareId,
      _hostname,
      _httpPort,
      _rtspPort,
      _username,
      _password,
      _recordingDirectory,
      _segmentSeconds,
      _maxRetentionMinutes,
      _latitude,
      _longitude,
      _elevation,
    ]) {
      controller.dispose();
    }

    for (final preset in _presets) {
      preset.dispose();
    }

    super.dispose();
  }

  /// Populates the device pickers. Each probe fails independently and leaves
  /// its list null, which renders as a free-text fallback — discovery never
  /// blocks the screen.
  Future<void> _discoverDevices() async {
    try {
      final cameras = await availableCameras();

      if (mounted) {
        setState(() {
          _cameras = [
            for (final camera in cameras)
              _DeviceOption(camera.name, camera.name),
          ];
        });
      }
    } catch (_) {
      // No camera plugin on this platform (or discovery failed).
    }

    if (!Platform.isMacOS) return;

    try {
      final devices = await _audioChannel.invokeListMethod<Object?>(
        'listDevices',
      );

      if (devices != null && mounted) {
        setState(() {
          _audioInputs = [
            for (final device in devices.whereType<Map<Object?, Object?>>())
              _DeviceOption(
                '${device['uid']}',
                '${device['name'] ?? device['uid']}',
              ),
          ];
        });
      }
    } catch (_) {
      // Channel unavailable; keep the text-field fallback.
    }

    try {
      final displays = await _screenChannel.invokeListMethod<Object?>(
        'listDisplays',
      );

      if (displays != null && mounted) {
        setState(() {
          _displays = [
            for (final display in displays.whereType<Map<Object?, Object?>>())
              _DeviceOption(
                '${display['id']}',
                '${display['name'] ?? display['id']}',
              ),
          ];
        });
      }
    } catch (_) {
      // Channel unavailable; keep the text-field fallback.
    }
  }

  /// Fires the macOS microphone prompt from the toggle's user gesture — a
  /// deterministic request point that is easier to diagnose than the one at
  /// server start (which remains as a backstop).
  Future<void> _onAudioToggled(bool enabled) async {
    setState(() {
      _audioEnabled = enabled;
      _micDenied = false;
    });

    if (!enabled || !Platform.isMacOS) return;

    try {
      final granted = await _permissionsChannel.invokeMethod<bool>(
        'requestMicrophone',
      );

      if (granted == false && mounted) setState(() => _micDenied = true);
    } catch (_) {
      // Channel unavailable (tests, other platforms): nothing to report.
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final geoLat = _latitude.text.trim();
    final geoLon = _longitude.text.trim();
    final geoElev = _elevation.text.trim();
    final retention = _maxRetentionMinutes.text.trim();
    final directory = _recordingDirectory.text.trim();

    final presets = [
      for (final preset in _presets)
        if (preset.token.text.trim().isNotEmpty)
          ImagingPresetSetting(
            token: preset.token.text.trim(),
            name: preset.name.text.trim(),
            type: preset.type.text.trim(),
          ),
    ];

    final updated = widget.settings.copyWith(
      config: widget.settings.config.copyWith(
        manufacturer: _manufacturer.text.trim(),
        model: _model.text.trim(),
        firmwareVersion: _firmware.text.trim(),
        serialNumber: _serial.text.trim(),
        hardwareId: _hardwareId.text.trim(),
        hostname: _hostname.text.trim(),
        httpPort: int.parse(_httpPort.text.trim()),
        rtspPort: int.parse(_rtspPort.text.trim()),
        username: _username.text.trim(),
        password: _password.text,
      ),
      services: ServiceFlags(
        recording: _recordingService,
        replay: _replayService,
        search: _searchService,
        imaging: _imagingService,
      ),
      recordingDirectory: directory.isEmpty ? null : directory,
      segmentSeconds: int.parse(_segmentSeconds.text.trim()),
      maxRetentionMinutes: retention.isEmpty ? null : int.parse(retention),
      imagingPresets: presets.isEmpty
          ? ServerSettings.defaultImagingPresets
          : presets,
      geoFallback: geoLat.isEmpty || geoLon.isEmpty
          ? null
          : GeoLocation(
              latitude: double.parse(geoLat),
              longitude: double.parse(geoLon),
              elevation: geoElev.isEmpty ? null : double.parse(geoElev),
            ),
      media: MediaSettings(
        videoSource: _videoSource,
        videoDevice: _videoDevice,
        audioEnabled: _audioEnabled,
        audioDevice: _audioDevice,
      ),
    );

    try {
      await widget.store.save(updated);

      if (mounted) Navigator.of(context).pop(updated);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        // A non-lazy scroll view: Form.validate() only visits built fields,
        // so lazily-built list items would let off-screen bad input through.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader('Device'),
              _textField(_manufacturer, 'Manufacturer'),
              _textField(_model, 'Model'),
              _textField(_firmware, 'Firmware version'),
              _textField(_serial, 'Serial number'),
              _textField(_hardwareId, 'Hardware ID'),
              _textField(_hostname, 'Hostname'),
              _sectionHeader('Network'),
              _textField(
                _httpPort,
                'HTTP port',
                keyboardType: TextInputType.number,
                validator: _portValidator,
              ),
              _textField(
                _rtspPort,
                'RTSP port',
                keyboardType: TextInputType.number,
                validator: _portValidator,
              ),
              _sectionHeader('Auth'),
              _textField(_username, 'Username', validator: _requiredValidator),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _password,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: _requiredValidator,
                ),
              ),
              _sectionHeader('Media'),
              _buildMediaSection(),
              _sectionHeader('Services'),
              SwitchListTile(
                title: const Text('Recording'),
                value: _recordingService,
                onChanged: (value) => setState(() => _recordingService = value),
              ),
              SwitchListTile(
                title: const Text('Replay'),
                value: _replayService,
                onChanged: (value) => setState(() => _replayService = value),
              ),
              SwitchListTile(
                title: const Text('Search'),
                value: _searchService,
                onChanged: (value) => setState(() => _searchService = value),
              ),
              SwitchListTile(
                title: const Text('Imaging'),
                value: _imagingService,
                onChanged: (value) => setState(() => _imagingService = value),
              ),
              _sectionHeader('Recording'),
              _textField(
                _recordingDirectory,
                'Directory (blank = system temp)',
              ),
              _textField(
                _segmentSeconds,
                'Segment length (seconds)',
                keyboardType: TextInputType.number,
                validator: (value) => _positiveIntValidator(value, 'segment'),
              ),
              _textField(
                _maxRetentionMinutes,
                'Retention (minutes, blank = keep forever)',
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.trim().isEmpty
                    ? null
                    : _positiveIntValidator(value, 'retention'),
              ),
              _sectionHeader('Imaging presets'),
              ..._buildPresetRows(),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => _presets.add(_PresetDraft.blank(_presets.length + 1)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add preset'),
                ),
              ),
              _sectionHeader('Location fallback'),
              _textField(
                _latitude,
                'Latitude (blank = none)',
                keyboardType: TextInputType.number,
                validator: _geoValidator,
              ),
              _textField(
                _longitude,
                'Longitude (blank = none)',
                keyboardType: TextInputType.number,
                validator: _geoValidator,
              ),
              _textField(
                _elevation,
                'Elevation (optional)',
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.trim().isEmpty
                    ? null
                    : (double.tryParse(value.trim()) == null
                          ? 'Not a number'
                          : null),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SegmentedButton<VideoSourceKind>(
            segments: const [
              ButtonSegment(
                value: VideoSourceKind.camera,
                label: Text('Camera'),
                icon: Icon(Icons.videocam),
              ),
              ButtonSegment(
                value: VideoSourceKind.display,
                label: Text('Display'),
                icon: Icon(Icons.desktop_windows),
              ),
              ButtonSegment(
                value: VideoSourceKind.test,
                label: Text('Test'),
                icon: Icon(Icons.grid_on),
              ),
            ],
            selected: {_videoSource},
            onSelectionChanged: (selection) => setState(() {
              _videoSource = selection.first;
              // Device identifiers are not interchangeable across source
              // kinds (camera name vs display id); reset on switch.
              _videoDevice = '';
            }),
          ),
        ),
        if (_videoSource == VideoSourceKind.camera)
          _devicePicker(
            label: 'Camera',
            options: _cameras,
            value: _videoDevice,
            onChanged: (value) => setState(() => _videoDevice = value),
          ),
        if (_videoSource == VideoSourceKind.display)
          _devicePicker(
            label: 'Display',
            options: _displays,
            value: _videoDevice,
            onChanged: (value) => setState(() => _videoDevice = value),
          ),
        SwitchListTile(
          title: const Text('Audio streaming'),
          subtitle: _micDenied
              ? const Text(
                  'Microphone access denied. Enable it in System Settings → '
                  'Privacy & Security → Microphone.',
                  style: TextStyle(color: Colors.orangeAccent),
                )
              : null,
          value: _audioEnabled,
          onChanged: _onAudioToggled,
        ),
        if (_audioEnabled)
          _devicePicker(
            label: 'Audio input',
            options: _audioInputs,
            value: _audioDevice,
            onChanged: (value) => setState(() => _audioDevice = value),
          ),
      ],
    );
  }

  /// A dropdown when discovery produced options (with "System default" first
  /// and the persisted value kept selectable even if no longer discovered);
  /// a free-text field otherwise.
  Widget _devicePicker({
    required String label,
    required List<_DeviceOption>? options,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    if (options == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            labelText: '$label (blank = default)',
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      );
    }

    final entries = [
      const _DeviceOption('', 'System default'),
      ...options,
      if (value.isNotEmpty && options.every((option) => option.id != value))
        _DeviceOption(value, '$value (not detected)'),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final entry in entries)
            DropdownMenuItem(value: entry.id, child: Text(entry.label)),
        ],
        onChanged: (selected) => onChanged(selected ?? ''),
      ),
    );
  }

  List<Widget> _buildPresetRows() {
    return [
      for (var i = 0; i < _presets.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _presets[i].token,
                  decoration: const InputDecoration(
                    labelText: 'Token',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _presets[i].name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _presets[i].type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _presets.removeAt(i).dispose()),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _portValidator(String? value) {
    final port = int.tryParse(value?.trim() ?? '');

    if (port == null || port < 1 || port > 65535) return 'Port must be 1–65535';

    return null;
  }

  String? _positiveIntValidator(String? value, String _) {
    final parsed = int.tryParse(value?.trim() ?? '');

    if (parsed == null || parsed < 1) return 'Must be a positive number';

    return null;
  }

  /// Latitude and longitude must be given together (or both blank).
  String? _geoValidator(String? value) {
    final lat = _latitude.text.trim();
    final lon = _longitude.text.trim();

    if (lat.isEmpty && lon.isEmpty) return null;
    if (lat.isEmpty || lon.isEmpty) return 'Set both latitude and longitude';

    final text = value?.trim() ?? '';

    return double.tryParse(text) == null ? 'Not a number' : null;
  }
}

/// Mutable editing state for one imaging preset row.
class _PresetDraft {
  final TextEditingController token;
  final TextEditingController name;
  final TextEditingController type;

  _PresetDraft.from(ImagingPresetSetting preset)
    : token = TextEditingController(text: preset.token),
      name = TextEditingController(text: preset.name),
      type = TextEditingController(text: preset.type);

  _PresetDraft.blank(int index)
    : token = TextEditingController(text: 'ImagingPreset_$index'),
      name = TextEditingController(text: 'Preset $index'),
      type = TextEditingController(text: 'Auto');

  void dispose() {
    token.dispose();
    name.dispose();
    type.dispose();
  }
}
