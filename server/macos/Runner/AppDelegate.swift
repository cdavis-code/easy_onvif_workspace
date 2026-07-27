import Cocoa
import FlutterMacOS
import AVFoundation

@main
class AppDelegate: FlutterAppDelegate {
  /// The hardware H.264 encoder bridged to Dart over platform channels.
  private let encoder = VideoToolboxEncoder()
  private var encoderEventSink: FlutterEventSink?

  /// Microphone capture bridged to Dart's NativeAudioSource.
  private let audioCapture = AudioCaptureSource()
  private var audioEventSink: FlutterEventSink?

  /// ScreenCaptureKit capture (macOS 12.3+), feeding the shared encoder.
  private var screenCapture: Any?

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
      registerAudioChannels(messenger: messenger)
      registerScreenCaptureChannel(messenger: messenger)
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
      case "requestScreenCapture":
        if CGPreflightScreenCaptureAccess() {
          result(true)
        } else {
          result(CGRequestScreenCaptureAccess())
        }
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

  /// Channels backing `NativeAudioSource`: control + PCM16/8 kHz event stream.
  private func registerAudioChannels(messenger: FlutterBinaryMessenger) {
    let control = FlutterMethodChannel(
      name: "easy_onvif_server/audio_capture",
      binaryMessenger: messenger
    )

    control.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }

      switch call.method {
      case "start":
        let args = call.arguments as? [String: Any] ?? [:]
        let deviceUid = args["deviceUid"] as? String ?? ""
        do {
          try self.audioCapture.start(deviceUid: deviceUid)
          result(nil)
        } catch {
          result(FlutterError(code: "audio_start", message: error.localizedDescription, details: nil))
        }

      case "stop":
        self.audioCapture.stop()
        result(nil)

      case "listDevices":
        result(AudioCaptureSource.listInputDevices())

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let events = FlutterEventChannel(
      name: "easy_onvif_server/audio_capture/events",
      binaryMessenger: messenger
    )

    events.setStreamHandler(AudioStreamHandler(capture: audioCapture) { [weak self] sink in
      self?.audioEventSink = sink
    })
  }

  /// Channel backing `ScreenH264Source`: starts/stops display capture. The
  /// encoded H.264 flows through the existing encoder event channel.
  private func registerScreenCaptureChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "easy_onvif_server/screen_capture",
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }

      // Display enumeration is plain CoreGraphics; it must work even where
      // ScreenCaptureKit itself is unavailable, so handle it before the guard.
      if call.method == "listDisplays" {
        result(AppDelegate.listDisplays())
        return
      }

      guard #available(macOS 12.3, *) else {
        result(FlutterError(
          code: "unavailable", message: "ScreenCaptureKit requires macOS 12.3+", details: nil))
        return
      }

      switch call.method {
      case "start":
        let args = call.arguments as? [String: Any] ?? [:]
        let displayId = UInt32(args["displayId"] as? Int ?? 0)
        let width = args["width"] as? Int ?? 1280
        let height = args["height"] as? Int ?? 720
        let frameRate = args["frameRate"] as? Int ?? 15
        let capture = ScreenCaptureSource(encoder: self.encoder)
        self.screenCapture = capture
        capture.start(displayId: displayId, width: width, height: height, frameRate: frameRate) { error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "screen_start", message: error.localizedDescription, details: nil))
            } else {
              result(nil)
            }
          }
        }

      case "stop":
        if let capture = self.screenCapture as? ScreenCaptureSource { capture.stop() }
        self.screenCapture = nil
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Active displays as `{id, name}` pairs for the settings UI's display
  /// picker. Names come from NSScreen when a match exists (localizedName,
  /// macOS 10.15+); otherwise a generic label with the CGDirectDisplayID.
  private static func listDisplays() -> [[String: Any]] {
    var displayCount: UInt32 = 0

    guard CGGetActiveDisplayList(0, nil, &displayCount) == .success, displayCount > 0 else {
      return []
    }

    var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))

    guard CGGetActiveDisplayList(displayCount, &displays, &displayCount) == .success else {
      return []
    }

    return displays.map { displayId in
      let screen = NSScreen.screens.first {
        ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
          == displayId
      }
      let main = CGDisplayIsMain(displayId) != 0
      let fallback = main ? "Main Display" : "Display \(displayId)"

      return ["id": Int(displayId), "name": screen?.localizedName ?? fallback]
    }
  }

  /// Requests access to [mediaType], showing the system prompt the first time,
  /// and returns whether access is authorized.
  ///
  /// Calls `requestAccess` unconditionally: it prompts when the status is
  /// undetermined and answers immediately otherwise. Preflighting with
  /// `authorizationStatus` first is unreliable — it can report an "unknown"
  /// state (e.g. right after a `tccutil` reset) that maps to the no-prompt
  /// branch, leaving the permission permanently unrequested.
  private static func requestAccess(for mediaType: AVMediaType, result: @escaping FlutterResult) {
    AVCaptureDevice.requestAccess(for: mediaType) { granted in
      NSLog("easy_onvif_server: \(mediaType.rawValue) access \(granted ? "granted" : "denied")")
      DispatchQueue.main.async { result(granted) }
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

/// Bridges microphone PCM chunks to a Flutter event stream.
private final class AudioStreamHandler: NSObject, FlutterStreamHandler {
  private let capture: AudioCaptureSource
  private let onSink: (FlutterEventSink?) -> Void

  init(capture: AudioCaptureSource, onSink: @escaping (FlutterEventSink?) -> Void) {
    self.capture = capture
    self.onSink = onSink
    super.init()
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    onSink(events)
    capture.onPcm = { data in
      DispatchQueue.main.async { events(FlutterStandardTypedData(bytes: data)) }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    capture.onPcm = nil
    onSink(nil)
    return nil
  }
}
