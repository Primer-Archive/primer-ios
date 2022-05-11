import ARKit

/// An `ARSCNView` with local swatch shading support. This view also permits interaction with its Metal framebuffer outside of render passes.
final class CustomSceneView: ARSCNView {
    
    // MARK: Creating a Custom Scene View
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect, options: [String: Any]? = nil) {
        super.init(frame: frame, options: options)
        
        let customLayer = layer as! CustomMetalLayer
        customLayer.framebufferOnly = false
        customLayer.sceneView = self
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Getting the Frame Information
    
    /// The contents of the scene view's frame.
    public var frameContents: MTLTexture? = nil
    
    /// The size of the scene view's frame.
    public var frameSize: CGSize = CGSize(width: 0, height: 0)
    
    // MARK: Managing the View
    
    override class var layerClass: AnyClass {
        get { CustomMetalLayer.self }
    }
}

/// A Metal layer that references its current drawable.
///
/// This is currently used to accumulate rendered frames for video recording.
private final class CustomMetalLayer: CAMetalLayer {
    public var sceneView: CustomSceneView?
    
    // MARK: Obtaining a Metal Drawable
    
    override func nextDrawable() -> CAMetalDrawable? {
        let nextDrawable = super.nextDrawable()
        
        self.sceneView?.frameContents = nextDrawable?.texture
        self.sceneView?.frameSize = self.drawableSize
        
        return nextDrawable
    }
    
}
