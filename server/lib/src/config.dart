/// Runtime configuration for the ONVIF server.
///
/// All values have sensible defaults (matching the assumptions in the project
/// plan) and can be overridden when constructing [ServerConfig].
class ServerConfig {
  /// HTTP port the SOAP service listens on.
  final int httpPort;

  /// RTSP port advertised by `GetStreamUri`.
  final int rtspPort;

  /// WS-Discovery uses a fixed well-known port; exposed for completeness.
  final int discoveryPort;

  /// Username accepted by the WS-Security UsernameToken validator.
  final String username;

  /// Password accepted by the WS-Security UsernameToken validator.
  final String password;

  /// Values reported by `GetDeviceInformation`.
  final String manufacturer;
  final String model;
  final String firmwareVersion;
  final String serialNumber;
  final String hardwareId;

  /// Hostname reported by `GetHostname`.
  final String hostname;

  const ServerConfig({
    this.httpPort = 8080,
    this.rtspPort = 8554,
    this.discoveryPort = 3702,
    this.username = 'admin',
    this.password = 'admin',
    this.manufacturer = 'easy_onvif',
    this.model = 'Dart ONVIF Server',
    this.firmwareVersion = '0.1.0',
    this.serialNumber = 'EASY-ONVIF-SERVER-0001',
    this.hardwareId = '1',
    this.hostname = 'easy-onvif-server',
  });

  /// The base URL for this device given the advertised [host] (IP or name).
  String baseUrl(String host) => 'http://$host:$httpPort';

  /// The device service endpoint for the advertised [host].
  String deviceServiceUrl(String host) =>
      '${baseUrl(host)}/onvif/device_service';

  /// The Media (ver10) service endpoint for the advertised [host].
  String mediaServiceUrl(String host) => '${baseUrl(host)}/onvif/Media';

  /// The Media2 (ver20) service endpoint for the advertised [host].
  String media2ServiceUrl(String host) => '${baseUrl(host)}/onvif/Media2';

  /// The PTZ service endpoint for the advertised [host].
  String ptzServiceUrl(String host) => '${baseUrl(host)}/onvif/PTZ';

  /// The RTSP stream URL for the advertised [host] and [profileToken].
  String rtspUrl(String host, String profileToken) =>
      'rtsp://$host:$rtspPort/onvif/$profileToken';

  /// The HTTP snapshot URL for the advertised [host] and [profileToken].
  String snapshotUrl(String host, String profileToken) =>
      '${baseUrl(host)}/onvif/snapshot/$profileToken';
}
