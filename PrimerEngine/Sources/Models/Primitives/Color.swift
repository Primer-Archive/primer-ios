import SwiftUI
import UIKit

public struct Color: Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double
    
    public init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
}

extension Color {
    
    public var uiColor: UIColor {
        UIColor(
            red: CGFloat(red),
            green: CGFloat(green),
            blue: CGFloat(blue),
            alpha: CGFloat(opacity)
        )
    }
    
    public var swiftUIColor: SwiftUI.Color {
        .init(red: red, green: green, blue: blue, opacity: opacity)
    }
    
}

extension Color {
    
    public static let red = Color(red: 1.0, green: 0.0, blue: 0.0)
    public static let green = Color(red: 0.0, green: 1.0, blue: 0.0)
    public static let blue = Color(red: 0.0, green: 0.0, blue: 1.0)
    public static let black = Color(red: 0.0, green: 0.0, blue: 0.0)
    public static let white = Color(red: 1.0, green: 1.0, blue: 1.0)
    
}
