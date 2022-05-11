//
//  UIApplication.swift
//  Primer
//
//  Created by James Hall on 10/15/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//
import SwiftUI

extension UIApplication {
    var currentScene: UIWindowScene? {
        connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
    }
}
