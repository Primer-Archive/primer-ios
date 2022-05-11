public struct TextureSize: Codable, Hashable {
    
    // In meters
    public var width: Double
    
    // In meters
    public var height: Double
    
    private init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    
    public static func inches(uniform length: Double) -> TextureSize {
        .inches(width: length, height: length)
    }
    
    public static func inches(width: Double, height: Double) -> TextureSize {
        TextureSize(
            width: width * 0.0254,
            height: height * 0.0254)
    }
    
    public static func meters(uniform length: Double) -> TextureSize {
        .meters(width: length, height: length)
    }
    
    public static func meters(width: Double, height: Double) -> TextureSize {
        TextureSize(
            width: width,
            height: height)
    }
}
