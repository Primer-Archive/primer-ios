import Metal
import MetalKit

fileprivate let kLoaderOptsSRGBOn: [MTKTextureLoader.Option : Any] = [MTKTextureLoader.Option.SRGB: true,
                                                                      MTKTextureLoader.Option.generateMipmaps: true,
                                                                      MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue),
                                                                      MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue)]
fileprivate let kLoaderOptsSRGBOff: [MTKTextureLoader.Option : Any] = [MTKTextureLoader.Option.SRGB: false,
                                                                       MTKTextureLoader.Option.generateMipmaps: true,
                                                                       MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue),
                                                                       MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue)]

// Represents a detailed model of a surface to be rendered
public struct LoadedMaterial {
        
    public var diffuse: Property
    public var ambientOcclusion: Property
    public var normal: Property
    public var metalness: Property
    public var roughness: Property
    public var displacement: Property
        
    public var usesBlending: Bool

    public var wallBlendContents: Property.Contents? {
        get {
            switch diffuse.contents {
            case .texture(texture: _, size: _):
                return nil
            default:
                return ambientOcclusion.contents
            }
        }
    }
    
    public init(
        diffuse: Property,
        ambientOcclusion: Property,
        normal: Property,
        metalness: Property,
        roughness: Property,
        displacement: Property,
        usesBlending: Bool
    ) {
        self.diffuse = diffuse
        self.ambientOcclusion = ambientOcclusion
        self.normal = normal
        self.metalness = metalness
        self.roughness = roughness
        self.displacement = displacement
        self.usesBlending = usesBlending
    }

}

extension LoadedMaterial {
    
    public struct Property {
        public var contents: Contents
        public var intensity: Double
        
        public init(contents: Contents, intensity: Double) {
            self.contents = contents
            self.intensity = intensity
        }
    }

}

extension LoadedMaterial.Property {
    
    public enum Contents {
        case none
        case constant(Double)
        case color(UIColor)
        case texture(texture: MTLTexture, size: TextureSize)
    }
    
}


extension Material {
    
    func load() -> LoadedMaterial {
        
        let device = MTLCreateSystemDefaultDevice()!
        let loader = MTKTextureLoader(device: device)
        
        return LoadedMaterial(
            diffuse: diffuse.load(textureLoader: loader),
            ambientOcclusion: ambientOcclusion.load(textureLoader: loader),
            normal: normal.load(textureLoader: loader, srgb: false),
            metalness: metalness.load(textureLoader: loader),
            roughness: roughness.load(textureLoader: loader),
            displacement: displacement.load(textureLoader: loader),
            usesBlending: usesBlending)
    }
    
}

extension Material.Property {
    func load(textureLoader: MTKTextureLoader, srgb: Bool = true) -> LoadedMaterial.Property {
        LoadedMaterial.Property(
            contents: contents.load(textureLoader: textureLoader, srgb: srgb),
            intensity: intensity)
    }
}

extension Material.Property.Contents {
    
    func load(textureLoader: MTKTextureLoader, srgb: Bool) -> LoadedMaterial.Property.Contents {
        switch self {
        case .none:
            return .none
        case .color(let color):
            return .color(color.uiColor)
        case .constant(let value):
            return .constant(value)
        case .texture(let imageReference):
            
            let texture: MTLTexture?
            
            switch imageReference {
            case .named(let name, let bundle):
                texture = try? textureLoader.newTexture(name: name, scaleFactor: 1.0, bundle: bundle)
            case .path(let path):
                let options = srgb ? kLoaderOptsSRGBOn : kLoaderOptsSRGBOff
                texture = try? textureLoader.newTexture(URL: URL(fileURLWithPath: path), options: options)
            }
            
            if let texture = texture {
                return .texture(texture: texture, size: TextureSize.meters(uniform: 1.0))
            } else {
                return .color(.red)
            }
        }
    }
    
}


extension CachedMaterial {
    
    func load() -> LoadedMaterial {
        material.load(cacheMap: cacheMap)
    }
    
}



extension MaterialModel {
    
    func load(cacheMap: [URL:URL] = [:]) -> LoadedMaterial {
        
        let device = MTLCreateSystemDefaultDevice()!
        let loader = MTKTextureLoader(device: device)
        
        return LoadedMaterial(
            diffuse: diffuse.load(textureLoader: loader, cacheMap: cacheMap),
            ambientOcclusion: ambientOcclusion.load(textureLoader: loader, cacheMap: cacheMap),
            normal: normal.load(textureLoader: loader, cacheMap: cacheMap, srgb: false),
            metalness: metalness.load(textureLoader: loader, cacheMap: cacheMap),
            roughness: roughness.load(textureLoader: loader, cacheMap: cacheMap),
            displacement: displacement.load(textureLoader: loader, cacheMap: cacheMap),
            usesBlending: usesBlending)
    }
    
}

extension MaterialModel.Property {
    
    func load(textureLoader: MTKTextureLoader, cacheMap: [URL:URL], srgb: Bool = true) -> LoadedMaterial.Property {
        LoadedMaterial.Property(
            contents: contents(textureLoader: textureLoader, cacheMap: cacheMap, srgb: srgb),
            intensity: intensity)
    }
    
    func contents(textureLoader: MTKTextureLoader, cacheMap: [URL:URL], srgb: Bool) -> LoadedMaterial.Property.Contents {
        switch self.content {
        case .inactive:
            return .none
        case .color(let color):
            return .color(color.uiColor)
        case .constant(let constant):
            return .constant(constant)
        case .texture(let url):
            let texture: MTLTexture
            do {
                let data: Data
                if let fileURL = cacheMap[url] {
                    data = try Data(contentsOf: fileURL)
                } else {
                    data = try Data(contentsOf: url)
                }
                let options = srgb ? kLoaderOptsSRGBOn : kLoaderOptsSRGBOff
                texture = try textureLoader.newTexture(data: data, options: options)
            } catch(let error) {
                print("Failed to load texture: \(error.localizedDescription)")
                return .color(.red)
            }
            
            return .texture(texture: texture, size: textureSize)
        }
    }
    
}
