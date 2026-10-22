// Cuts a simulator recording into the welcome screen clip:
// keeps [start, end], crops to the top part of the screen, scales it down,
// cross-fades the end into the start (so the loop has no jump) and writes
// an H.264 mp4 plus a JPEG of its first frame.
//
//   swift edit.swift <in.mp4> <out.mp4> <poster.jpg> <start s> <end s> \
//       <crop height ÷ width> <out width> [fade s]
import AVFoundation
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
guard a.count >= 8 else {
  print("usage: edit.swift in out poster start end crop width [fade]")
  exit(2)
}
let src = AVURLAsset(url: URL(fileURLWithPath: a[1]))
let outURL = URL(fileURLWithPath: a[2])
let posterURL = URL(fileURLWithPath: a[3])
let start = Double(a[4])!, end = Double(a[5])!
let aspect = Double(a[6])!, width = Double(a[7])!
let fade = a.count > 8 ? Double(a[8])! : 0.5

func t(_ s: Double) -> CMTime { CMTime(seconds: s, preferredTimescale: 600) }

func run() async throws {
  guard let track = try await src.loadTracks(withMediaType: .video).first else {
    throw NSError(domain: "edit", code: 1, userInfo: [NSLocalizedDescriptionKey: "no video track"])
  }
  let natural = try await track.load(.naturalSize)
  let fps = try await track.load(.nominalFrameRate)

  // Output timeline: src[start+fade, end] on track A from 0; src[start,
  // start+fade] on track B over the last `fade` seconds, fading in. The
  // last frame then equals the first one.
  let length = end - start - fade
  let comp = AVMutableComposition()
  let ta = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
  let tb = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
  try ta.insertTimeRange(CMTimeRange(start: t(start + fade), end: t(end)), of: track, at: .zero)
  try tb.insertTimeRange(CMTimeRange(start: t(start), end: t(start + fade)), of: track, at: t(length - fade))

  let scale = width / natural.width
  let height = (width * aspect / 2).rounded() * 2
  let transform = CGAffineTransform(scaleX: scale, y: scale)

  // Instruction ranges follow the composition's own (rounded) duration.
  let total = comp.duration
  let blendStart = CMTimeSubtract(total, t(fade))
  let main = AVMutableVideoCompositionInstruction()
  main.timeRange = CMTimeRange(start: .zero, end: blendStart)
  let la = AVMutableVideoCompositionLayerInstruction(assetTrack: ta)
  la.setTransform(transform, at: .zero)
  main.layerInstructions = [la]

  let blend = AVMutableVideoCompositionInstruction()
  blend.timeRange = CMTimeRange(start: blendStart, end: total)
  let lb = AVMutableVideoCompositionLayerInstruction(assetTrack: tb)
  lb.setTransform(transform, at: .zero)
  lb.setOpacityRamp(fromStartOpacity: 0, toEndOpacity: 1, timeRange: blend.timeRange)
  let la2 = AVMutableVideoCompositionLayerInstruction(assetTrack: ta)
  la2.setTransform(transform, at: .zero)
  blend.layerInstructions = [lb, la2]

  let video = AVMutableVideoComposition()
  video.renderSize = CGSize(width: width, height: height)
  video.frameDuration = CMTime(value: 1, timescale: CMTimeScale(max(30, min(60, fps.rounded()))))
  video.instructions = [main, blend]

  // Encode with a set bitrate so the clip stays small.
  try? FileManager.default.removeItem(at: outURL)
  let reader = try AVAssetReader(asset: comp)
  let output = AVAssetReaderVideoCompositionOutput(
    videoTracks: [ta, tb],
    videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
  output.videoComposition = video
  reader.add(output)
  let writer = try AVAssetWriter(outputURL: outURL, fileType: .mp4)
  let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [
      AVVideoAverageBitRateKey: 1_400_000,
      AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
      AVVideoMaxKeyFrameIntervalKey: 60,
    ],
  ])
  input.expectsMediaDataInRealTime = false
  writer.add(input)
  writer.startWriting()
  reader.startReading()
  writer.startSession(atSourceTime: .zero)
  var first: CVPixelBuffer?
  while let sample = output.copyNextSampleBuffer() {
    while !input.isReadyForMoreMediaData { usleep(2000) }
    if first == nil { first = CMSampleBufferGetImageBuffer(sample) }
    input.append(sample)
  }
  input.markAsFinished()
  if reader.status == .failed { throw reader.error ?? NSError(domain: "edit", code: 3) }
  await writer.finishWriting()
  if writer.status != .completed { throw writer.error ?? NSError(domain: "edit", code: 2) }

  // Poster: the first frame (also the last), for "reduce motion".
  if let px = first {
    let ctx = CIContext()
    let image = CIImage(cvPixelBuffer: px)
    let cg = ctx.createCGImage(image, from: image.extent)!
    let dest = CGImageDestinationCreateWithURL(posterURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, cg, [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary)
    CGImageDestinationFinalize(dest)
  }
  let bytes = (try FileManager.default.attributesOfItem(atPath: outURL.path)[.size] as? NSNumber)?.intValue ?? 0
  print(String(format: "wrote %@ %dx%d, %.2f s, %d KB", outURL.lastPathComponent, Int(width), Int(height), length, bytes / 1024))
}

let done = DispatchSemaphore(value: 0)
Task {
  do { try await run() } catch { print("edit failed: \(error)"); exit(1) }
  done.signal()
}
done.wait()
