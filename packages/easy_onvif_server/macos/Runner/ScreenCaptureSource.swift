import CoreMedia
import ScreenCaptureKit

/// Captures a display with ScreenCaptureKit and feeds BGRA frames into the
/// existing VideoToolbox H.264 encoder, so the encoded output reaches Dart on
/// the already-registered `easy_onvif_server/h264_encoder/events` channel.
@available(macOS 12.3, *)
final class ScreenCaptureSource: NSObject, SCStreamOutput {
  private let encoder: VideoToolboxEncoder
  private let queue = DispatchQueue(label: "easy_onvif_server.screen_capture")
  private var stream: SCStream?

  init(encoder: VideoToolboxEncoder) {
    self.encoder = encoder
  }

  func start(
    displayId: UInt32, width: Int, height: Int, frameRate: Int,
    completion: @escaping (Error?) -> Void
  ) {
    SCShareableContent.getWithCompletionHandler { [weak self] content, error in
      guard let self = self else { return }

      if let error = error {
        completion(error)
        return
      }

      let displays = content?.displays ?? []
      guard let display = displays.first(where: { $0.displayID == displayId }) ?? displays.first else {
        completion(NSError(
          domain: "easy_onvif_server", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "No display available to capture"]))
        return
      }

      let filter = SCContentFilter(display: display, excludingWindows: [])
      let configuration = SCStreamConfiguration()
      configuration.width = width
      configuration.height = height
      configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(frameRate))
      configuration.pixelFormat = kCVPixelFormatType_32BGRA

      let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)

      do {
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: self.queue)
        self.encoder.start(width: width, height: height, frameRate: frameRate)
        stream.startCapture { error in completion(error) }
        self.stream = stream
      } catch {
        completion(error)
      }
    }
  }

  func stop() {
    stream?.stopCapture()
    stream = nil
    encoder.stop()
  }

  func stream(
    _ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
    of type: SCStreamOutputType
  ) {
    guard type == .screen, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

    guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let width = CVPixelBufferGetWidth(pixelBuffer)

    encoder.encode(
      bytes: Data(bytes: base, count: bytesPerRow * height),
      width: width, height: height, bytesPerRow: bytesPerRow)
  }
}
