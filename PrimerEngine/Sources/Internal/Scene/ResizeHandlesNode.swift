import SceneKit
import CoreImage.CIFilterBuiltins

final class ResizeHandlesNode: SCNNode {
    
    private static let padding: Float = 0.02
    
    private let handles: [Swatch.Corner:HandleNode] = [
        .topLeft: HandleNode(assetName: "grabber.scnassets/grabber2.scn"),
        .topRight: HandleNode(assetName: "grabber.scnassets/grabber3.scn"),
        .bottomLeft: HandleNode(assetName: "grabber.scnassets/grabber4.scn"),
        .bottomRight: HandleNode(assetName: "grabber.scnassets/grabber5.scn")
    ]
    
    fileprivate func handleNode(for corner: Swatch.Corner) -> HandleNode {
        handles[corner]!
    }
    
    var topLeftPosition: SIMD3<Float> {
        get { handleNode(for: .topLeft).simdPosition }
        set { handleNode(for: .topLeft).simdPosition = newValue }
    }
    
    var topRightPosition: SIMD3<Float> {
        get { handleNode(for: .topRight).simdPosition }
        set { handleNode(for: .topRight).simdPosition = newValue }
    }
    
    var bottomLeftPosition: SIMD3<Float> {
        get { handleNode(for: .bottomLeft).simdPosition }
        set { handleNode(for: .bottomLeft).simdPosition = newValue }
    }
    
    var bottomRightPosition: SIMD3<Float> {
        get { handleNode(for: .bottomRight).simdPosition }
        set { handleNode(for: .bottomRight).simdPosition = newValue }
    }
    
    var activeGestureType: GestureType? = nil {
        didSet {
            updateHandles()
        }
    }

    override init() {
        super.init()
        for corner in Swatch.Corner.allCases {
            addChildNode(handleNode(for: corner))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateHandles() {
        for corner in Swatch.Corner.allCases {
            let node = handleNode(for: corner)
            if let gesture = activeGestureType {
                switch gesture {
                case .move:
                    node.state = .inactive
                case .resize(let activeHandle):
                    node.state = (activeHandle == corner) ? .active : .inactive
                case .pinch:
                    node.state = .inactive
                }
            } else {
                node.state = .normal
            }
        }
    }
    
}

fileprivate final class HandleNode: SCNNode {

    enum State: Equatable {
        case normal // no resize is in progress
        case active // a resize is in progress with this handle
        case inactive // a resize is in progress for a different handle
    }

    private static let handleScale: Float = 0.001
    private static let diffuseColor = colorToVec(UIColor.white)
    private static let emissionColor = colorToVec(UIColor.lightGray)
    private static let activeDiffuseColor = colorToVec(UIColor.blue)
    private static let activeEmissionColor = colorToVec(UIColor.blue)

    private static let animationDuration = CFTimeInterval(0.2)
    private static let animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

    private let assetNode: SCNNode

    var state: State = .normal {
        didSet {
            guard state != oldValue else { return }

            SCNTransaction.begin()
            SCNTransaction.animationDuration = Self.animationDuration
            SCNTransaction.animationTimingFunction = Self.animationTimingFunction
            updateColors()
            updateOpacity()
            SCNTransaction.commit()
        }
    }

    init(assetName: String) {
        let bundle = Bundle(for: HandleNode.self)
        guard let url = bundle.url(forResource: assetName, withExtension: nil),
            let scene = try? SCNScene(url: url, options: [:]),
            let assetNode = scene.rootNode.childNodes.first,
            let geom = assetNode.geometry else {
                fatalError("Failed to load asset: \(assetName)")
        }

        self.assetNode = assetNode
        super.init()

        let program = SCNProgram()
        program.vertexFunctionName = "resize_handle_vertex"
        program.fragmentFunctionName = "resize_handle_fragment"
        geom.program = program

        updateColors()
        updateOpacity()

        self.assetNode.scale = SCNVector3(Self.handleScale, Self.handleScale, Self.handleScale)
        addChildNode(assetNode)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateOpacity() {
        guard let geom = self.assetNode.geometry else {
            return
        }
        geom.setValue(Float(state == .inactive ? 0 : 1), forKey: "opacity")
    }

    private func updateColors() {
        guard let geom = self.assetNode.geometry else {
            return
        }
        switch state {
        case .normal:
            geom.setValue(Self.diffuseColor, forKey: "diffuseColor")
            geom.setValue(Self.emissionColor, forKey: "emissionColor")
        case .active:
            geom.setValue(Self.activeDiffuseColor, forKey: "diffuseColor")
            geom.setValue(Self.activeEmissionColor, forKey: "emissionColor")
        case .inactive:
            geom.setValue(Self.diffuseColor, forKey: "diffuseColor")
            geom.setValue(Self.emissionColor, forKey: "emissionColor")
        }
    }
}

fileprivate func colorToVec(_ color: UIColor) -> SCNVector4 {
    var red: CGFloat = CGFloat(0);
    var green: CGFloat = CGFloat(0);
    var blue: CGFloat = CGFloat(0);
    var alpha: CGFloat = CGFloat(1);
    if (!color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)) {
        print("Could not turn color into SCNVector4", color)
    }
    return SCNVector4(red, green, blue, alpha)
}


