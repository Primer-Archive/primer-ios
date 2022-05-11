import SceneKit
import ARKit

final class WorldGeometryNode: SCNNode {
    
    var swatch: Swatch?
    
    private var geometryNodes: [SCNNode] = []

    private let program: SCNProgram
    private let customMaterialLines: SCNMaterial
    private let customMaterialDepth: SCNMaterial

    override public init() {
        self.program = SCNProgram()
        self.customMaterialLines = SCNMaterial()
        self.customMaterialDepth = SCNMaterial()
        super.init()

        self.program.vertexFunctionName = "world_geometry_vertex"
        self.program.fragmentFunctionName = "world_geometry_fragment"

        self.customMaterialLines.writesToDepthBuffer = true
        self.customMaterialLines.fillMode = .lines
        self.customMaterialLines.program = program

        self.customMaterialDepth.writesToDepthBuffer = true
        self.customMaterialDepth.fillMode = .fill
        self.customMaterialDepth.program = program
        self.customMaterialDepth.colorBufferWriteMask = []
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(for frame: ARFrame) {
        updateGeometryNodes(for: frame)
    }
    
    private func updateGeometryNodes(for frame: ARFrame) {
        reset()

        guard #available(iOS 13.4, *) else {
            return
        }
        let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }

        meshAnchors.forEach({ meshAnchor in
            let geometry = SCNGeometry(arMeshGeometry: meshAnchor.geometry)
            geometry.materials = [self.swatch == nil ? self.customMaterialLines : self.customMaterialDepth]
            //geometry.program = self.program
            
            let node = SCNNode(geometry: geometry)
            
            // Render world geometry nodes first, so that we can impact the depth buffer first
            node.renderingOrder = -1

            node.simdTransform = meshAnchor.transform
            addChildNode(node)
            
            geometryNodes.append(node)
        })
    }
    
    func reset() {
        geometryNodes.forEach { node in
            node.removeFromParentNode()
        }
        geometryNodes = []
    }
}

extension SCNGeometry {
    @available(iOS 13.4, *)
    convenience init(arMeshGeometry: ARMeshGeometry) {
        let vertexSource = SCNGeometrySource(arGeometrySource: arMeshGeometry.vertices, semantic: .vertex)
        let normalSource = SCNGeometrySource(arGeometrySource: arMeshGeometry.normals, semantic: .normal)
        let element = SCNGeometryElement(arGeometryElement: arMeshGeometry.faces)
        self.init(sources: [vertexSource, normalSource], elements: [element])
    }

}
extension SCNGeometrySource {
    @available(iOS 13.4, *)
    convenience init(arGeometrySource: ARGeometrySource, semantic: SCNGeometrySource.Semantic) {
        self.init(
            buffer: arGeometrySource.buffer,
            vertexFormat: arGeometrySource.format,
            semantic: semantic,
            vertexCount: arGeometrySource.count,
            dataOffset: arGeometrySource.offset,
            dataStride: arGeometrySource.stride)
    }
}

extension SCNGeometryElement {
    @available(iOS 13.4, *)
    convenience init(arGeometryElement: ARGeometryElement) {
        let buffer = arGeometryElement.buffer
        let data = Data(bytes: buffer.contents(), count: buffer.length)
        let type: SCNGeometryPrimitiveType = arGeometryElement.primitiveType == .triangle ? .triangles : .line
        self.init(
            data: data,
            primitiveType: type,
            primitiveCount: arGeometryElement.count,
            bytesPerIndex: arGeometryElement.bytesPerIndex)
    }
}
