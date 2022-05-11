//
//  WallBlendPipeline.swift
//  PrimerEngine
//
//  Created by Eric Florenzano on 2/18/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

final class WallBlendPipeline {
    private let sceneView: CustomSceneView

    public var sourceTexture: MTLTexture? = nil {
        didSet {
            updateInternalTexture()
            updateRenderDescriptor()
        }
    }
    public var blendedTexture: MTLTexture? {
        get { return internalTexture }
    }

    private var data: WallBlendData
    private var internalTexture: MTLTexture? = nil
    private var renderDescriptor = MTLRenderPassDescriptor()

    private let device: MTLDevice
    private let library: MTLLibrary
    private let commandQueue: MTLCommandQueue
    private let renderPipelineState: MTLRenderPipelineState
    private let depthStencilState: MTLDepthStencilState
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer

    private lazy var textureCache = makeTextureCache()
    private var capturedImageTextureY: CVMetalTexture?
    private var capturedImageTextureCbCr: CVMetalTexture?

    public var swatchWorldTransform: simd_float4x4 {
        get { return data.swatchWorldTransform }
        set(value) { data.swatchWorldTransform = value }
    }

    public var textureTransform: simd_float4x4 {
        get { return data.textureTransform }
        set(value) { data.textureTransform = value }
    }

    public var intensity: Float {
        get { return data.blendPercent }
        set(value) { data.blendPercent = value }
    }

    public var lighten: Float {
        get { return data.blendLighten }
        set(value) { data.blendLighten = value }
    }

    public var sourceContents: LoadedMaterial.Property.Contents? = nil {
        didSet {
            guard let source = sourceContents else {
                data.color = simd_float4(0, 0, 0, 0)
                data.hasColor = 1
                sourceTexture = nil
                return
            }
            switch source {
            case .texture(texture: let tex, size: _):
                data.hasColor = 0
                sourceTexture = tex
            case .color(let color):
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                if color.getRed(&red, green: &green, blue: &blue, alpha: nil) {
                    data.color = simd_float4(Float(red), Float(green), Float(blue), 1.0)
                } else {
                    data.color = simd_float4(0, 0, 0, 0)
                }
                data.hasColor = 1
                sourceTexture = nil
            default:
                data.color = simd_float4(1, 1, 1, 0)
                data.hasColor = 1
                sourceTexture = nil
            }
        }
    }

    public init(sceneView: CustomSceneView) {
        self.sceneView = sceneView
        self.data = WallBlendData()
        self.data.blendPercent = 1.0
        self.data.blendLighten = 0.3

        self.device = MTLCreateSystemDefaultDevice()!
        self.library = self.device.makeDefaultLibrary()!
        self.commandQueue = self.device.makeCommandQueue()!
        self.renderPipelineState = makeRenderPipelineState(device: device, library: library)!
        self.depthStencilState = makeDepthStencilState(device: device)!
        self.vertexBuffer = makeVertexBuffer(device: device)!
        self.indexBuffer = makeIndexBuffer(device: device)!
    }

    func makeTextureCache() -> CVMetalTextureCache {
        var cache: CVMetalTextureCache!
        CVMetalTextureCacheCreate(nil, nil, device, nil, &cache)
        return cache
    }

    func update() {
        guard let frame = sceneView.session.currentFrame,
              let tex = internalTexture else {
            return
        }

        updateViewToCamera(frame: frame)
        updateTextures(frame: frame)

        guard let capturedImageYTex = capturedImageTextureY,
              let capturedImageY = CVMetalTextureGetTexture(capturedImageYTex),
              let capturedImageCbCrTex = capturedImageTextureCbCr,
              let capturedImageCbCr = CVMetalTextureGetTexture(capturedImageCbCrTex),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor) else {
            return
        }

        let projectionMatrix = frame.camera.projectionMatrix(for: .portrait, viewportSize: sceneView.frameSize, zNear: 0.01, zFar: 100)
        let viewMatrix = frame.camera.viewMatrix(for: .portrait)
        let viewProjectionMatrix = projectionMatrix * viewMatrix
        data.modelViewProjectionTransform = viewProjectionMatrix * data.swatchWorldTransform

        let sourceImage = sourceTexture
        var retainingTextures = [sourceImage, capturedImageY, capturedImageCbCr, tex]
        commandBuffer.addCompletedHandler { buffer in
            retainingTextures.removeAll()
        }

        encoder.setDepthStencilState(depthStencilState)
        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        withUnsafePointer(to: data) {
            let bytesLen = MemoryLayout<WallBlendData>.stride
            encoder.setVertexBytes($0, length: bytesLen, index: 1)
            encoder.setFragmentBytes($0, length: bytesLen, index: 0)
        }
        encoder.setFragmentTexture(sourceImage, index: 0)
        encoder.setFragmentTexture(capturedImageY, index: 1)
        encoder.setFragmentTexture(capturedImageCbCr, index: 2)
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        encoder.endEncoding()

        if let blit = commandBuffer.makeBlitCommandEncoder() {
            blit.generateMipmaps(for: tex)
            blit.endEncoding()
        }

        commandBuffer.commit()
    }

    func updateViewToCamera(frame: ARFrame) {
        let affine = frame.displayTransform(for: .portrait, viewportSize: sceneView.frameSize).inverted()
        data.viewToCamera.columns.0 = SIMD3<Float>(Float(affine.a), Float(affine.c), Float(affine.tx))
        data.viewToCamera.columns.1 = SIMD3<Float>(Float(affine.b), Float(affine.d), Float(affine.ty))
        data.viewToCamera.columns.2 = SIMD3<Float>(0, 0, 1)
    }

    func updateTextures(frame: ARFrame) {
        capturedImageTextureY = makeTexture(fromPixelBuffer: frame.capturedImage, pixelFormat: .r8Unorm, planeIndex: 0)
        capturedImageTextureCbCr = makeTexture(fromPixelBuffer: frame.capturedImage, pixelFormat: .rg8Unorm, planeIndex: 1)
    }

    func makeTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)

        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)

        if status != kCVReturnSuccess {
            texture = nil
        }

        return texture
    }

    private func updateInternalTexture() {
        var width: Int
        var height: Int
        if let tex = sourceTexture {
            width = Int(tex.width)
            height = Int(tex.height)
        } else {
            width = 1024
            height = 1024
        }
        let textureDescriptor: MTLTextureDescriptor = .texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: width,
            height: height,
            mipmapped: true
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        internalTexture = device.makeTexture(descriptor: textureDescriptor)
    }

    private func updateRenderDescriptor() {
        guard let tex = internalTexture else {
            return
        }
        renderDescriptor.renderTargetWidth = tex.width
        renderDescriptor.renderTargetHeight = tex.height
        renderDescriptor.colorAttachments[0].texture = tex
        renderDescriptor.colorAttachments[0].loadAction = .clear
        renderDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 0)
        renderDescriptor.colorAttachments[0].storeAction = .store
    }
}

fileprivate func makeRenderPipelineState(device: MTLDevice, library: MTLLibrary) -> MTLRenderPipelineState? {
    guard let vertexFunction = library.makeFunction(name: "wall_blend_vertex"),
          let fragmentFunction = library.makeFunction(name: "wall_blend_fragment") else {
            return nil
    }

    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].bufferIndex = 0
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.layouts[0].stride = MemoryLayout<SCNVector3>.stride

    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    descriptor.vertexDescriptor = vertexDescriptor
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
    descriptor.colorAttachments[0].isBlendingEnabled = true
    descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

    do {
        return try device.makeRenderPipelineState(descriptor: descriptor)
    } catch {
        print("Could not make render pipeline state: \(error)")
    }
    return nil
}

fileprivate func makeDepthStencilState(device: MTLDevice) -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    return device.makeDepthStencilState(descriptor: descriptor)
}

fileprivate func makeVertexBuffer(device: MTLDevice) -> MTLBuffer? {
    let vertices: [WallBlendVertex] = [
        WallBlendVertex(position: simd_float3(-1, -1, 0), texcoord0: simd_float2(0, 1)),
        WallBlendVertex(position: simd_float3(-1, 1, 0), texcoord0: simd_float2(0, 0)),
        WallBlendVertex(position: simd_float3(1, -1, 0), texcoord0: simd_float2(1, 1)),
        WallBlendVertex(position: simd_float3(1, 1, 0), texcoord0: simd_float2(1, 0))
    ]
    guard let buffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<WallBlendVertex>.stride * vertices.count, options: .storageModeShared) else {
        fatalError("Failed to create vertices MTLBuffer")
    }
    return buffer
}

fileprivate func makeIndexBuffer(device: MTLDevice) -> MTLBuffer? {
    let indices: [UInt16] = [0, 1, 2, 1, 2, 3]
    guard let buffer = device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count, options: .storageModeShared) else {
        fatalError("Failed to create vertices MTLBuffer")
    }
    return buffer
}
