//
//  URL+Extension.swift
//  Primer
//
//  Created by Sarah Hurtgen on 2/2/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import Foundation

// sets URL to conform to Identifiable for use within SwiftUI navigation
extension URL: Identifiable {
    public var id: UUID {
        return UUID()
    }
}
