import SceneKit


extension SCNMaterial {

    func update(from loadedMaterial: LoadedMaterial, wallBlend: WallBlendPipeline? = nil, completionBlock: (() -> Void)? = nil) {
        SCNTransaction.begin()
        diffuse.update(from: loadedMaterial.diffuse)
        normal.update(from: loadedMaterial.normal)
        metalness.update(from: loadedMaterial.metalness)
        roughness.update(from: loadedMaterial.roughness)
        displacement.update(from: loadedMaterial.displacement)
        if let wb = wallBlend {
            wb.sourceContents = loadedMaterial.wallBlendContents
            ambientOcclusion.contents = wb.blendedTexture
            ambientOcclusion.intensity = 1.0
        } else {
            ambientOcclusion.update(from: loadedMaterial.ambientOcclusion)
        }
        SCNTransaction.completionBlock = completionBlock
        SCNTransaction.commit()
    }
    
}

extension SCNMaterialProperty {
    
    fileprivate func update(from property: LoadedMaterial.Property) {
        switch property.contents {
        case .none:
            self.contents = nil
        case .color(let color):
            self.contents = nil
            self.contents = color
        case .texture(let texture, _):
            self.contents = texture
        case .constant(let value):
            self.contents = nil
            self.contents = NSNumber(value:value)
        }
        intensity = CGFloat(property.intensity)
    }
    
}

