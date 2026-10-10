import AVFoundation
import CoreImage
import Metal
import VWSpikeKernels

/// ARCH §13.2 `VWCompositor`, reduced: BGRA IOSurface/Metal source buffers,
/// `supportsHDRSourceFrames = false`, one Metal `CIContext` with colour management off, the
/// precompiled `-fcikernel` kernels, `k = round(compositionTime × fps)` evaluated at
/// `timeOfFrame(k)`, a `vwish.frame` stamp on every output buffer, and redraw-from-cache of the
/// last request's source buffers.
final class SpikeCompositor: NSObject, AVVideoCompositing {
  static let frameAttachmentKey = "vwish.frame" as CFString

  static let bgraAttributes: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_32BGRA],
    kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any](),
    kCVPixelBufferMetalCompatibilityKey as String: true,
  ]

  static let device: MTLDevice = MTLCreateSystemDefaultDevice()!

  /// Loaded once per process; nil means V-N9 failed (the kernel tests report why).
  static let kernels: SpikeKernels? = try? SpikeKernels()

  static func makeContext(software: Bool = false) -> CIContext {
    var options: [CIContextOption: Any] = [
      .workingColorSpace: NSNull(),
      .outputColorSpace: NSNull(),
      .cacheIntermediates: false,
    ]
    if software {
      options[.useSoftwareRenderer] = true
      return CIContext(options: options)
    }
    return CIContext(mtlDevice: device, options: options)
  }

  private let ciContext = SpikeCompositor.makeContext()
  private let renderQueue = DispatchQueue(label: "vw.spike.compositor", qos: .userInitiated)
  private let genLock = NSLock()
  private var generation = 0

  private struct Cache {
    var k: Int64
    var layers: [SpikePlan.Layer]
    var sources: [String: CVPixelBuffer]
    var state: CompositorState
    var size: CGSize
  }

  private var cache: Cache?  // renderQueue only
  private var redrawPool: CVPixelBufferPool?  // renderQueue only

  var sourcePixelBufferAttributes: [String: Any]? { Self.bgraAttributes }
  var requiredPixelBufferAttributesForRenderContext: [String: Any] { Self.bgraAttributes }
  var supportsWideColorSourceFrames: Bool { false }
  var supportsHDRSourceFrames: Bool { false }

  func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
    renderQueue.async { self.redrawPool = nil }
  }

  func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
    genLock.lock()
    let gen = generation
    genLock.unlock()
    renderQueue.async {
      self.genLock.lock()
      let cancelled = gen != self.generation
      self.genLock.unlock()
      if cancelled {
        request.finishCancelledRequest()
        return
      }
      do {
        request.finish(withComposedVideoFrame: try self.render(request))
      } catch {
        request.finish(with: error)
      }
    }
  }

  func cancelAllPendingVideoCompositionRequests() {
    genLock.lock()
    generation += 1
    genLock.unlock()
  }

  enum Failure: Error { case foreignInstruction, noBuffer }

  private func render(_ request: AVAsynchronousVideoCompositionRequest) throws -> CVPixelBuffer {
    guard let instruction = request.videoCompositionInstruction as? SpikeInstruction else {
      throw Failure.foreignInstruction
    }
    let state = instruction.state
    state.register(self)
    let plan = state.plan
    let k = Grid.frameIndexNearest(request.compositionTime, fps: plan.canvas.fps)
    let t = Grid.timeOfFrame(k, fps: plan.canvas.fps)
    let active = plan.activeLayers(at: t)
    var sources: [String: CVPixelBuffer] = [:]
    var missing: [String] = []
    var formats: [String: OSType] = [:]
    var transfers: [String: String] = [:]
    for layer in active {
      if let id = state.trackIDBySeq[layer.seq], let buffer = request.sourceFrame(byTrackID: id) {
        sources[layer.id] = buffer
        formats[layer.id] = CVPixelBufferGetPixelFormatType(buffer)
        let tf = CVBufferCopyAttachment(buffer, kCVImageBufferTransferFunctionKey, nil)
        transfers[layer.id] = tf.map { "\($0)" } ?? "nil"
      } else {
        missing.append(layer.id)
      }
    }
    guard let out = request.renderContext.newPixelBuffer() else { throw Failure.noBuffer }
    let started = CFAbsoluteTimeGetCurrent()
    let params = state.params
    try Self.renderComposite(
      context: ciContext, plan: plan, layers: active, sources: sources, look: params.look,
      blur: params.blur, size: request.renderContext.size, into: out)
    let ms = (CFAbsoluteTimeGetCurrent() - started) * 1000
    if state.stampFrames {
      CVBufferSetAttachment(out, Self.frameAttachmentKey, NSNumber(value: k), .shouldPropagate)
    }
    state.log.add(
      FrameRecord(
        k: k, compositionTime: request.compositionTime, active: active.map(\.id), missing: missing,
        surfaceID: Pixels.ioSurfaceID(out), renderMs: ms, sourceFormats: formats,
        sourceTransfer: transfers))
    cache = Cache(k: k, layers: active, sources: sources, state: state, size: request.renderContext.size)
    return out
  }

  /// Composites `layers` (bottom → top) onto the opaque background with colour management off.
  static func renderComposite(
    context: CIContext, plan: SpikePlan, layers: [SpikePlan.Layer], sources: [String: CVPixelBuffer],
    look: SpikeLook, blur: Float, size: CGSize, into out: CVPixelBuffer
  ) throws {
    let scale = size.width / CGFloat(plan.canvas.w)
    var image = CIImage(color: CIColor(red: 0, green: 0, blue: 0)).cropped(
      to: CGRect(origin: .zero, size: size))
    for layer in layers {
      guard let buffer = sources[layer.id] else { continue }
      var img = CIImage(cvPixelBuffer: buffer, options: [.colorSpace: NSNull()])
      if let kernels = kernels {
        img = kernels.applyLook(img, look)
        if blur > 0 { img = kernels.applyBlur(img, sigma: blur) }
      }
      let r = plan.placementRect(layer)
      let rect = CGRect(
        x: r.minX * scale, y: r.minY * scale, width: r.width * scale, height: r.height * scale)
      let sx = rect.width / img.extent.width
      let sy = rect.height / img.extent.height
      img = img.transformed(by: CGAffineTransform(scaleX: sx, y: sy))
        .transformed(by: CGAffineTransform(translationX: rect.minX, y: size.height - rect.maxY))
      image = img.composited(over: image)
    }
    let dest = CIRenderDestination(pixelBuffer: out)
    dest.colorSpace = nil
    let task = try context.startTask(toRender: image, to: dest)
    _ = try task.waitUntilCompleted()
  }

  // MARK: Redraw-from-cache (paused param patches, transients, editing modes, look stills)

  struct Redraw {
    var buffer: CVPixelBuffer
    var k: Int64
    var ms: Double
  }

  /// Re-renders the last request's frame from its cached source buffers with the state's current
  /// parameters, on the render queue, into a buffer from the compositor's own pool.
  func redrawFromCache() throws -> Redraw? {
    try renderQueue.sync {
      guard let c = cache else { return nil }
      let started = CFAbsoluteTimeGetCurrent()
      if redrawPool == nil {
        var pool: CVPixelBufferPool?
        var attrs = Self.bgraAttributes
        attrs[kCVPixelBufferPixelFormatTypeKey as String] = kCVPixelFormatType_32BGRA
        attrs[kCVPixelBufferWidthKey as String] = Int(c.size.width)
        attrs[kCVPixelBufferHeightKey as String] = Int(c.size.height)
        CVPixelBufferPoolCreate(nil, nil, attrs as CFDictionary, &pool)
        redrawPool = pool
      }
      var pb: CVPixelBuffer?
      CVPixelBufferPoolCreatePixelBuffer(nil, redrawPool!, &pb)
      guard let out = pb else { throw Failure.noBuffer }
      let params = c.state.params
      try Self.renderComposite(
        context: ciContext, plan: c.state.plan, layers: c.layers, sources: c.sources,
        look: params.look, blur: params.blur, size: c.size, into: out)
      CVBufferSetAttachment(out, Self.frameAttachmentKey, NSNumber(value: c.k), .shouldPropagate)
      return Redraw(buffer: out, k: c.k, ms: (CFAbsoluteTimeGetCurrent() - started) * 1000)
    }
  }

  /// The cached source buffers of the last request (HDR inspection).
  func cachedSources() -> [String: CVPixelBuffer] {
    renderQueue.sync { cache?.sources ?? [:] }
  }

  static func frameStamp(_ buffer: CVPixelBuffer) -> Int64? {
    guard let n = CVBufferCopyAttachment(buffer, frameAttachmentKey, nil) as? NSNumber else {
      return nil
    }
    return n.int64Value
  }
}
