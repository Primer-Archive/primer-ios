//
//  AlertItem.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/27/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Used with the SwiftUI `Alert` style view to help support displaying more one alert within a single view (but only calling `.alert(item:)` once). Use `@State var alertItem: AlertItem?` and set at various trigger points according to what content should be displayed.
 */
struct AlertItem: Identifiable {
    var id = UUID()
    var title: Text
    var message: Text?
    var primaryButton: Alert.Button?
    var secondaryButton: Alert.Button?
    var dismissButton: Alert.Button?
}
