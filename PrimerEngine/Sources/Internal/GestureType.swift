public enum GestureType: Hashable {
    case move
    case pinch
    case resize(corner: Swatch.Corner)
}
