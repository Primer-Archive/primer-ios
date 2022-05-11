import SceneKit
import ARKit
import Metal

final class SceneController {
    var material: CachedMaterial? = nil {
        didSet {
            guard material != oldValue else { return }
            updateMaterial()
        }
    }
    
    var swatch: Swatch? = nil {
        didSet {
            guard swatch != oldValue else { return }
            updateSwatch()
        }
    }
    
    var placementSwatch: Swatch? = nil {
        didSet {
            guard placementSwatch != oldValue else { return }
            updatePlacementSwatch()
        }
    }

    var activeGestureType: GestureType? {
        get { swatchNode.activeGestureType }
        set { swatchNode.activeGestureType = newValue }
    }

    var shouldShowLoadingSpinner: Bool {
        get { swatchNode.shouldShowLoadingSpinner }
    }

    var swatchPos: SIMD3<Float> {
        get { return swatchNode.lastWorldPosition }
    }
    
    private let scene = SCNScene()
        
    public let swatchNode: SwatchNode
    
    private let worldGeometryNode = WorldGeometryNode()
    
    private let sceneView: CustomSceneView

    public let sceneLights: SceneLights
        
    init(sceneView: CustomSceneView) {
        self.sceneView = sceneView
        swatchNode = SwatchNode(sceneView: sceneView)
        sceneView.scene = scene
        sceneLights = SceneLights(sceneView: sceneView)
        sceneLights.setup()
        setupSceneView()
        updateMaterial()
        updateSwatch()
    }

    private func setupSceneView() {
        sceneView.antialiasingMode = .multisampling4X
        sceneView.rendersCameraGrain = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = true

        if !UIDevice.isGPUPowered() {
            sceneView.preferredFramesPerSecond = 30
        }

        scene.rootNode.addChildNode(swatchNode)
        scene.rootNode.addChildNode(worldGeometryNode)
    }

    func update(for renderer: SCNSceneRenderer, intensity: CGFloat, temperature: CGFloat) {
        guard let frame = sceneView.session.currentFrame else {
            return
        }
        swatchNode.update(for: renderer)
        sceneLights.update(intensity: intensity, temperature: temperature, forward: swatchNode.lastWorldForward, position: swatchNode.lastWorldPosition, swatch: swatch)
        worldGeometryNode.update(for: frame)
    }

    private func updatePlacementSwatch() {
        swatchNode.placementSwatch = placementSwatch
    }

    private func updateSwatch() {
        swatchNode.swatch = swatch
        worldGeometryNode.swatch = swatch
    }

    private func updateMaterial() {
        swatchNode.material = material
    }

    func reset() {
        worldGeometryNode.reset()
        sceneLights.setup()
    }
}
