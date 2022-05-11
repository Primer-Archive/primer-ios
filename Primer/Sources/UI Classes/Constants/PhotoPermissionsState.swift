//
//  PhotoPermissionsState.swift
//  Primer
//
//  Created by Sarah Hurtgen on 12/15/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import Foundation

/**
 Helper enum for tracking Photo permissions within the `PhotoPermissionsView`
 */
enum PhotoPermissionsState {
    case initial
    case denied
    
    var btnLabel: String {
        switch self {
        case .initial:
            return "Allow Access to Photos"
        case .denied:
            return "Grant Access in Settings"
        }
    }
    
    var imageName: String {
        switch self {
        case .initial:
            return "PermissionsBackground"
        case .denied:
            return "PermissionsInstructions"
        }
    }
}
