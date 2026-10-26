// TypeScript declarations for easy-onvif-node.
//
// The runtime API is produced by dart2js via @JSExport on Dart classes.
// Methods are grouped under service objects mirroring the easy_onvif Dart
// package structure: deviceManagement, media, ptz, imaging, search,
// recordings, replay.

// ── Common types ────────────────────────────────────────────────────────────

export interface ConnectOptions {
  host: string;
  username: string;
  password: string;
}

export interface EndpointReference {
  address: string;
}

export interface ProbeMatch {
  types: string[];
  scopes: string[];
  xAddrs: string[];
  metadataVersion: number;
  endpointReference: EndpointReference;
}

export interface DeviceInformation {
  manufacturer: string;
  model: string;
  firmwareVersion: string;
  serialNumber: string;
  hardwareId: string;
}

export interface Profile {
  token: string;
  name: string;
  fixed: boolean;
}

export interface SystemDateAndTime {
  dateTimeType: string;
  daylightSavings: boolean;
  timeZone: string;
  utcDateTime: string;
  localDateTime: string;
}

export interface User {
  username: string;
  userLevel: string;
}

export interface PtzStatus {
  position: {
    panTilt?: { x: number; y: number };
    zoom?: { x: number };
  };
  moveStatus?: Record<string, string>;
  error: string;
  utcTime: string;
}

export interface Preset {
  token: string;
  name: string;
  position?: {
    panTilt?: { x: number; y: number };
    zoom?: { x: number };
  };
}

export interface PresetTour {
  token: string;
  name: string;
  status: string;
}

export interface PtzConfiguration {
  token: string;
  name: string;
  nodeToken: string;
  defaultAbsolutePantTiltPositionSpace?: string;
  defaultAbsoluteZoomPositionSpace?: string;
  defaultRelativePanTiltTranslationSpace?: string;
  defaultRelativeZoomTranslationSpace?: string;
  defaultContinuousPanTiltVelocitySpace?: string;
  defaultContinuousZoomVelocitySpace?: string;
  defaultPTZSpeed?: {
    panTilt?: { x: number; y: number };
    zoom?: { x: number };
  };
  defaultPTZTimeout: string;
  panTiltLimits?: Record<string, unknown>;
  zoomLimits?: Record<string, unknown>;
  extension?: Record<string, unknown>;
}

export interface PtzConfigurationOptions {
  spaces: Record<string, unknown>;
  timeoutRange: { min: string; max: string };
  PTZTimeout: { min: string; max: string };
  PTZDirection?: string[];
}

export interface ImagingPreset {
  token: string;
  type: string;
}

export interface ImagingStatus {
  focusStatus?: {
    position: number;
    moveStatus: string;
    error: string;
  };
}

// ── DeviceManagement service ────────────────────────────────────────────────

export interface DeviceManagementService {
  /** Returns manufacturer/model/firmware metadata for the device. */
  getDeviceInformation(): Promise<DeviceInformation>;

  /** Returns the list of available services on the device. */
  getServices(includeCapability?: boolean): Promise<Record<string, unknown>[]>;

  /** Returns the capabilities of the device service. */
  getServiceCapabilities(): Promise<Record<string, unknown>>;

  /** Returns the device capabilities (legacy). */
  getCapabilities(): Promise<Record<string, unknown>>;

  /** Returns the device system date and time. */
  getSystemDateAndTime(): Promise<SystemDateAndTime>;

  /** Returns the hostname configuration. */
  getHostname(): Promise<Record<string, unknown>>;

  /** Returns the DNS settings. */
  getDns(): Promise<Record<string, unknown>>;

  /** Returns the NTP settings. */
  getNtp(): Promise<Record<string, unknown>>;

  /** Returns configured network protocols. */
  getNetworkProtocols(): Promise<Record<string, unknown>[]>;

  /** Returns the current discovery mode. */
  getDiscoveryMode(): Promise<string>;

  /** Returns registered users. */
  getUsers(): Promise<User[]>;

  /** Creates new device users. */
  createUsers(users: Array<{ username: string; password?: string; userLevel: string }>): Promise<boolean>;

  /** Deletes users from the device. */
  deleteUsers(usernames: string[]): Promise<boolean>;

  /** Reboots the device. */
  systemReboot(): Promise<string>;

  /** Returns dynamic DNS settings. */
  getDynamicDns(): Promise<Record<string, unknown>>;

  /** Returns IP address filter settings. */
  getIPAddressFilter(): Promise<Record<string, unknown>>;

  /** Lists all storage configurations. */
  getStorageConfigurations(): Promise<Record<string, unknown>[]>;

  /** Returns a specific storage configuration. */
  getStorageConfiguration(referenceToken: string): Promise<Record<string, unknown>>;

  /** Returns the endpoint reference address. */
  getEndpointReference(): Promise<Record<string, unknown>>;

  /** Returns URIs for system logs, support info, and backup data. */
  getSystemUris(): Promise<Record<string, unknown>>;
}

// ── Media service ───────────────────────────────────────────────────────────

export interface MediaService {
  /** Returns the list of media profiles advertised by the device. */
  getProfiles(): Promise<Profile[]>;

  /** Returns an RTSP stream URI for the given profile. */
  getStreamUri(profileToken: string): Promise<string>;

  /** Returns the HTTP snapshot URI for the given profile. */
  getSnapshotUri(profileToken: string): Promise<string>;

  /** Lists all available physical video inputs. */
  getVideoSources(): Promise<Record<string, unknown>[]>;

  /** Lists all available physical audio inputs. */
  getAudioSources(): Promise<Record<string, unknown>[]>;

  /** Returns the capabilities of the media service. */
  getServiceCapabilities(): Promise<Record<string, unknown>>;

  /** Starts multicast streaming for a profile. */
  startMulticastStreaming(profileToken: string): Promise<boolean>;

  /** Stops multicast streaming for a profile. */
  stopMulticastStreaming(profileToken: string): Promise<boolean>;
}

// ── PTZ service ─────────────────────────────────────────────────────────────

export interface PtzService {
  /** Issues an ONVIF PTZ AbsoluteMove on the given profile. */
  absoluteMove(profileToken: string, x: number, y: number, zoom: number): Promise<boolean>;

  /** Issues a relative Pan/Tilt and Zoom move. */
  relativeMove(
    profileToken: string,
    x: number,
    y: number,
    zoom: number,
    speedX?: number,
    speedY?: number,
    speedZoom?: number,
  ): Promise<boolean>;

  /** Issues a continuous Pan/Tilt and Zoom movement. */
  continuousMove(
    profileToken: string,
    velocityX: number,
    velocityY: number,
    velocityZoom: number,
    timeout?: number,
  ): Promise<boolean>;

  /** Stops ongoing pan, tilt and zoom movements. */
  stop(profileToken: string, panTilt?: boolean, zoom?: boolean): Promise<boolean>;

  /** Returns the current PTZ status for the profile. */
  getStatus(profileToken: string): Promise<PtzStatus>;

  /** Returns all PTZ presets for the profile. */
  getPresets(profileToken: string): Promise<Preset[]>;

  /** Moves the PTZ to a saved preset position. */
  gotoPreset(profileToken: string, presetToken: string): Promise<boolean>;

  /** Saves the current position as a preset. Returns the preset token. */
  setPreset(profileToken: string, presetName?: string, presetToken?: string): Promise<string>;

  /** Removes a PTZ preset. */
  removePreset(profileToken: string, presetToken: string): Promise<boolean>;

  /** Moves the PTZ to its home position. */
  gotoHomePosition(profileToken: string): Promise<boolean>;

  /** Saves the current position as the home position. */
  setHomePosition(profileToken: string): Promise<boolean>;

  /** Returns all PTZ configurations. */
  getConfigurations(): Promise<PtzConfiguration[]>;

  /** Returns a specific PTZ configuration. */
  getConfiguration(configurationToken: string): Promise<PtzConfiguration>;

  /** Returns the configuration options for a token. */
  getConfigurationOptions(configurationToken: string): Promise<PtzConfigurationOptions>;

  /** Returns PTZ configurations compatible with a media profile. */
  getCompatibleConfigurations(profileToken: string): Promise<PtzConfiguration[]>;

  /** Returns all preset tours for a profile. */
  getPresetTours(profileToken: string): Promise<PresetTour[]>;

  /** Returns a specific preset tour. */
  getPresetTour(profileToken: string, presetTourToken: string): Promise<PresetTour>;

  /** Returns the capabilities of the PTZ service. */
  getServiceCapabilities(): Promise<Record<string, unknown>>;
}

// ── Imaging service ─────────────────────────────────────────────────────────

export interface ImagingService {
  /** Returns the current imaging preset. */
  getCurrentPreset(videoSourceToken: string): Promise<ImagingPreset>;

  /** Returns available imaging presets. */
  getPresets(videoSourceToken: string): Promise<ImagingPreset[]>;

  /** Returns the current imaging status. */
  getStatus(videoSourceToken: string): Promise<ImagingStatus>;

  /** Applies an imaging preset to a video source. */
  setCurrentPreset(videoSourceToken: string, presetToken: string): Promise<boolean>;

  /** Returns the capabilities of the imaging service. */
  getServiceCapabilities(): Promise<Record<string, unknown>>;
}

// ── Search service ──────────────────────────────────────────────────────────

export interface SearchService {
  /** Starts a recording search session. Returns a search token. */
  findRecordings(keepAliveTime?: number): Promise<string>;

  /** Gets results from a recording search session. */
  getRecordingSearchResults(searchToken: string): Promise<Record<string, unknown>[]>;

  /** Returns information about a specific recording. */
  getRecordingInformation(recordingToken: string): Promise<Record<string, unknown>>;

  /** Returns a summary of all recordings. */
  getRecordingSummary(): Promise<Record<string, unknown>>;
}

// ── Recordings service ──────────────────────────────────────────────────────

export interface RecordingsService {
  /** Lists all recordings on the device. */
  getRecordings(): Promise<Record<string, unknown>[]>;

  /** Returns the capabilities of the recordings service. */
  getServiceCapabilities(): Promise<Record<string, unknown>>;
}

// ── Replay service ──────────────────────────────────────────────────────────

export interface ReplayService {
  /** Returns the replay configuration. */
  getReplayConfiguration(): Promise<Record<string, unknown>>;

  /** Returns a URI for replaying a recording. */
  getReplayUri(recordingToken: string): Promise<string>;

  /** Returns the capabilities of the replay service. */
  getServiceCapabilities(): Promise<Record<string, unknown>>;
}

// ── Main API ────────────────────────────────────────────────────────────────

/**
 * The ONVIF API surface exposed by the compiled dart2js bundle.
 *
 * All handles are opaque integers; pass them back unchanged to subsequent
 * calls. Call `disconnect(handle)` to release resources.
 *
 * Service objects are obtained via `getDeviceManagement(handle)`,
 * `getMedia(handle)`, `getPtz(handle)`, etc.
 */
export interface EasyOnvifApi {
  /** Connects to a device and returns an opaque handle. */
  connect(options: ConnectOptions): Promise<number>;

  /** Releases the given handle. Idempotent. */
  disconnect(handle: number): void;

  // ── Service getters ────────────────────────────────────────────────────

  /** Returns a DeviceManagement service proxy for the given handle. */
  getDeviceManagement(handle: number): DeviceManagementService;

  /** Returns a Media service proxy for the given handle. */
  getMedia(handle: number): MediaService;

  /** Returns a PTZ service proxy for the given handle. */
  getPtz(handle: number): PtzService;

  /** Returns an Imaging service proxy for the given handle. */
  getImaging(handle: number): ImagingService;

  /** Returns a Search service proxy for the given handle. */
  getSearch(handle: number): SearchService;

  /** Returns a Recordings service proxy for the given handle. */
  getRecordings(handle: number): RecordingsService;

  /** Returns a Replay service proxy for the given handle. */
  getReplay(handle: number): ReplayService;

  // ── Node-only methods ──────────────────────────────────────────────────

  /**
   * Runs WS-Discovery over UDP multicast (239.255.255.250:3702) for the
   * given number of seconds and returns the raw probe matches.
   */
  probe(timeoutSeconds?: number): Promise<ProbeMatch[]>;
}

/**
 * Loads the compiled dart2js bundle (lazily, exactly once) and returns
 * the ONVIF API object.
 */
export function loadEasyOnvif(): Promise<EasyOnvifApi>;

export default loadEasyOnvif;
