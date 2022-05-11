import Foundation
import SceneKit
import UIKit


final class GridNode: SCNNode {
    
    private static let tileSize = 0.05 as Float
    private static let fadeDuration = CFTimeInterval(0.2)
    private static let fadeTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
    
    // TODO: Subsume `resizePlaneNode` into the grid node, and perhaps its material.
    private let resizePlane = SCNPlane(width: 1, height: 1)
    private let resizePlaneNode = SCNNode()
    
    var maskCenter = .zero as SIMD2<Float> {
        didSet {
            update()
        }
    }
    
    var size = Swatch.Size(width: 1, height: 1) {
        didSet {
            update()
        }
    }
    
    override public init() {
        super.init()
        
        let diffuseTex = UIImage(named: "grid-lines", in: Bundle(for: Self.self), compatibleWith: nil)!
        let transparentTex = UIImage(named: "grid-opacity", in: Bundle(for: Self.self), compatibleWith: nil)!

        let program = SCNProgram()
        program.vertexFunctionName = "grid_vertex"
        program.fragmentFunctionName = "grid_fragment"
        
        resizePlane.program = program
        resizePlane.setValue(SCNMaterialProperty(contents: diffuseTex), forKey:"diffuseTex")
        resizePlane.setValue(SCNMaterialProperty(contents: transparentTex), forKey:"transparentTex")
        resizePlane.setValue(Self.tileSize, forKey:"tileSize")
        resizePlane.setValue(SCNVector3(0, 0, 0), forKey:"swatchPosition")
        resizePlane.setValue(SCNVector3(1, 1, 0), forKey:"swatchScale")
        resizePlane.setValue(Float(0), forKey:"opacity")
        
        resizePlaneNode.geometry = resizePlane
        resizePlaneNode.categoryBitMask = ([.resizer] as SCNNode.CategorySet).rawValue
        resizePlaneNode.renderingOrder = -2
        addChildNode(resizePlaneNode)
        
        update()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func update() {
        let pos = SCNVector3(maskCenter.x, maskCenter.y, 0)
        let scl = SCNVector3(CGFloat(size.width), CGFloat(size.height), 1)
        resizePlaneNode.position = pos
        resizePlaneNode.scale = scl
        resizePlane.setValue(pos, forKey: "swatchPosition")
        resizePlane.setValue(scl, forKey: "swatchScale")
    }

    public func fadeIn() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = Self.fadeDuration
        SCNTransaction.animationTimingFunction = Self.fadeTimingFunction
        resizePlane.setValue(Float(1), forKey:"opacity")
        SCNTransaction.commit()
    }

    public func fadeOut() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = Self.fadeDuration
        SCNTransaction.animationTimingFunction = Self.fadeTimingFunction
        resizePlane.setValue(Float(0), forKey:"opacity")
        SCNTransaction.commit()
    }
}
