import Foundation
import AVFoundation
import CoreImage
import Accelerate
import UIKit
import Sentry

fileprivate let kMaxWaitTickCount = 10

final class MetalVideoRecorder {
    
    private enum State {
        case inactive
        case active(RecordingSession)
        
        var isActive: Bool {
            if case .active = self {
                return true
            } else {
                return false
            }
        }
    }
        
    private var state = State.inactive
    
    var isActive: Bool {
        state.isActive
    }
    
    var isReadyForTexture: Bool {
        isActive && !isFinishing
    }
    
    var isFinishing: Bool {
        guard case .active(let session) = state else {
            return false
        }
        return session.state == .finishing
    }

    init() {}
    
    @discardableResult
    func startRecording(width: Int, height: Int, selectedProduct: ProductModel?, encodeOnGPU: Bool) -> Bool {
        precondition(!isActive)
        
        let session: RecordingSession
        
        do {
            session = try RecordingSession(width: width,
                                           height: height,
                                           selectedProduct: selectedProduct, encodeOnGPU: encodeOnGPU)
        } catch {
            print("Recording session initialization error: \(error)")
            return false
        }
                
        state = .active(session)
        return true
    }

    func endRecording(_ completionHandler: @escaping (URL?) -> ()) {
        switch state {
        case .inactive:
            let event = Event(level: .error)
            event.message = "Cannot end recording while the recorder is inactive"
            Client.shared?.send(event: event, completion: nil)
        case .active(let session):
            session.endRecording { url in
                self.state = .inactive
                completionHandler(url)
            }
        }
    }

    func writeFrame(forTexture texture: MTLTexture) {
        switch state {
        case .inactive:
            let event = Event(level: .error)
            event.message = "Cannot write a frame while the recorder is not in a recording state"
            Client.shared?.send(event: event, completion: nil)
        case .active(let session):
            session.writeFrame(forTexture: texture)
        }
    }
}

enum RecordingSessionError: Error {
    case metalDeviceError
    case metalCommandQueueError
    case textureCacheError
}



fileprivate final class RecordingSession {
    
    let width: Int
    let height: Int
    private let selectedProduct: ProductModel?
    
    private var lastPresentationTime: CMTime? = nil
    
    private (set) var state: RecordingState
    private (set) var startTime: TimeInterval

    private let overlayImage: CIImage
    
    let outputFileURL: URL
    let assetWriter: AVAssetWriter
    let assetWriterVideoInput: AVAssetWriterInput
    let assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor
    
    let useGPU: Bool
    let commandQueue: MTLCommandQueue
    let metalTextureCache: CVMetalTextureCache

    let ciContext = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
    
    var inFlightTextures: [CMTimeValue: MTLTexture] = [:]

    private let videoFrameQueue = DispatchQueue(label: "video-frame-queue", qos: .utility)

    enum RecordingState: Equatable {
        case waitingForFirstFrame
        case writing(firstFrameTime: TimeInterval)
        case finishing
    }
    
    init(width: Int, height: Int, selectedProduct: ProductModel?, encodeOnGPU: Bool) throws {
        self.width = width
        self.height = height
        self.selectedProduct = selectedProduct
        
        state = .waitingForFirstFrame
        startTime = CACurrentMediaTime()
        
        let tempDirectoryPath = NSTemporaryDirectory()
        let filename = UUID().uuidString
        outputFileURL = URL(fileURLWithPath: tempDirectoryPath).appendingPathComponent("\(filename).m4v")
                
        assetWriter = try AVAssetWriter(outputURL: outputFileURL, fileType: .m4v)

        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]

        assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String : width,
            kCVPixelBufferHeightKey as String : height ]

        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: assetWriterVideoInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes)

        assetWriter.add(assetWriterVideoInput)
        
        let overlayView = WaterMarkView(product: selectedProduct!, width: width, height: height)
        overlayView.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        overlayView.layoutIfNeeded()
        
        let overlayFormat = UIGraphicsImageRendererFormat()
        overlayFormat.scale = 1.0
        overlayFormat.opaque = false
        let overlayRenderer = UIGraphicsImageRenderer(size: CGSize(width: CGFloat(width), height: CGFloat(height)), format: overlayFormat)
        let overlayImage = overlayRenderer.image { ctx in
            overlayView.layer.render(in: ctx.cgContext)
        }
                
        self.overlayImage = CIImage(cgImage: overlayImage.cgImage!)

        self.useGPU = encodeOnGPU

        guard let device = MTLCreateSystemDefaultDevice() else {
            throw RecordingSessionError.metalDeviceError
        }

        guard let commandQueue = device.makeCommandQueue() else {
            throw RecordingSessionError.metalCommandQueueError
        }
        self.commandQueue = commandQueue

        var cache: CVMetalTextureCache?
        let ret = CVMetalTextureCacheCreate(nil, nil, device, nil, &cache)
        guard ret == kCVReturnSuccess else {
            print("CVMetalTextureCacheCreate error return: \(ret)")
            throw RecordingSessionError.textureCacheError
        }
        self.metalTextureCache = cache!
    }
    
    func endRecording(_ completionHandler: @escaping (URL?) -> Void) {
        switch state {
        case .waitingForFirstFrame:
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        case .writing:
            assetWriterVideoInput.markAsFinished()
            assetWriter.finishWriting(completionHandler: {
                DispatchQueue.main.async {
                    completionHandler(self.outputFileURL)
                }
            })
            state = .finishing
        case .finishing:
            let event = Event(level: .error)
            event.message = "Cannot end recording while the recorder is already finishing a recording"
            Client.shared?.send(event: event, completion: nil)
        }
    }
    
    func writeFrame(forTexture texture: MTLTexture) {
        assert(texture.width == width)
        assert(texture.height == height)
        
        switch state {
        case .waitingForFirstFrame:
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMTime.zero)
            state = .writing(firstFrameTime: CACurrentMediaTime())
            writeFrame(texture: texture, frameTime: 0)
        case .writing(let firstFrameTime):
            let frameTime = CACurrentMediaTime() - firstFrameTime
            writeFrame(texture: texture, frameTime: frameTime)
            break
        case .finishing:
            let event = Event(level: .error)
            event.message = "Cannot write a frame while the recorder is in a finishing state"
            Client.shared?.send(event: event, completion: nil)
        }
    }
    
    private func writeFrame(texture: MTLTexture, frameTime: TimeInterval) {
        let presentationTime = CMTimeMakeWithSeconds(frameTime, preferredTimescale: 240)
        guard presentationTime != self.lastPresentationTime else {
            return
        }
        self.lastPresentationTime = presentationTime

        self.inFlightTextures[presentationTime.value] = texture

        guard let pixelBufferPool = assetWriterPixelBufferInput.pixelBufferPool else {
            print("Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame")
            return
        }
        
        // Get a fresh CVPixelBuffer from the pool that we can use to encode the frame
        // for submission into the AV writer system
        var maybePixelBuffer: CVPixelBuffer? = nil
        let status  = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &maybePixelBuffer)
        if status != kCVReturnSuccess {
            print("Could not get pixel buffer from asset writer input; dropping frame...")
            return
        }
        
        guard let pixelBuffer = maybePixelBuffer else { return }
        
        // Encode and enqueue the frame based on the capabilities of the system
        let encode = self.useGPU ? self.encodeFrameGPU : self.encodeFrameCPU
        encode(texture, pixelBuffer, presentationTime)
    }

    private func encodeFrameGPU(_ texture: MTLTexture, _ pixelBuffer: CVPixelBuffer, _ presentationTime: CMTime) {
        // First, flush out any extra metal textures that can be flushed from the texture cache
        CVMetalTextureCacheFlush(self.metalTextureCache, 0)

        // Create a CVMetalTexture backed by the given CVPixelBuffer
        var cvMetalTex: CVMetalTexture? = nil
        guard CVMetalTextureCacheCreateTextureFromImage(nil, self.metalTextureCache, pixelBuffer, nil, .bgra8Unorm_srgb, width, height, 0, &cvMetalTex) == kCVReturnSuccess else {
            print("CVMetalTextureCacheCreateTextureFromImage error; dropping frame...")
            return
        }

        // Get the actual MTLTexture from the CVMetalTexture backed by the CVPixelBuffer
        guard let tex = CVMetalTextureGetTexture(cvMetalTex!) else {
            print("CVMetalTextureGetTexture error; dropping frame...")
            return
        }

        // Create a structure where we can request that the GPU copy scene texture contents
        // to our new MTLTexture, which means the values will end up in our CVPixelBuffer
        guard let commandBuffer = self.commandQueue.makeCommandBuffer() else {
            print("Could not create metal command buffer; dropping frame...")
            return
        }
        guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
            print("Could not create blit command encoder; dropping frame...")
            return
        }
        blitEncoder.copy(from: texture, to: tex)
        blitEncoder.endEncoding()

        // Set an asychnronous completion handler that says, once the texture is copied,
        // enqueue it for submission into the video output
        commandBuffer.addCompletedHandler { buf in
            self.inFlightTextures.removeValue(forKey: presentationTime.value)
            self.videoFrameQueue.async {
                self.submitVideoFrame(pixelBuffer, presentationTime)
            }
        }

        // Pass the structure to the GPU for the work to be executed
        commandBuffer.commit()
    }

    private func encodeFrameCPU(_ texture: MTLTexture, _ pixelBuffer: CVPixelBuffer, _ presentationTime: CMTime) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])

        let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer)!

        // Use the bytes per row value from the pixel buffer since its stride may be rounded up to be 16-byte aligned
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)

        // Copy the texture from MTLTexture into the CVPixelBuffer via the CPU
        texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        self.inFlightTextures.removeValue(forKey: presentationTime.value)

        // The frame is copied into the pixelBuffer, so enqueue it for submission into the video output
        videoFrameQueue.async {
            self.submitVideoFrame(pixelBuffer, presentationTime)
        }
    }

    private func submitVideoFrame(_ pixelBuffer: CVPixelBuffer, _ presentationTime: CMTime) {
        // This function is called asynchronously, so we check the state to see if we should bail early
        if self.state == .finishing {
            return
        }

        // Do this composite overlay in a block so that the CIImage reference is dropped right away
        {
            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            let image = overlayImage.composited(over: CIImage(cvPixelBuffer: pixelBuffer))
            self.ciContext.render(image, to: pixelBuffer)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        }()

        // Wait for AV readiness...
        var tick = 0
        while !assetWriterVideoInput.isReadyForMoreMediaData {
            // If we finish writing while we're still waiting for AV readiness, bail early
            if self.state == .finishing {
                return
            }
            print("Asset writer is not yet ready for more media data...")

            // If we've waited N ticks already, it's too long and we need to skip this frame, so bail
            tick += 1
            if tick == kMaxWaitTickCount {
                print("Waited", kMaxWaitTickCount, "ticks to write a video frame but it was never ready; skipping frame...")
                return
            }
        }

        // OK, the image is composited, the AV system is ready for writing...let's write it!
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
        assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: presentationTime)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
    }
}

