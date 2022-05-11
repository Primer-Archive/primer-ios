//
//  ARTrackingErrorStyle.swift
//  Primer
//
//  Created by Sarah Hurtgen on 2/24/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI

enum ARTrackingErrorStyle {
    case excessiveMotion
    case insufficientFeatures
    case lowLight
    case cantFindWall
    case none
    
    var symbol: SystemIconStyle {
        switch self {
        case .excessiveMotion:
            return .walkingManErrorState
        case .insufficientFeatures:
            return .arkitErrorState
        case .lowLight:
            return .lightbulbErrorState
        case .cantFindWall:
            return .circlesHexagonErrorState
        default:
            return .arkitErrorState
        }
    }
    
    var message: String {
        switch self {
        case .excessiveMotion:
            return "Excessive motion, slow down device"
        case .insufficientFeatures:
            return "Insufficient features, look around"
        case .lowLight:
            return "Not enough light, go to a brighter spot"
        case .cantFindWall:
            return "LiDAR could not detect a wall"
        default:
            return ""
        }
    }
}
