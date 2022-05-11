// Represents a detailed model of a surface to be rendered
public struct Material: Equatable {
        
    public var diffuse: Property
    public var ambientOcclusion: Property
    public var normal: Property
    public var metalness: Property
    public var roughness: Property
    public var displacement: Property
    
    public var textureSize: TextureSize? = nil
    
    public var usesBlending: Bool
        
    public init(
        diffuse: Property,
        ambientOcclusion: Property,
        normal: Property,
        metalness: Property,
        roughness: Property,
        displacement: Property,
        textureSize: TextureSize?,
        usesBlending: Bool
    ) {
        self.diffuse = diffuse
        self.ambientOcclusion = ambientOcclusion
        self.normal = normal
        self.metalness = metalness
        self.roughness = roughness
        self.displacement = displacement
        self.textureSize = textureSize
        self.usesBlending = usesBlending
    }
    
    public init(color: Color) {
        self = Material(
            diffuse: .color(color),
            ambientOcclusion: .none,
            normal: .none,
            metalness: .none,
            roughness: .none,
            displacement: .none,
            textureSize: nil,
            usesBlending: false)
    }
    
    public static var plain: Material {
        Material(color: .white)
    }
    
}

extension Material {
    
    public struct Property: Equatable {
        
        public var contents: Contents = .none
        public var intensity: Double = 1.0
        
        public init(contents: Contents, intensity: Double) {
            self.contents = contents
            self.intensity = intensity
        }
        
        public static var none: Property {
            Property(contents: .none, intensity: 1.0)
        }
        
        public static func constant(_ value: Double) -> Property {
            Property(contents: .constant(value), intensity: 1.0)
        }

        public static func color(_ color: Color) -> Property {
            Property(contents: .color(color), intensity: 1.0)
        }
        
        public static func texture(_ reference: ImageReference, intensity: Double = 1.0) -> Property {
            Property(contents: .texture(reference), intensity: intensity)
        }
        

        
    }

}

extension Material.Property {
    
    public enum Contents: Equatable {
        case none
        case constant(Double)
        case color(Color)
        case texture(ImageReference)
    }
    
}
