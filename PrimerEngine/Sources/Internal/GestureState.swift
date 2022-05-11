import CoreGraphics

enum GestureState: Equatable {
    case inactive
    case move(initialSwatch: Swatch, initialPointOnPlane: Swatch.Position, latestLocationInView: CGPoint)
    case resize(initialSwatch: Swatch, initialPointOnPlane: Swatch.Position, latestLocationInView: CGPoint, corner: Swatch.Corner)
    case pinch(initialSwatch: Swatch, latestScale: CGFloat)
}
