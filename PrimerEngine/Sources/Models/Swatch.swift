import SceneKit
import simd

public struct Swatch: Equatable {
    
    // The original mount point
    public var position: SIMD3<Float>
    
    // The angle (heading) of the wall
    public var angle: Float
    
    // The translation on the wall (from the original mount point) of the swatch
    public var translation: SIMD2<Float> = .zero

    public var size: Size
    
    public init(position: SIMD3<Float>, angle: Float, size: Size) {
        self.position = position
        self.angle = angle
        self.size = size
    }
    
    // The mounting point on the wall
    public var mountPointTransform: simd_float4x4 {
        let translate = simd_float4x4(SCNMatrix4MakeTranslation(position.x, position.y, position.z))
        let headingRotation = simd_float4x4(SCNMatrix4MakeRotation(angle, 0.0, 1.0, 0.0))
        return simd_mul(translate, headingRotation)
    }
    
    // Represents a plane where positive Y is the normal of the mounted wall
    public var planeTransform: simd_float4x4 {
        let rotate = simd_float4x4(SCNMatrix4MakeRotation(0.5 * .pi, 1.0, 0.0, 0.0))
        return simd_mul(mountPointTransform, rotate)
    }
    
    // Converts a point in world space to the closest point on the plane
    public func intersectingLocalPositionOnPlane(for worldPosition: SIMD3<Float>) -> Position {
        // Use the inverse to move to local coordinates
        let planePoint = simd_mul(mountPointTransform.inverse, SIMD4(worldPosition, 1.0))
        return Position(x: planePoint.x, y: planePoint.y)
    }
    
    // Converts a point on the plane to a point in world space
    public func worldPosition(for localPosition: Position) -> SIMD3<Float> {
        let globalLocation = simd_mul(mountPointTransform, SIMD4(localPosition.x, localPosition.y, 0.0, 1.0))
        return SIMD3(globalLocation.x, globalLocation.y, globalLocation.z)
    }
    
    public func worldPosition(for localPosition: Position, xOffset: Float, yOffset: Float) -> SIMD3<Float> {
        let globalLocation = simd_mul(mountPointTransform, SIMD4(localPosition.x + xOffset, localPosition.y + yOffset, 0.0, 1.0))
        return SIMD3(globalLocation.x, globalLocation.y, globalLocation.z)
    }
    
    // Relative to the mount point
    public var localSwatchRectangle: Rectangle {
        return Rectangle(
            position: Position(
                x: translation.x,
                y: translation.y),
            size: size)
    }
    
    public var localResizeHandlesRectangle: Rectangle {
        localSwatchRectangle.inset(by: -0.02)
    }
    
}

extension Swatch {
    
    // Represents a two-dimentional location on the mounted plane
    public struct Position: Hashable {
        public var x: Float
        public var y: Float
        
        public var simd: SIMD2<Float> {
            SIMD2(x, y)
        }
        
        public func boundingCircle(radius: Float) -> Circle {
            Circle(
                position: self,
                radius: radius)
        }
        
        public func distance(to otherPosition: Position) -> SIMD2<Float> {
            SIMD2(otherPosition.x - x, otherPosition.y - y)
        }
    }
    
    // Represents a two-dimensional size on the mounted plane
    public struct Size: Hashable {
        public var width: Float
        public var height: Float
        
        public var simd: SIMD2<Float> {
            SIMD2(width, height)
        }
    }
    
    // Represents a circle within the mounted plane
    public struct Circle: Hashable {
        public var position: Position
        public var radius: Float
        
        public func contains(position: Position) -> Bool {
            let distance = self.position.distance(to: position)
            let lengthSquared = distance.x*distance.x + distance.y*distance.y
            return sqrt(lengthSquared) < radius
        }
    }
    
    public enum Corner: Hashable, CaseIterable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        
        public var alignment: Alignment {
            switch self {
            case .topLeft:
                return .topLeft
            case .topRight:
                return .topRight
            case .bottomLeft:
                return .bottomLeft
            case .bottomRight:
                return .bottomRight
            }
        }
    }

    
}

extension Swatch {
    
    public struct Rectangle: Hashable {
        
        public var position: Position
        public var size: Size
        
        public subscript(horizontalAlignment: HorizontalAlignment) -> Float {
            switch horizontalAlignment {
            case .left:
                return position.x - size.width/2.0
            case .center:
                return position.x
            case .right:
                return position.x + size.width/2.0
            }
        }
        
        public subscript(verticalAlignment: VerticalAlignment) -> Float {
            switch verticalAlignment {
            case .top:
                return position.y + size.height/2.0
            case .center:
                return position.y
            case .bottom:
                return position.y - size.height/2.0
            }
        }
        
        public subscript(alignment: Alignment) -> Position {
            return Position(
                x: self[alignment.horizontal],
                y: self[alignment.vertical])
        }
        
        public subscript(corner corner: Corner) -> Position {
            return self[corner.alignment]
        }
        
        public func inset(by length: Float) -> Rectangle {
            Rectangle(
                position: position,
                size: Size(
                    width: size.width - (length * 2.0),
                    height: size.height - (length * 2.0)))
        }
    }
    
}

extension Swatch {
    
    // Represents a horizontal position
    public enum HorizontalAlignment: Hashable, CaseIterable {
        case left
        case center
        case right
    }

    public enum VerticalAlignment: Hashable, CaseIterable {
        case top
        case center
        case bottom
    }

    public struct Alignment: Hashable {
        
        public var horizontal: HorizontalAlignment
        public var vertical: VerticalAlignment
        
        public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
            self.horizontal = horizontal
            self.vertical = vertical
        }
        
        public static let topLeft = Alignment(horizontal: .left, vertical: .top)
        public static let top = Alignment(horizontal: .center, vertical: .top)
        public static let topRight = Alignment(horizontal: .right, vertical: .top)
        
        public static let left = Alignment(horizontal: .left, vertical: .center)
        public static let center = Alignment(horizontal: .center, vertical: .center)
        public static let right = Alignment(horizontal: .right, vertical: .center)

        public static let bottomLeft = Alignment(horizontal: .left, vertical: .bottom)
        public static let bottom = Alignment(horizontal: .center, vertical: .bottom)
        public static let bottomRight = Alignment(horizontal: .right, vertical: .bottom)
    }
    
}


