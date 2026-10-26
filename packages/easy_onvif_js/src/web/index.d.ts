// TypeScript declarations for easy-onvif-web.

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

export interface ConnectOptions {
  host: string;
  username: string;
  password: string;
}

/**
 * Browser-flavored ONVIF API surface.
 *
 * `probe()` always rejects with an `UnsupportedError` — browsers cannot open
 * UDP sockets, so WS-Discovery is structurally unavailable. Connect to known
 * camera endpoints with `connect()` through a CORS-friendly proxy instead.
 */
export interface EasyOnvifApi {
  connect(options: ConnectOptions): Promise<number>;
  disconnect(handle: number): void;
  getDeviceInformation(handle: number): Promise<DeviceInformation>;
  getProfiles(handle: number): Promise<Profile[]>;
  getStreamUri(handle: number, profileToken: string): Promise<string>;
  getSnapshotUri(handle: number, profileToken: string): Promise<string>;
  absoluteMove(
    handle: number,
    profileToken: string,
    x: number,
    y: number,
    zoom: number,
  ): Promise<boolean>;
  /** Always rejects. WS-Discovery is not available in browsers. */
  probe(timeoutSeconds?: number): Promise<never>;
}

export function loadEasyOnvif(): Promise<EasyOnvifApi>;

export default loadEasyOnvif;
