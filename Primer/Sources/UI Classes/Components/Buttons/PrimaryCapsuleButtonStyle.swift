//
//  PrimaryCapsuleButtonStyle.swift
//  Primer
//

import SwiftUI

// MARK: - Button Style

public struct PrimaryCapsuleButtonStyle: ButtonStyle {
    
    private var leadingIconStyle: SystemIconStyle?
    private var buttonColor: ButtonColor?
    private var trailingImage: Image?
    private var font: Font? = nil
    private var height: CGFloat = 48.0
    private var radius: CGFloat?
    

    init(buttonColor: ButtonColor? = .blue, leadingIconStyle: SystemIconStyle? = nil, trailingImage: Image? = nil, font: Font? = nil, height: CGFloat = 48.0, cornerRadius: CGFloat? = nil) {
        self.buttonColor = buttonColor
        self.leadingIconStyle = leadingIconStyle
        self.trailingImage = trailingImage
        self.font = font
        self.height = height
        self.radius = cornerRadius
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        ButtonView(label: configuration.label, font: font, height: height, isPressed: configuration.isPressed, buttonColor: buttonColor, radius: radius, leadingIconStyle: leadingIconStyle)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Button View

fileprivate struct ButtonView<Label: View>: View {
    
    var label: Label
    var font: Font? = nil
    var height: CGFloat
    var isPressed: Bool
    var buttonColor: ButtonColor? = nil
    var radius: CGFloat?
    var leadingIconStyle: SystemIconStyle? = nil
    @Environment(\EnvironmentValues.isEnabled) private var isEnabled
    @Environment(\EnvironmentValues.colorScheme) private var colorScheme

    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            if let style = leadingIconStyle {
                Image(systemName: style.symbol)
                    .font(style.font)
                    .foregroundColor(style.foreground)
                    .frame(width: style.size.width, height: style.size.height)
            }
            label
                .frame(height: self.height)
                .foregroundColor(textColor)
                .font(self.font ?? Font.system(size: 15.0, weight: .medium, design: .rounded))
                .lineLimit(1)
            if let style = leadingIconStyle {
                Spacer()
                    .frame(minWidth: 0, maxWidth: style.size.width / 2)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .if(radius != nil) {
            $0.cornerRadius(radius ?? 0)
        }
        .if(radius == nil) {
            $0.clipShape(Capsule(style: .circular))
        }

        .overlay(RoundedRectangle(cornerRadius: radius ?? 0).stroke(lineWidth: (buttonColor?.hasOutline ?? false) ? 2 : 0).foregroundColor(buttonColor?.outline ?? .clear))
    }
    
    // MARK: - Background Color
    
    private var backgroundColor: SwiftUI.Color {
        
        guard isEnabled else {
            switch colorScheme {
            case .dark:
                return Color(white: 0.25)
            case .light:
                return Color(white: 0.75)
            @unknown default:
                fatalError()
            }
        }
        
        if let buttonColor = buttonColor {
            if isPressed {
                return buttonColor.selected
            } else {
                return buttonColor.background
            }
        } else {
            return Color.clear
        }

    }
    
    // MARK: - Text Color
    
    private var textColor: SwiftUI.Color {
        
        guard isEnabled else {
            switch colorScheme {
            case .dark:
                return Color(white: 0.5)
            case .light:
                return Color(white: 0.9)
            @unknown default:
                fatalError()
            }
        }
        
        if let buttonColor = buttonColor {
            return buttonColor.foreground
        } else {
            return BrandColors.white.color
        }
    }
}

// MARK: - Preview

struct ButtonView_Previews: PreviewProvider {
    
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            VStack(spacing: 20) {
                Button(action: {}, label: {
                    Text("Regular Button")
                }).buttonStyle(PrimaryCapsuleButtonStyle(cornerRadius: 10))
                
                Button(action: {}, label: {
                    Text("Semibold Button")
                }).buttonStyle(PrimaryCapsuleButtonStyle(font: LabelStyle.buttonSemibold.font, cornerRadius: 10))
                
                Button(action: {}, label: {
                    Text("Place Swatch")
                }).buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blueWhiteOutline, leadingIconStyle: .handTapLarge,font: LabelStyle.bodySemiboldWhite.font, cornerRadius: 30))
                .shadow(color: BrandColors.blue.color.opacity(0.3), radius: 5, x: 0.0, y: 0.0)
            }.padding()
        }
    }
}
