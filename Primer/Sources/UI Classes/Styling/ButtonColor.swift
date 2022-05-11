//
//  ButtonColor.swift
//  Primer
//
//  Created by Sarah Hurtgen on 9/21/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Initial pass at creating button color pairs. Ideally replace "color" cases with more standard names for dark mode support. (ex. replace "blue" with "primaryAction" or something like that)
 */
enum ButtonColor {
    case blue
    case navy
    case navyToggle
    case transparent
    case greyToggleGrey
    case categoryGrey
    case categoryWhite
    case categoryNavy
    case sandBlueOutline
    case sandLockedBlueOutline
    case whiteBlueOutline
    case blueFilledAndOutline
    case solitudeGrey
    case blueWhiteOutline
    case brightBlueWhiteOutline
    case deepBlue
    case greyOutline
    case grey

    var foreground: Color {
        switch self {
        case .transparent:
            return BrandColors.white.color.opacity(0.55)
        case .sandLockedBlueOutline, .whiteBlueOutline:
            return BrandColors.blue.color
        case .sandBlueOutline:
            return BrandColors.blueToggleWhite.color
        case .solitudeGrey, .categoryWhite:
            return BrandColors.solitudeGrey.color
        case .greyOutline:
            return BrandColors.buttonGrey.color
        default:
            return BrandColors.white.color
        }
    }

    var background: Color {
        switch self {
        case .blue, .blueFilledAndOutline, .blueWhiteOutline:
            return BrandColors.blue.color
        case .navy, .categoryNavy:
            return BrandColors.navy.color
        case .brightBlueWhiteOutline:
            return Color.blue
        case .navyToggle:
            return BrandColors.blueToggleNavy.color
        case .transparent:
            return BrandColors.darkBlue.color.opacity(0.6)
        case .greyToggleGrey:
            return BrandColors.buttonGreyToggleSofterGrey.color
        case .categoryGrey, .grey:
            return BrandColors.buttonGrey.color
        case .sandBlueOutline, .sandLockedBlueOutline, .greyOutline:
            return BrandColors.backgroundView.color
        case .solitudeGrey:
            return BrandColors.solitudeGrey.color
        case .categoryWhite, .whiteBlueOutline:
            return BrandColors.white.color
        case .deepBlue:
            return BrandColors.deepBlue.color
        }
    }
    
    var outline: Color {
        switch self {
        case .blueFilledAndOutline:
            return BrandColors.blue.color
        default:
            return self.foreground
        }
    }
    
    var selected: Color {
        switch self {
        case .categoryGrey, .categoryWhite, .categoryNavy:
            return BrandColors.blue.color
        default:
            return self.background
        }
    }
    
    var hasOutline: Bool {
        switch self {
        case .sandBlueOutline, .blueFilledAndOutline, .whiteBlueOutline, .blueWhiteOutline, .brightBlueWhiteOutline, .sandLockedBlueOutline, .greyOutline:
            return true
        default:
            return false
        }
    }
}
