import SceneKit
import ARKit

public enum Constants {}

extension Constants {
    public enum AppearanceTransition {
        static let duration: CFTimeInterval = 0.45
        static let timingMode: CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
    }
}

final class LoadingMaterial {
    var material: LoadedMaterial? = nil
}

final class SwatchNode: SCNNode {
    private static let defaultTilingInfo = SCNVector3(1, 1, 1)
    private static let defaultSwatchDimensions = SCNVector3(1, 1, 0)
    private static let minPolySegmentsPerSide: Int = 200
    private static let maxPolySegmentsPerSide: Int = 750
    private static let polysPerMeter: Float = Float(minPolySegmentsPerSide) / 0.4
    private static let resizeDebounceTime: TimeInterval = 0.25
    
    private let transformNode: SCNNode
    
    private let gridNode = GridNode()
    private let blendNode: SCNNode
    
    private let box: SCNBox
    private let boxNode: SCNNode
    private let surfaceShader: String
    
    private let placementBox: SCNBox
    private let placementNode: SCNNode
    
    private let resizeHandles = ResizeHandlesNode()

    private let wallBlend: WallBlendPipeline

    private let materialLoadingQueue = OperationQueue()
    
    var activeGestureType: GestureType? = nil {
        didSet {
            guard activeGestureType != oldValue else { return }
            activeGestureDidChange()
        }
    }
    
    var placementSwatch: Swatch? = nil {
        didSet {
            updatePlacementSwatch()
        }
    }
    
    var swatch: Swatch? = nil {
        didSet {
            updateSwatch()
            if oldValue == nil && swatch != nil {
                revealSwatch()
            } else if oldValue != nil && swatch == nil {
                hideSwatch()
            }
        }
    }

    var lastWorldPosition = SIMD3<Float>(0, 0, 0)
    var lastWorldForward = SIMD3<Float>(0, 1, 0)
    
    var material: CachedMaterial? = nil {
        didSet {
            updateMaterial()
        }
    }

    var blendDisabled: Bool = false {
        didSet {
            guard blendDisabled != oldValue else {
                return
            }
            updateMaterial()
        }
    }

    var blendActive: Bool = false

    var blendIntensity: Float {
        get { return wallBlend.intensity }
        set(value) { wallBlend.intensity = value }
    }

    var blendLighten: Float {
        get { return wallBlend.lighten }
        set(value) { wallBlend.lighten = value }
    }

    var shouldShowLoadingSpinner: Bool = true

    private var lastResizeTime: TimeInterval? = nil
    private var isFirstReveal: Bool = true
    private var hasDisplacement: Bool = false {
        didSet {
            if hasDisplacement != oldValue && lastResizeTime == nil {
                lastResizeTime = Date().timeIntervalSince1970
            }
        }
    }

    init(sceneView: CustomSceneView) {
        
        transformNode = SCNNode()
        box = SCNBox(width: 1.0, height: 1.0, length: 0.003, chamferRadius: 0.01)
        box.heightSegmentCount = 1
        box.widthSegmentCount = 1
        boxNode = SCNNode(geometry: box)
        blendNode = SCNNode()
        wallBlend = WallBlendPipeline(sceneView: sceneView)
        
        let placementProgram = SCNProgram()
        placementProgram.vertexFunctionName = "placement_swatch_vertex"
        placementProgram.fragmentFunctionName = "placement_swatch_fragment"
        
        placementBox = SCNBox(width: 1.0, height: 1.0, length: 0.001, chamferRadius: 0)
        placementBox.program = placementProgram
        placementBox.setValue(SCNMaterialProperty(contents: UIImage(named: "placeholderDiffuse")!), forKey: "diffuseTex")
        placementBox.setValue(SCNMaterialProperty(contents: UIImage(named: "placeholderMetalness")!), forKey: "metalnessTex")
        placementNode = SCNNode(geometry: placementBox)
        placementNode.name = "placeGeometry"
        placementNode.categoryBitMask = ([.swatch] as SCNNode.CategorySet).rawValue

        surfaceShader = try! String(contentsOf: Bundle.main.url(forResource: "SwatchSurface.metal", withExtension: "txt")!)
        
        super.init()
        boxNode.name = "swatchGeometry"
        boxNode.categoryBitMask = ([.swatch] as SCNNode.CategorySet).rawValue

        blendNode.position = SCNVector3(0, 0, -0.006)
        boxNode.addChildNode(blendNode)
        
        transformNode.addChildNode(gridNode)
        transformNode.addChildNode(boxNode)
        transformNode.addChildNode(placementNode)
        transformNode.addChildNode(resizeHandles)
        addChildNode(transformNode)

        box.firstMaterial = baseMaterial()

        let backProgram = SCNProgram()
        backProgram.vertexFunctionName = "back_swatch_vertex"
        backProgram.fragmentFunctionName = "back_swatch_fragment"
        
        let mat = SCNMaterial()
        mat.setValue(SCNMaterialProperty(contents: UIImage(named: "backTextureDiffuse")!), forKey: "diffuseTex")
        mat.setValue(SCNMaterialProperty(contents: UIImage(named: "backTextureMetalness")!), forKey: "metalnessTex")
        mat.setValue(SCNMaterialProperty(contents: UIImage(named: "backTextureRoughness")!), forKey: "roughnessTex")
        mat.program = backProgram
        
        //right edge
        box.materials.insert(mat, at: 1)
        
        //back of cube
        box.materials.insert(mat, at: 2)
        
        //left edge
        box.materials.insert(mat, at: 3)
        
        //top edge
        box.materials.insert(mat, at: 4)
        
        //bottom edge
        box.materials.insert(mat, at: 5)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func activeGestureDidChange() {
        if activeGestureType != nil {
            gridNode.fadeIn()
        } else {
            gridNode.fadeOut()
        }
        
        resizeHandles.activeGestureType = activeGestureType
    }

    func baseMaterial() -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.wrapS = .repeat
        mat.diffuse.wrapT = .repeat
        mat.ambientOcclusion.wrapS = .repeat
        mat.ambientOcclusion.wrapT = .repeat
        mat.normal.wrapS = .repeat
        mat.normal.wrapT = .repeat
        mat.metalness.wrapS = .repeat
        mat.metalness.wrapT = .repeat
        mat.roughness.wrapS = .repeat
        mat.roughness.wrapT = .repeat
        mat.displacement.wrapS = .repeat
        mat.displacement.wrapT = .repeat
        mat.isDoubleSided = false
        mat.isLitPerPixel = true
        mat.setValue(box.firstMaterial?.value(forKey: "revealPercent") ?? Float(0), forKey: "revealPercent")
        mat.setValue(Self.defaultTilingInfo, forKey: "tilingInfo")
        mat.setValue(Self.defaultSwatchDimensions, forKey: "swatchDimensions")
        mat.shaderModifiers = [
            SCNShaderModifierEntryPoint.surface : surfaceShader,
        ]
        return mat
    }

    func update(for renderer: SCNSceneRenderer) {
        debouncedSwatchSegmentResize()
        wallBlend.update()
    }

    private func debouncedSwatchSegmentResize() {
        guard let currentSwatch = swatch,
              let resizeTime = lastResizeTime else {
            return
        }
        let now = Date().timeIntervalSince1970
        if (now - resizeTime) < SwatchNode.resizeDebounceTime {
            return
        }
        lastResizeTime = nil
        var changed: Bool = false
        let heightSegmentCount = hasDisplacement ? min(max(Int(SwatchNode.polysPerMeter * currentSwatch.size.width), SwatchNode.minPolySegmentsPerSide), SwatchNode.maxPolySegmentsPerSide) : 1
        if box.heightSegmentCount != heightSegmentCount {
            box.heightSegmentCount = heightSegmentCount
            changed = true
        }
        let widthSegmentCount = hasDisplacement ? min(max(Int(SwatchNode.polysPerMeter * currentSwatch.size.height), SwatchNode.minPolySegmentsPerSide), SwatchNode.maxPolySegmentsPerSide) : 1
        if box.widthSegmentCount != widthSegmentCount {
            box.widthSegmentCount = widthSegmentCount
            changed = true
        }
        if changed {
            print("Set swatch poly count to \(box.widthSegmentCount)x\(box.heightSegmentCount)")
        }
    }
    
    private func updatePlacementSwatch() {
        if let swatch = placementSwatch {
            transformNode.isHidden = false
            placementNode.isHidden = false
            resizeHandles.isHidden = true
            boxNode.opacity = 0.0
            transformNode.simdTransform = swatch.mountPointTransform
            placementNode.scale.x = swatch.size.width
            placementNode.scale.y = swatch.size.height
            placementNode.position = SCNVector3(swatch.translation.x, swatch.translation.y, 0.0)
            gridNode.maskCenter = SIMD2(swatch.translation.x, swatch.translation.y)
            gridNode.size = Swatch.Size(width: swatch.size.width + 1, height: swatch.size.height + 0.8)
        } else {
            transformNode.isHidden = false
        }
    }
    
    @objc private func performRevealSwatch() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = Constants.AppearanceTransition.duration
        SCNTransaction.animationTimingFunction = Constants.AppearanceTransition.timingMode
        box.firstMaterial?.setValue(Float(1), forKey: "revealPercent")
        SCNTransaction.commit()
    }

    private func revealSwatch() {
        // First time we reveal has to compile in SceneKit, so delay 0.5 seconds in order to still show the animation
        if (isFirstReveal) {
            isFirstReveal = false
            self.perform(#selector(self.performRevealSwatch), with: nil, afterDelay: 0.5)
        } else {
            // Subsequent times perform the reveal immediately
            self.performRevealSwatch()
        }
    }

    private func hideSwatch() {
        box.firstMaterial?.setValue(Float(0), forKey: "revealPercent")
    }

    private func updateSwatch() {
        if material == nil {
            resizeHandles.isHidden = true
            placementNode.isHidden = true
            transformNode.isHidden = true
            return
        }

        if let swatch = swatch {
            resizeHandles.isHidden = false
            placementNode.isHidden = true
            transformNode.isHidden = false
            if(boxNode.opacity == 0.0){
                boxNode.runAction(SCNAction.fadeIn(duration: 0.2))
            }
            
            transformNode.simdTransform = swatch.mountPointTransform

            if abs(boxNode.scale.x - swatch.size.width) > .ulpOfOne || abs(boxNode.scale.y - swatch.size.height) > .ulpOfOne {
                boxNode.scale.x = swatch.size.width
                boxNode.scale.y = swatch.size.height
                lastResizeTime = Date().timeIntervalSince1970
            }

            boxNode.position = SCNVector3(swatch.translation.x, swatch.translation.y, 0.0)
            lastWorldPosition = boxNode.simdWorldPosition
            lastWorldForward = boxNode.simdWorldFront * -1.0

            wallBlend.swatchWorldTransform = blendNode.simdWorldTransform

            resizeHandles.topLeftPosition = SIMD3(swatch.localResizeHandlesRectangle[.topLeft].simd, 0.0)
            resizeHandles.topRightPosition = SIMD3(swatch.localResizeHandlesRectangle[.topRight].simd, 0.0)
            resizeHandles.bottomLeftPosition = SIMD3(swatch.localResizeHandlesRectangle[.bottomLeft].simd, 0.0)
            resizeHandles.bottomRightPosition = SIMD3(swatch.localResizeHandlesRectangle[.bottomRight].simd, 0.0)
            
            gridNode.maskCenter = SIMD2(swatch.translation.x, swatch.translation.y)
            gridNode.size = Swatch.Size(width: swatch.size.width + 1, height: swatch.size.height + 0.8)

            func updateMaterialTransform(modelProperty: MaterialModel.Property?, scnProperty: SCNMaterialProperty?, tilingAnchorPosition: MaterialModel.Property.TilingAnchor?) {
                var materialTransform: SCNMatrix4
                if let modelProperty = modelProperty, case .texture = modelProperty.content, let tilingAnchor = tilingAnchorPosition {
                    let scaleX = swatch.size.width / Float(modelProperty.textureSize.width)
                    let scaleY = swatch.size.height / Float(modelProperty.textureSize.height)

                    materialTransform = SCNMatrix4MakeScale(scaleX, scaleY, 1.0)
                    switch tilingAnchor {
                        case .center:
                            let translateX = scaleX / -2.0
                            let translateY = scaleY / -2.0
                            materialTransform = SCNMatrix4Translate(materialTransform, translateX, translateY, 0.0)
                            break;
                        case .topLeft:
                            break;
                    }
                }
                else {
                    materialTransform = SCNMatrix4Identity
                }
                if self.blendActive && modelProperty == material?.material.ambientOcclusion {
                    wallBlend.textureTransform = simd_float4x4(materialTransform)
                    scnProperty?.contentsTransform = SCNMatrix4Identity
                } else {
                    scnProperty?.contentsTransform = materialTransform
                }
            }

            box.materials.forEach { mat in
                updateMaterialTransform(modelProperty: material?.material.diffuse, scnProperty: mat.diffuse, tilingAnchorPosition: material?.material.tilingAnchor)
                updateMaterialTransform(modelProperty: material?.material.ambientOcclusion, scnProperty: mat.ambientOcclusion, tilingAnchorPosition: material?.material.tilingAnchor)
                updateMaterialTransform(modelProperty: material?.material.normal, scnProperty: mat.normal, tilingAnchorPosition: material?.material.tilingAnchor)
                updateMaterialTransform(modelProperty: material?.material.metalness, scnProperty: mat.metalness, tilingAnchorPosition: material?.material.tilingAnchor)
                updateMaterialTransform(modelProperty: material?.material.roughness, scnProperty: mat.roughness, tilingAnchorPosition: material?.material.tilingAnchor)
                updateMaterialTransform(modelProperty: material?.material.displacement, scnProperty: mat.displacement, tilingAnchorPosition: material?.material.tilingAnchor)
            }

            if let model = material?.material, case .texture = model.diffuse.content {
                box.firstMaterial?.setValue(SCNVector3(swatch.size.width, swatch.size.height, 0), forKey: "swatchDimensions")
                box.firstMaterial?.setValue(makeTilingInfo(kind: model.tilingAnchor, size: model.diffuse.textureSize), forKey: "tilingInfo")
            } else {
                box.firstMaterial?.setValue(Self.defaultSwatchDimensions, forKey: "swatchDimensions")
                box.firstMaterial?.setValue(Self.defaultTilingInfo, forKey: "tilingInfo")
            }
        } else {
            transformNode.isHidden = true
        }
    }

    private func updateMaterial() {
        shouldShowLoadingSpinner = true

        guard let material = material else {
            return
        }

        let loading = LoadingMaterial()

        // Create an operation to load the material asynchronously
        let operation = BlockOperation {
            loading.material = material.load()
        }

        // When the material is loaded, update the texture and swatch
        operation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                guard let mat = loading.material,
                      let nextMat = self?.baseMaterial() else { return }
                let blendOn = (mat.wallBlendContents != nil) && !(self?.blendDisabled ?? true)
                self?.blendActive = blendOn
                nextMat.update(from: mat, wallBlend: blendOn ? self?.wallBlend : nil) { [weak self] in
                    switch mat.displacement.contents {
                    case .texture(texture: _, size: _):
                        self?.hasDisplacement = true
                    default:
                        self?.hasDisplacement = false
                    }
                    self?.box.firstMaterial = nextMat
                    self?.updateSwatch()
                    let delay = (1.0 / 60.0) * 4.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: { [weak self] in
                        self?.shouldShowLoadingSpinner = false
                    })
                }
            }
        }

        // Cancel any existing operations so we can start loading
        // the newly-selected material right away
        materialLoadingQueue.cancelAllOperations()
        
        // Load the currently-selected material immediately
        materialLoadingQueue.addOperation(operation)
    }
    
}

func makeTilingInfo(kind: MaterialModel.Property.TilingAnchor, size: TextureSize) -> SCNVector3 {
    return SCNVector3(x: Float(size.width), y: Float(size.height), z: Float(kind == .center ? 0.0 : 1.0))
}
