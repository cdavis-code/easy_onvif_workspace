import AVFoundation
import CoreAudio

/// Captures the input device with AVAudioEngine, converts to PCM16 mono
/// 8 kHz, and forwards each chunk to `onPcm` (bridged to Dart, which does the
/// G.711 A-law encode).
final class AudioCaptureSource {
  private let engine = AVAudioEngine()
  private var converter: AVAudioConverter?
  private var running = false

  var onPcm: ((Data) -> Void)?

  func start(deviceUid: String) throws {
    if running { return }

    if !deviceUid.isEmpty { selectInput(uid: deviceUid) }

    let input = engine.inputNode
    let inputFormat = input.outputFormat(forBus: 0)
    guard let outFormat = AVAudioFormat(
      commonFormat: .pcmFormatInt16, sampleRate: 8000, channels: 1, interleaved: true
    ) else { return }

    converter = AVAudioConverter(from: inputFormat, to: outFormat)

    input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
      guard let self = self, let converter = self.converter else { return }

      let ratio = 8000.0 / inputFormat.sampleRate
      let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 16
      guard let out = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: capacity) else { return }

      var consumed = false
      var error: NSError?

      converter.convert(to: out, error: &error) { _, status in
        if consumed { status.pointee = .noDataNow; return nil }
        consumed = true
        status.pointee = .haveData
        return buffer
      }

      if error == nil, out.frameLength > 0, let channel = out.int16ChannelData {
        self.onPcm?(Data(bytes: channel[0], count: Int(out.frameLength) * 2))
      }
    }

    engine.prepare()
    try engine.start()
    running = true
  }

  func stop() {
    guard running else { return }
    engine.inputNode.removeTap(onBus: 0)
    engine.stop()
    running = false
  }

  /// Enumerates input-capable CoreAudio devices as `{uid, name}` pairs, for
  /// the settings UI's audio device picker.
  static func listInputDevices() -> [[String: String]] {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDevices,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: AudioObjectPropertyElement(0))
    var size: UInt32 = 0

    guard AudioObjectGetPropertyDataSize(
      AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else { return [] }

    let count = Int(size) / MemoryLayout<AudioDeviceID>.size
    var devices = [AudioDeviceID](repeating: 0, count: count)

    guard AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &devices) == noErr else { return [] }

    var result: [[String: String]] = []

    for device in devices {
      // Input-capable = has at least one input stream buffer.
      var inputAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyStreamConfiguration,
        mScope: kAudioDevicePropertyScopeInput,
        mElement: AudioObjectPropertyElement(0))
      var configSize: UInt32 = 0

      guard AudioObjectGetPropertyDataSize(device, &inputAddress, 0, nil, &configSize) == noErr,
            configSize > 0 else { continue }

      let bufferList = UnsafeMutableRawPointer.allocate(
        byteCount: Int(configSize), alignment: MemoryLayout<AudioBufferList>.alignment)
      defer { bufferList.deallocate() }

      guard AudioObjectGetPropertyData(
        device, &inputAddress, 0, nil, &configSize,
        bufferList.assumingMemoryBound(to: AudioBufferList.self)) == noErr else { continue }

      let buffers = UnsafeMutableAudioBufferListPointer(
        bufferList.assumingMemoryBound(to: AudioBufferList.self))

      guard buffers.reduce(0, { $0 + Int($1.mNumberChannels) }) > 0 else { continue }

      guard let uid = stringProperty(device, selector: kAudioDevicePropertyDeviceUID) else { continue }

      let name = stringProperty(device, selector: kAudioObjectPropertyName) ?? uid

      result.append(["uid": uid, "name": name])
    }

    return result
  }

  private static func stringProperty(
    _ device: AudioDeviceID, selector: AudioObjectPropertySelector
  ) -> String? {
    var address = AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: AudioObjectPropertyElement(0))
    var value: CFString = "" as CFString
    var size = UInt32(MemoryLayout<CFString>.size)

    let status = withUnsafeMutablePointer(to: &value) { pointer in
      AudioObjectGetPropertyData(device, &address, 0, nil, &size, pointer)
    }

    return status == noErr ? (value as String) : nil
  }

  /// Points the input audio unit at the CoreAudio device with the given UID.
  /// Unknown UIDs silently keep the system default input.
  private func selectInput(uid: String) {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDevices,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: AudioObjectPropertyElement(0))
    var size: UInt32 = 0

    guard AudioObjectGetPropertyDataSize(
      AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else { return }

    let count = Int(size) / MemoryLayout<AudioDeviceID>.size
    var devices = [AudioDeviceID](repeating: 0, count: count)

    guard AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &devices) == noErr else { return }

    for device in devices {
      var uidAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceUID,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: AudioObjectPropertyElement(0))
      var deviceUid: CFString = "" as CFString
      var uidSize = UInt32(MemoryLayout<CFString>.size)

      let status = withUnsafeMutablePointer(to: &deviceUid) { pointer in
        AudioObjectGetPropertyData(device, &uidAddress, 0, nil, &uidSize, pointer)
      }

      if status == noErr, (deviceUid as String) == uid {
        var deviceId = device

        if let unit = engine.inputNode.audioUnit {
          AudioUnitSetProperty(
            unit, kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global, 0, &deviceId,
            UInt32(MemoryLayout<AudioDeviceID>.size))
        }
        return
      }
    }
  }
}
