//
//  Persona.swift
//  Primer
//
//  Created by Sarah Hurtgen on 9/23/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import Foundation


/**
 A simple enum to house the constants for "Persona" types. Keeping in one place incase Copy changes around the roles, this way it can automatically update anywhere they're used.
 */
enum Persona: String {
    case unselected = "I am a..."
    case designer = "Design Professional"
    case decorator = "Decor Enthusiast"
    case manufacturer = "Manufacturer"
    
    var parsingFriendly: String {
        switch self {
        case .designer:
            return "professional"
        case .decorator:
            return "enthusiast"
        case .manufacturer:
            return "manufacturer"
        default:
            return ""
        }
    }
}
