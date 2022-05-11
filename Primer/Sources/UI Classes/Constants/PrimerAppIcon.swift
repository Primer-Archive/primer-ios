//
//  PrimerAppIcon.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/20/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import UIKit

/**
 Helper enum to use with `AppIconManager` to fetch images for customizing displayed App icon. `.standard` case returns nil for `name`, and represents the default App icon.
 */
enum PrimerAppIcon: CaseIterable {
    case standard
    case darkGray
    case orange
    case purple
    case pink
    case yellow
    case sand
    case aqua
    case green
    case blue
    case nineties
    
    var name: String? {
        switch self {
        case .standard:
            return nil
        case .darkGray:
            return "AltIconDarkGray"
        case .orange:
            return "AltIconOrange"
        case .purple:
            return "AltIconPurple"
        case .pink:
            return "AltIconPink"
        case .yellow:
            return "AltIconYellow"
        case .sand:
            return "AltIconSand"
        case .aqua:
            return "AltIconAqua"
        case .green:
            return "AltIconGreen"
        case .blue:
            return "AltIconBlue"
        case .nineties:
            return "AltIcon90s"
        }
    }
}
