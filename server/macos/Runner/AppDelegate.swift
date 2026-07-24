import Cocoa
import FlutterMacOS
import AVFoundation

@main
class AppDelegate: FlutterAppDelegate {
  /// The hardware H.264 encoder bridged to Dart over platform channels.
  private let encoder = VideoToolboxEncoder()
  private var encoderEventSink: FlutterEventSink?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Expose a channel so Dart can trigger the standard camera/microphone
    // permission prompt. This matters because the RTSP video source is an
    // `ffmpeg` subprocess: macOS will not prompt on a child process's behalf,
    // so the host app must obtain the TCC grant first. Once the app is granted,
    // the ffmpeg child inherits access to the capture device.
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      let messenger = controller.engine.binaryMessenger

      registerPermissionChannel(messenger: messenger)
      registerEncoderChannels(messenger: messenger)
    }

    super.applicationDidFinishLaunching(notification)
  }

  /// Channel used by Dart to request the macOS camera/microphone TCC grant.
  private func registerPermissionChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "easy_onvif_server/permissions",
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "requestCamera":
        AppDelegate.requestAccess(for: .video, result: result)
      case "requestMicrophone":
        AppDelegate.requestAccess(for: .audio, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Channels backing `PlatformChannelH264Encoder`: a method channel to control
  /// the VideoToolbox encoder and feed it raw frames, and an event channel that
  /// streams Annex-B encoded access units back to Dart.
  private func registerEncoderChannels(messenger: FlutterBinaryMessenger) {
    let control = FlutterMethodChannel(
      name: "easy_onvif_server/h264_encoder",
      binaryMessenger: messenger
    )

    control.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }

      switch call.method {
      case "start":
        let args = call.arguments as? [String: Any] ?? [:]
        let width = args["width"] as? Int ?? 1280
        let height = args["height"] as? Int ?? 720
        let frameRate = args["frameRate"] as? Int ?? 15
        self.encoder.start(width: width, height: height, frameRate: frameRate)
        result(nil)

      case "encode":
        let args = call.arguments as? [String: Any] ?? [:]
        if let bytes = (args["bytes"] as? FlutterStandardTypedData)?.data {
          let width = args["width"] as? Int ?? 0
          let height = args["height"] as? Int ?? 0
          let bytesPerRow = args["bytesPerRow"] as? Int ?? (width * 4)
          self.encoder.encode(bytes: bytes, width: width, height: height, bytesPerRow: bytesPerRow)
        }
        result(nil)

      case "stop":
        self.encoder.stop()
        result(nil)

      case "snapshot":
        if let jpeg = self.encoder.snapshotJpeg() {
          result(FlutterStandardTypedData(bytes: jpeg))
        } else {
          result(nil)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let events = FlutterEventChannel(
      name: "easy_onvif_server/h264_encoder/events",
      binaryMessenger: messenger
    )

    events.setStreamHandler(EncoderStreamHandler(encoder: encoder) { [weak self] sink in
      self?.encoderEventSink = sink
    })
  }

  /// Requests access to [mediaType], showing the system prompt the first time,
  /// and returns whether access is authorized.
  private static func requestAccess(for mediaType: AVMediaType, result: @escaping FlutterResult) {
    switch AVCaptureDevice.authorizationStatus(for: mediaType) {
    case .authorized:
      result(true)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: mediaType) { granted in
        DispatchQueue.main.async { result(granted) }
      }
    default:
      result(false)
    }
  }
}

/// Bridges the encoder's Annex-B output to a Flutter event stream.
private final class EncoderStreamHandler: NSObject, FlutterStreamHandler {
  private let encoder: VideoToolboxEncoder
  private let onSink: (FlutterEventSink?) -> Void

  init(encoder: VideoToolboxEncoder, onSink: @escaping (FlutterEventSink?) -> Void) {
    self.encoder = encoder
    self.onSink = onSink
    super.init()
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    onSink(events)
    encoder.onOutput = { data in
      events(FlutterStandardTypedData(bytes: data))
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    encoder.onOutput = nil
    onSink(nil)
    return nil
  }
}
