//
//  SystemIconStyle.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/27/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import Foundation
import SwiftUI

/**
 A helper enum to hold preset styling information for symbol use throughout app and with the `SmallSystemIcon` view. If no customizations applied, styling defaults to white foreground color, clear background, size 12 semibold font, image size 36x36.
 */
enum SystemIconStyle: CaseIterable {
    
    case x12
    case x18
    case xFillBlue
    case xFillGrey
    case xFillSearch
    case filter
    case backChevron
    case smallBackChevron
    case rightChevron
    case downChevron
    case downChevronGrey
    case checkmark
    case checkmarkFill
    case checkmarkSquare
    case emptyCircle
    case filledCircle
    case profileCircle
    case searchWhite
    case searchGrey
    case colorPalette
    case paintbrush
    case squares
    case squareOnCircle
    case shareSquare
    case shareSquareNavy
    case clearShareSquare
    case squareOutline
    case largeShare
    case largeSave
    case largeCheckmark
    case arrowLeft
    case counterClockwiseArrow
    case cartFill
    case bag
    case heartOutline
    case heartFill
    case ellipses
    case favoriteBadge
    case unfavoritedBadge
    case tripleSquares
    case walkingMan
    case walkingManLarge
    case walkingManErrorState
    case lightbulbErrorState
    case circlesHexagonErrorState
    case arkitErrorState
    case phoneArrow
    case phoneArrowLarge
    case handTap
    case handTapLarge
    case rectangleFillOnRectFill
    case envelopeFill
}

extension SystemIconStyle {
    
    // MARK: - Foreground
    
    var foreground: Color {
        switch self {
        case .emptyCircle, .xFillGrey, .xFillSearch:
            return BrandColors.buttonGreyToggleSofterGrey.color
        case .searchGrey:
            return BrandColors.buttonGreyToggleSoftWhite.color
        case .rightChevron, .colorPalette, .squares, .squareOnCircle, .bag:
            return BrandColors.titleLabel.color
        case .backChevron:
            return BrandColors.navy.color
        case .handTap, .phoneArrow:
            return BrandColors.deepBlue.color
        case .filledCircle, .checkmarkFill, .checkmarkSquare, .squareOutline, .clearShareSquare, .largeCheckmark:
            return BrandColors.blueToggleAqua.color
        case .largeSave, .largeShare:
            return BrandColors.black.color
        case .downChevronGrey:
            return BrandColors.grey.color
        case .checkmark:
            return BrandColors.blue.color
        case .walkingManErrorState, .lightbulbErrorState, .circlesHexagonErrorState, .arkitErrorState:
            return BrandColors.burntRed.color
        default:
            return BrandColors.white.color
        }
    }
    
    var isSelectedForeground: Color {
        switch self {
        case .phoneArrow, .handTap:
            return BrandColors.white.color
        default:
            return foreground
        }
    }
    
    // MARK: - Background
    
    var background: Color {
        switch self {
        case .searchWhite, .x12, .x18, .paintbrush, .profileCircle, .arrowLeft, .ellipses, .shareSquareNavy, .smallBackChevron:
            return BrandColors.navy.color
        case .heartFill, .heartOutline, .cartFill, .xFillBlue:
            return BrandColors.blue.color
        case .filter:
            return BrandColors.buttonGrey.color
        case .backChevron, .walkingManErrorState, .lightbulbErrorState, .circlesHexagonErrorState, .arkitErrorState:
            return BrandColors.white.color
        case .favoriteBadge:
            return BrandColors.orange.color
        default:
            return Color.clear
        }
    }
    
    // MARK: - Font
    
    var font: Font {
        switch self {
        case .largeCheckmark:
            return Font.system(size: 48, weight: .regular, design: .rounded)
        case .checkmarkSquare:
            return Font.system(size: 36, weight: .medium, design: .rounded)
        case .emptyCircle, .checkmarkFill, .filledCircle, .xFillGrey:
            return Font.system(size: 32, weight: .medium, design: .rounded)
        case .backChevron:
            return Font.system(size: 32, weight: .regular, design: .rounded)
        case .largeSave, .largeShare, .squareOutline, .xFillSearch:
            return Font.system(size: 24, weight: .regular, design: .rounded)
        case .profileCircle, .paintbrush, .x18, .ellipses, .clearShareSquare:
            return Font.system(size: 18, weight: .semibold, design: .rounded)
        case .searchGrey, .searchWhite:
            return Font.system(size: 17, weight: .medium, design: .default)
        case .checkmark:
            return Font.system(size: 16, weight: .bold, design: .default)
        case .handTapLarge, .walkingManLarge, .phoneArrowLarge, .counterClockwiseArrow:
            return Font.system(size: 16, weight: .medium, design: .rounded)
        case .filter, .tripleSquares:
            return Font.system(size: 16, weight: .regular, design: .default)
        case .shareSquare, .xFillBlue, .shareSquareNavy, .handTap, .walkingMan, .phoneArrow:
            return Font.system(size: 14, weight: .medium, design: .rounded)
        case .favoriteBadge, .unfavoritedBadge:
            return Font.system(size: 14, weight: .regular, design: .rounded)
        default:
            return Font.system(size: 12, weight: .semibold, design: .rounded)
        }
    }
    
    // MARK: - Size
    
    var size: CGSize {
        switch self {
        case .largeCheckmark:
            return CGSize(width: 50, height: 50)
        case .xFillSearch, .rectangleFillOnRectFill:
            return CGSize(width: 22, height: 22)
//        case .smallBackChevron:
//            return CGSize(width: 14, height: 14)
        case .envelopeFill:
            return CGSize(width: 26, height: 26)
        case .emptyCircle, .checkmarkFill, .filledCircle, .backChevron, .filter:
            return CGSize(width: 30, height: 30)
        case .largeSave, .largeShare, .walkingManErrorState, .lightbulbErrorState, .circlesHexagonErrorState, .arkitErrorState:
            return CGSize(width: 32, height: 32)
        default:
            return CGSize(width: 36, height: 36)
        }
    }
    
    // MARK: - Symbol String
    
    var symbol: String {
        switch self {
        case .x12, .x18, .xFillBlue:
            return SFSymbol.x.rawValue
        case .xFillGrey, .xFillSearch:
            return SFSymbol.xFill.rawValue
        case .filter:
            return SFSymbol.filterSlider.rawValue
        case .backChevron:
            return SFSymbol.chevronLeftFill.rawValue
        case .smallBackChevron:
            return SFSymbol.chevronLeft.rawValue
        case .downChevron, .downChevronGrey:
            return SFSymbol.chevronDown.rawValue
        case .emptyCircle:
            return SFSymbol.circle.rawValue
        case .checkmark:
            return SFSymbol.checkmark.rawValue
        case .checkmarkFill, .largeCheckmark:
            return SFSymbol.checkmarkCircleFill.rawValue
        case .checkmarkSquare:
            return SFSymbol.checkmarkSquare.rawValue
        case .squareOutline:
            return SFSymbol.squareOutline.rawValue
        case .filledCircle:
            return SFSymbol.circleOutlineFill.rawValue
        case .searchGrey, .searchWhite:
            return SFSymbol.magnifyingGlass.rawValue
        case .colorPalette:
            return SFSymbol.paintPalette.rawValue
        case .squares:
            return SFSymbol.squareOnSquare.rawValue
        case .rightChevron:
            return SFSymbol.chevronRight.rawValue
        case .profileCircle:
            return SFSymbol.personCropCircle.rawValue
        case .paintbrush:
            return SFSymbol.paintbrush.rawValue
        case .arrowLeft:
            return SFSymbol.arrowLeft.rawValue
        case .phoneArrow, .phoneArrowLarge:
            return SFSymbol.arrowToPhone.rawValue
        case .shareSquare, .clearShareSquare, .largeShare, .shareSquareNavy:
            return SFSymbol.squareAndArrowUp.rawValue
        case .counterClockwiseArrow:
            return SFSymbol.arrowCounterClockwise.rawValue
        case .handTap, .handTapLarge:
            return SFSymbol.handTapFill.rawValue
        case .heartFill, .favoriteBadge, .unfavoritedBadge:
            return SFSymbol.heartFill.rawValue
        case .heartOutline:
            return SFSymbol.heartOutline.rawValue
        case .cartFill:
            return SFSymbol.cartFill.rawValue
        case .ellipses:
            return SFSymbol.ellipsis.rawValue
        case .squareOnCircle:
            return SFSymbol.squareOnCircle.rawValue
        case .bag:
            return SFSymbol.bag.rawValue
        case .largeSave:
            return SFSymbol.squareAndArrowDown.rawValue
        case .tripleSquares:
            return SFSymbol.tripleSquares.rawValue
        case .walkingMan, .walkingManLarge, .walkingManErrorState:
            return SFSymbol.walkingMan.rawValue
        case .rectangleFillOnRectFill:
            return SFSymbol.rectangleFillOnRectFill.rawValue
        case .lightbulbErrorState:
            return SFSymbol.lightbulbFill.rawValue
        case .circlesHexagonErrorState:
            return SFSymbol.circleHexagonFill.rawValue
        case .arkitErrorState:
            return SFSymbol.arkit.rawValue
        case .envelopeFill:
            return SFSymbol.envelopeFill.rawValue
        }
    }
}
