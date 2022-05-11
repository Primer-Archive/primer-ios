//
//  LabelStyle.swift
//  Primer
//
//  Created by Sarah Hurtgen on 9/21/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Styling defaults for use on labels throughout app. Intended to be paired with `LabelView`.
 */
enum LabelStyle: String, CaseIterable {
    case cardHeader
    case cardTitle
    case cardSubtitle
    case cardSubtitleLeading
    case cardDescription
    case subviewCardTitle
    case subviewBrandTitle
    case featuredCardTitle
    case featuredCardSubtitle
    case inputHeader
    case bodyRegular
    case bodyLeading
    case bodySemibold
    case bodySemiboldWhite
    case bodyMedium
    case bodyMediumGray
    case bodyInactive
    case buttonMedium
    case buttonSemibold
    case buttonNearSIWA
    case bodyTrailingMedium
    case textfield
    case sectionHeader
    case sectionSubtitle
    case subtitle
    case subtleFooter
    case transparentButton
    case nuxTitle
    case nuxDescription
    case nuxHeaderLeading
    case nuxTitleLeading
    case nuxDescriptionLeading
    case smallLight
    case smallCategoryLight
    case smallCategoryDark
    case smallSwatchTitle
    case smallSwatchSubtitle
    case medSwatchTitle
    case medSwatchSubtitle
    case largeSwatchTitle
    case largeSwatchSubtitle
    case largeSwatchFooter
    case search
    case searchInactive
    case lightModeMedium
    case shareModal
    case textEditor
    case singleLineLight12M
    case errorStateLight
    case singleLineTitle12M
    
    // MARK: - Font
    
    var font: Font {
        switch self {
        case .smallSwatchSubtitle, .medSwatchSubtitle:
            return Font.system(size: 9, weight: .medium, design: .rounded)
        case .subtleFooter:
            return Font.system(size: 10, weight: .regular, design: .rounded)
        case .subviewBrandTitle, .smallSwatchTitle, .largeSwatchSubtitle, .largeSwatchFooter:
            return Font.system(size: 10, weight: .medium, design: .rounded)
        case .subviewCardTitle, .medSwatchTitle:
            return Font.system(size: 11, weight: .medium, design: .rounded)
        case .bodyLeading, .cardSubtitleLeading:
            return Font.system(size: 12, weight: .regular, design: .rounded)
        case .featuredCardSubtitle, .largeSwatchTitle, .bodyTrailingMedium, .singleLineLight12M, .singleLineTitle12M:
            return Font.system(size: 12, weight: .medium, design: .rounded)
        case .errorStateLight:
            return Font.system(size: 12, weight: .semibold, design: .rounded)
        case .cardSubtitle, .shareModal, .subtitle:
            return Font.system(size: 13, weight: .regular, design: .rounded)
        case .smallCategoryLight, .smallCategoryDark, .smallLight:
            return Font.system(size: 13, weight: .medium, design: .rounded)
        case .cardDescription:
            return Font.system(size: 14, weight: .regular, design: .rounded)
        case .cardTitle, .sectionSubtitle:
            return Font.system(size: 14, weight: .medium, design: .rounded)
        case .inputHeader, .featuredCardTitle:
            return Font.system(size: 14, weight: .semibold, design: .rounded)
        case .bodySemiboldWhite:
            return Font.system(size: 14, weight: .semibold, design: .rounded)
        case .bodyRegular, .textfield, .nuxDescriptionLeading, .bodyInactive:
            return Font.system(size: 16, weight: .regular, design: .rounded)
        case .bodySemibold:
            return Font.system(size: 16, weight: .semibold, design: .rounded)
        case .bodyMedium, .buttonMedium, .bodyMediumGray, .transparentButton, .sectionHeader, .lightModeMedium:
            return Font.system(size: 16, weight: .medium, design: .rounded)
        case .buttonSemibold:
            return Font.system(size: 16, weight: .semibold, design: .rounded)
        case .search, .searchInactive, .textEditor:
            return Font.system(size: 17, weight: .regular, design: .default)
        case .nuxDescription:
            return Font.system(size: 18, weight: .medium, design: .rounded)
        case .cardHeader:
            return Font.system(size: 18, weight: .semibold, design: .rounded)
        case .buttonNearSIWA:
            return Font.system(size: 20, weight: .regular, design: .default)
        case .nuxTitleLeading:
            return Font.system(size: 22, weight: .regular, design: .rounded)
        case .nuxTitle:
            return Font.system(size: 24, weight: .bold, design: .rounded)
        case .nuxHeaderLeading:
            return Font.system(size: 30, weight: .regular, design: .rounded)
        }
    }
    
    // MARK: - IPad Font
    
    var ipadFont: Font {
        switch self {
        case .subtleFooter:
            return Font.system(size: 10, weight: .regular, design: .rounded)
        case .subviewBrandTitle, .featuredCardSubtitle:
            return Font.system(size: 12, weight: .medium, design: .rounded)
        case .cardSubtitle:
            return Font.system(size: 14, weight: .regular, design: .rounded)
        case .subviewCardTitle, .featuredCardTitle:
            return Font.system(size: 14, weight: .medium, design: .rounded)
        case .cardTitle, .transparentButton:
            return Font.system(size: 16, weight: .medium, design: .rounded)
        case .sectionSubtitle:
            return Font.system(size: 18, weight: .medium, design: .rounded)
        case .sectionHeader:
            return Font.system(size: 28, weight: .semibold, design: .rounded)
        case .nuxTitleLeading:
            return Font.system(size: 24, weight: .regular, design: .rounded)
        default:
            return self.font
        }
    }
    
    // MARK: - Color
    
    var textColor: Color {
        switch self {
        case .cardSubtitle, .sectionSubtitle, .cardSubtitleLeading:
            return BrandColors.softGreyToggleSofterGrey.color
        case .subtleFooter:
            return BrandColors.softGreyToggleSofterGrey.color.opacity(0.4)
        case .subviewCardTitle, .subviewBrandTitle, .bodyMediumGray:
            return BrandColors.greyToggleWhite.color
        case .inputHeader:
            return BrandColors.inputHeader.color
        case .sectionHeader, .featuredCardTitle:
            return BrandColors.greyToggleSand.color
        case .featuredCardSubtitle:
            return BrandColors.greyToggleSand.color.opacity(0.5)
        case .buttonMedium, .buttonSemibold, .buttonNearSIWA:
            return BrandColors.blueToggleAqua.color
        case .textfield:
            return BrandColors.textfieldText.color
        case .transparentButton, .smallCategoryLight, .largeSwatchTitle, .largeSwatchSubtitle, .searchInactive, .smallLight, .bodySemiboldWhite, .singleLineLight12M, .errorStateLight:
            return BrandColors.white.color
        case .smallCategoryDark, .lightModeMedium, .shareModal:
            return BrandColors.grey.color
        case .largeSwatchFooter:
            return BrandColors.buttonGrey.color
        case .search, .textEditor:
            return BrandColors.buttonGreyToggleSoftWhite.color
        case .medSwatchTitle, .medSwatchSubtitle:
            return BrandColors.black.color
        case .nuxDescriptionLeading:
            return BrandColors.titleLabel.color.opacity(0.75)
        case .bodyLeading, .bodyTrailingMedium:
            return BrandColors.darkBlueToggleWhite.color
        case .bodyInactive:
            return BrandColors.inactiveText.color
        default:
            return BrandColors.titleLabel.color
        }
    }
    
    // MARK: - Line Limit
    
    var lineLimit: Int? {
        switch self {
        case .featuredCardSubtitle, .smallSwatchTitle, .smallSwatchSubtitle, .medSwatchTitle, .medSwatchSubtitle, .smallCategoryLight, .smallCategoryDark, .cardTitle, .cardSubtitleLeading, .singleLineLight12M, .errorStateLight, .singleLineTitle12M:
            return 1
        case .largeSwatchTitle, .nuxTitle, .nuxDescription:
            return 2
        case .smallLight, .bodyLeading:
            return nil
        default:
            return 3
        }
    }
    
    // MARK: - Text Alignment
    
    var textAlignment: TextAlignment {
        switch self {
        case .nuxHeaderLeading, .nuxTitleLeading, .nuxDescriptionLeading, .bodyLeading, .cardSubtitleLeading, .textEditor:
            return .leading
        case .bodyTrailingMedium:
            return .trailing
        default:
            return .center
        }
    }
    
    // MARK: - Padding
    
    var leadingPadding: CGFloat {
        switch self {
        case .sectionSubtitle, .sectionHeader:
            return BrandPadding.Medium.pixelWidth
        default:
            return 0.0
        }
    }
    
    // MARK: - Truncation
    
    var truncationMode: Text.TruncationMode {
        switch self {
            default: return .tail
        }
    }
}


// MARK: - Preview

struct LabelStyle_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(LabelStyle.allCases, id: \.self) { style in
                        LabelView(text: style.rawValue, style: style)
                    }
                }
            }.frame(maxWidth: .infinity)
        }
    }
}
