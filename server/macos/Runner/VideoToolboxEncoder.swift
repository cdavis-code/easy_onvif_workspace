import Foundation
import VideoToolbox
import CoreMedia
import CoreVideo
import CoreGraphics
import ImageIO
import CoreServices

/// A hardware H.264 encoder backed by Apple's VideoToolbox.
///
/// Raw BGRA camera frames (delivered by the `camera_desktop` image stream and
/// forwarded from Dart over a method channel) are compressed with a
/// `VTCompressionSession`. Each encoded access unit is emitted as an Annex-B
/// byte buffer (start-code delimited NAL units) on [onOutput]; SPS/PPS are
/// prepended to every keyframe so a client can begin decoding at any IDR.
///
/// The Dart side (`CameraH264Source` + `AccessUnitFramer`) splits these bytes
/// into NAL units and frames them for RTP, exactly as it does for the ffmpeg
/// source — so the RTSP server is unchanged.
final class VideoToolboxEncoder {
  /// Called on the main queue with each Annex-B encoded access unit.
  var onOutput: ((Data) -> Void)?

  private var session: VTCompressionSession?
  private var width: Int = 0
  private var height: Int = 0
  private var frameRate: Int = 15

  private var frameIndex: Int64 = 0
  private let startEpoch = Date()

  /// The most recent camera frame, retained so [snapshotJpeg] can produce a
  /// still on demand (e.g. for the ONVIF snapshot endpoint).
  private var latestPixelBuffer: CVPixelBuffer?

  func start(width: Int, height: Int, frameRate: Int) {
    stop()

    self.width = width
    self.height = height
    self.frameRate = max(1, frameRate)
    self.frameIndex = 0

    var session: VTCompressionSession?
    let status = VTCompressionSessionCreate(
      allocator: kCFAllocatorDefault,
      width: Int32(width),
      height: Int32(height),
      codecType: kCMVideoCodecType_H264,
      encoderSpecification: nil,
      imageBufferAttributes: nil,
      compressedDataAllocator: nil,
      outputCallback: VideoToolboxEncoder.outputCallback,
      refcon: Unmanaged.passUnretained(self).toOpaque(),
      compressionSessionOut: &session
    )

    guard status == noErr, let session = session else {
      NSLog("VideoToolboxEncoder: failed to create session (status \(status))")
      return
    }

    // Real-time, low-latency encoding suitable for live streaming.
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel,
                         value: kVTProfileLevel_H264_Baseline_AutoLevel)
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
    // One keyframe per second keeps the stream joinable without bloating it.
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval,
                         value: NSNumber(value: self.frameRate))
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ExpectedFrameRate,
                         value: NSNumber(value: self.frameRate))
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate,
                         value: NSNumber(value: 2_000_000))

    VTCompressionSessionPrepareToEncodeFrames(session)

    self.session = session
  }

  /// Encodes one BGRA frame. [bytes] must be `width * height * 4` bytes.
  func encode(bytes: Data, width: Int, height: Int, bytesPerRow: Int) {
    guard let session = session else { return }

    // The source row stride may include padding; default to tight packing.
    let srcRowBytes = bytesPerRow > 0 ? bytesPerRow : width * 4
    guard bytes.count >= srcRowBytes * height else { return }

    let attrs: [CFString: Any] = [
      kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
      kCVPixelBufferWidthKey: width,
      kCVPixelBufferHeightKey: height,
      kCVPixelBufferCGImageCompatibilityKey: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey: true,
    ]

    var pixelBuffer: CVPixelBuffer?
    let createStatus = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_32BGRA,
      attrs as CFDictionary,
      &pixelBuffer
    )

    guard createStatus == kCVReturnSuccess, let pixelBuffer = pixelBuffer else { return }

    // Copy the frame bytes into the pixel buffer. The source `bytes` belong to
    // the method-channel argument and are freed when this call returns, but
    // VideoToolbox encodes asynchronously, so the buffer must own its data.
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    if let base = CVPixelBufferGetBaseAddress(pixelBuffer) {
      let dstRowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
      bytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
        if let src = raw.baseAddress {
          if dstRowBytes == width * 4 && srcRowBytes == width * 4 {
            base.copyMemory(from: src, byteCount: width * height * 4)
          } else {
            for row in 0..<height {
              base.advanced(by: row * dstRowBytes)
                .copyMemory(from: src.advanced(by: row * srcRowBytes), byteCount: width * 4)
            }
          }
        }
      }
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

    // Cache for on-demand snapshots.
    latestPixelBuffer = pixelBuffer

    let presentationTime = CMTime(value: frameIndex, timescale: CMTimeScale(frameRate))
    frameIndex += 1

    var flags: VTEncodeInfoFlags = []
    VTCompressionSessionEncodeFrame(
      session,
      imageBuffer: pixelBuffer,
      presentationTimeStamp: presentationTime,
      duration: .invalid,
      frameProperties: nil,
      sourceFrameRefcon: nil,
      infoFlagsOut: &flags
    )
  }

  /// Returns the most recent camera frame encoded as JPEG, or `nil` if no frame
  /// has been received yet. Backs the ONVIF snapshot endpoint.
  func snapshotJpeg() -> Data? {
    guard let pixelBuffer = latestPixelBuffer else { return nil }
    guard let image = Self.cgImage(from: pixelBuffer) else { return nil }

    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
      data as CFMutableData, kUTTypeJPEG, 1, nil
    ) else { return nil }

    CGImageDestinationAddImage(destination, image, nil)

    guard CGImageDestinationFinalize(destination) else { return nil }

    return data as Data
  }

  /// Builds a `CGImage` from a BGRA pixel buffer by copying its bytes (so the
  /// image stays valid after the buffer is recycled). Compatible with the
  /// macOS 10.15 deployment target (avoids the newer `CVPixelBufferGetCGImage`).
  private static func cgImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

    guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

    let data = Data(
      bytesNoCopy: base,
      count: bytesPerRow * height,
      deallocator: .none
    )

    guard let provider = CGDataProvider(data: data as CFData) else { return nil }

    // The camera delivers BGRA whose alpha byte is typically uninitialized.
    // Declare it as `noneSkipFirst` (XRGB) so the alpha lane is treated as
    // opaque padding and ignored — using a premultiplied alpha here would make
    // ImageIO un-premultiply by the garbage alpha and blow the JPEG out to
    // white (over-exposed).
    //
    // The memory layout is [B][G][R][A] (little-endian 0xAARRGGBB), so we must
    // set `byteOrder32Little` — without it CoreGraphics defaults to big-endian
    // and reads the alpha byte as blue, producing a blue-tinted image.
    return CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 32,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGBitmapInfo(rawValue:
        CGImageAlphaInfo.noneSkipFirst.rawValue |
        CGBitmapInfo.byteOrder32Little.rawValue),
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    )
  }

  func stop() {
    if let session = session {
      VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
      VTCompressionSessionInvalidate(session)
    }
    session = nil
    frameIndex = 0
    latestPixelBuffer = nil
  }

  // MARK: - Output callback

  private static let outputCallback: VTCompressionOutputCallback = {
    outputCallbackRefCon, _, status, _, sampleBuffer in
    guard let refCon = outputCallbackRefCon else { return }
    let encoder = Unmanaged<VideoToolboxEncoder>.fromOpaque(refCon).takeUnretainedValue()
    encoder.handleEncodedFrame(status: status, sampleBuffer: sampleBuffer)
  }

  private func handleEncodedFrame(status: OSStatus, sampleBuffer: CMSampleBuffer?) {
    guard status == noErr, let sampleBuffer = sampleBuffer else { return }

    let isKeyFrame = !Self.hasNotSyncAttachment(sampleBuffer)
    let annexB = Self.annexB(from: sampleBuffer, prependParameterSets: isKeyFrame)

    guard let data = annexB, !data.isEmpty else { return }

    DispatchQueue.main.async { [weak self] in
      self?.onOutput?(data)
    }
  }

  /// Returns true if the sample carries the `NotSync` attachment (i.e. it is
  /// *not* a keyframe). A sample without the attachment is a keyframe.
  private static func hasNotSyncAttachment(_ sampleBuffer: CMSampleBuffer) -> Bool {
    guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false),
          CFArrayGetCount(attachments) > 0 else {
      return false
    }

    let dict = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFDictionary.self)
    var value: UnsafeRawPointer?
    let key = Unmanaged.passUnretained(kCMSampleAttachmentKey_NotSync).toOpaque()

    return CFDictionaryGetValueIfPresent(dict, key, &value)
  }

  // MARK: - AVCC → Annex-B conversion

  /// Converts an AVCC (length-prefixed) sample buffer into Annex-B
  /// (start-code delimited) bytes, optionally prepending SPS/PPS for keyframes.
  private static func annexB(from sampleBuffer: CMSampleBuffer, prependParameterSets: Bool) -> Data? {
    guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else { return nil }

    var result = Data()
    let startCode = Data([0, 0, 0, 1])

    if prependParameterSets {
      var parameterSetCount = 0
      let countStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
        formatDescription, parameterSetIndex: 0,
        parameterSetPointerOut: nil, parameterSetSizeOut: nil,
        parameterSetCountOut: &parameterSetCount, nalUnitHeaderLengthOut: nil
      )

      if countStatus == noErr {
        for index in 0..<parameterSetCount {
          var setPointer: UnsafePointer<UInt8>?
          var setSize = 0
          let status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            formatDescription, parameterSetIndex: index,
            parameterSetPointerOut: &setPointer, parameterSetSizeOut: &setSize,
            parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil
          )
          if status == noErr, let setPointer = setPointer {
            result.append(startCode)
            result.append(Data(bytes: setPointer, count: setSize))
          }
        }
      }
    }

    guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }

    var totalLength = 0
    var dataPointer: UnsafeMutablePointer<Int8>?
    let dataStatus = CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: nil,
                                                 totalLengthOut: &totalLength, dataPointerOut: &dataPointer)
    guard dataStatus == kCMBlockBufferNoErr, let pointer = dataPointer else { return nil }

    let nalLengthSize = 4
    var offset = 0
    let bytes = UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self)

    while offset + nalLengthSize <= totalLength {
      let nalLength =
        Int(bytes[offset]) << 24 |
        Int(bytes[offset + 1]) << 16 |
        Int(bytes[offset + 2]) << 8 |
        Int(bytes[offset + 3])
      offset += nalLengthSize

      guard nalLength > 0, offset + nalLength <= totalLength else { break }

      result.append(startCode)
      result.append(Data(bytes: bytes + offset, count: nalLength))
      offset += nalLength
    }

    return result
  }
}
