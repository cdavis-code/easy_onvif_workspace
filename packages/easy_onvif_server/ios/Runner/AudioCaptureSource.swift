import AVFoundation

/// Captures the default microphone with AVAudioEngine, converts to PCM16 mono
/// 8 kHz, and forwards each chunk to `onPcm`.
final class AudioCaptureSource {
  private let engine = AVAudioEngine()
  private var converter: AVAudioConverter?
  private var running = false

  var onPcm: ((Data) -> Void)?

  func start(deviceUid: String) throws {
    if running { return }

    // deviceUid is ignored on iOS: the default microphone is used.
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement)
    try session.setActive(true)

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
}
