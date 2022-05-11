//
//  BrandColors.swift
//  PrimerTwo
//
//  Modified by Adam Debreczeni on 04/1/20.
//  Copyright © 2019 Timothy Donnelly. All rights reserved.
//

import SwiftUI

/**
 Holds all of the brand colors. For colors that follow the naming style of `color-Toggle-color`, the first color named is applied in `light` mode and the second color named is applied in `dark` mode.
 */
enum BrandColors: String, CaseIterable {
    case grey
    case white
    case orange
    case navy
    case pink
    case yellow
    case sand
    case aqua
    case green
    case blue
    case eastBayBlue
    case black
    case solitudeGrey
    case solitudeGreyPressed
    case darkBlue
    case foreground
    case backgroundBW
    case softBackground
    case backgroundView
    case textfieldText
    case titleLabel
    case inputHeader
    case blueToggleAqua
    case blueToggleNavy
    case blueToggleWhite
    case greyToggleWhite
    case greyToggleSand
    case softGreyToggleSofterGrey
    case pinkToggleNavy
    case orangeTogglePink
    case buttonGrey
    case buttonGreyToggleSofterGrey
    case buttonGreyToggleSoftWhite
    case whiteToggleDeepBlue
    case softWhiteToggleGrey
    case darkBlueToggleBlack
    case darkBlueToggleWhite
    case whiteToggleDarkBlue
    case shadowedBackground
    case whiteToggleInactive
    case inactiveBackground
    case inactiveText
    case deepBlue
    case softSandToggleNavy
    case blueGrey
    case burntRed
}

extension BrandColors {
    var color: SwiftUI.Color {
        get {
            switch self {
            case .grey:
                return SwiftUI.Color("grey")
            case .white:
                return SwiftUI.Color("white")
            case .orange:
                return SwiftUI.Color("orange")
            case .navy:
                return SwiftUI.Color("navy")
            case .pink:
                return SwiftUI.Color("pink")
            case .yellow:
                return SwiftUI.Color("yellow")
            case .sand:
                return SwiftUI.Color("sand")
            case .aqua:
                return SwiftUI.Color("aqua")
            case .green:
                return SwiftUI.Color("green")
            case .blue:
                return SwiftUI.Color("blue")
            case .eastBayBlue:
                return SwiftUI.Color("eastBayBlue")
            case .black:
                return SwiftUI.Color("black")
            case .solitudeGrey:
                return SwiftUI.Color("solitudeGrey")
            case .solitudeGreyPressed:
                return SwiftUI.Color("solitudeGreyPressed")
            case .darkBlue:
                return SwiftUI.Color("darkBlue")
            case .foreground:
                return SwiftUI.Color("foreground")
            case .backgroundBW:
                return SwiftUI.Color("backgroundBW")
            case .backgroundView:
                return SwiftUI.Color("sandToggleDarkBlue")
            case .softBackground:
                return SwiftUI.Color("whiteToggleNavy")
            case .textfieldText:
                return SwiftUI.Color("textfieldText")
            case .titleLabel:
                return SwiftUI.Color("titleLabel")
            case .inputHeader:
                return SwiftUI.Color("inputHeaderText")
            case .blueToggleAqua:
                return SwiftUI.Color("blueToggleAqua")
            case .blueToggleNavy:
                return SwiftUI.Color("blueToggleNavy")
            case .blueToggleWhite:
                return SwiftUI.Color("blueToggleWhite")
            case .greyToggleWhite:
                return SwiftUI.Color("greyToggleWhite")
            case .greyToggleSand:
                return SwiftUI.Color("greyToggleSand")
            case .softGreyToggleSofterGrey:
                return SwiftUI.Color("softGreyToggleSofterGrey")
            case .pinkToggleNavy:
                return SwiftUI.Color("pinkToggleNavy")
            case .orangeTogglePink:
                return SwiftUI.Color("orangeTogglePink")
            case .buttonGrey:
                return SwiftUI.Color("buttonGrey")
            case .buttonGreyToggleSofterGrey:
                return SwiftUI.Color("buttonGreyToggleSofterGrey")
            case .buttonGreyToggleSoftWhite:
                return SwiftUI.Color("buttonGreyToggleSoftWhite")
            case .whiteToggleDeepBlue:
                return SwiftUI.Color("whiteToggleDeepBlue")
            case .softWhiteToggleGrey:
                return SwiftUI.Color("softWhiteToggleGrey")
            case .darkBlueToggleBlack:
                return SwiftUI.Color("darkBlueToggleBlack")
            case .whiteToggleDarkBlue:
                return SwiftUI.Color("whiteToggleDarkBlue")
            case .darkBlueToggleWhite:
                return SwiftUI.Color("darkBlueToggleWhite")
            case .shadowedBackground:
                return SwiftUI.Color("shadowSandToggleShadowBlue")
            case .whiteToggleInactive:
                return SwiftUI.Color("whiteToggleInactive")
            case .inactiveBackground:
                return SwiftUI.Color("inactiveBackground")
            case .inactiveText:
                return SwiftUI.Color("inactiveText")
            case .deepBlue:
                return SwiftUI.Color("deepBlue")
            case .softSandToggleNavy:
                return SwiftUI.Color("softSandToggleNavy")
            case .blueGrey:
                return SwiftUI.Color("blueGrey")
            case .burntRed:
                return SwiftUI.Color("burntRed")
            }
        }
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct BrandColors_Previews: PreviewProvider {
    
    static var previews: some View {
        
        PreviewHelperView(axis: .vertical) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 150))], spacing: 20) {
                    ForEach(BrandColors.allCases, id: \.self) { item in
                        VStack {
                            Rectangle().foregroundColor(item.color)
                                .frame(height: 30)
                            Text(item.rawValue)
                                .foregroundColor(BrandColors.foreground.color)
                        }
                    }
                }
            }.padding()
        }
    }
}
