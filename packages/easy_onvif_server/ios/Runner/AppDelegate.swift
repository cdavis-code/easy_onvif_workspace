import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Microphone capture bridged to Dart's NativeAudioSource.
  private let audioCapture = AudioCaptureSource()
  private var audioEventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    registerAudioChannels(messenger: engineBridge.applicationRegistrar.messenger())
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
