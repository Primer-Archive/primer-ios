//
//  NavigationLink+Extension.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/28/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI


/**
 Helper for setting up "lazy" navigation links. Used with a `View` extension to call `.navigate(using:, destination:)` that initializes when the value is ready.
 */
extension NavigationLink where Label == EmptyView {
    init?<Value>(
        _ binding: Binding<Value?>,
        @ViewBuilder destination: (Value) -> Destination
    ) {
        guard let value = binding.wrappedValue else {
            return nil
        }

        let isActive = Binding(
            get: { true },
            set: { newValue in if !newValue { binding.wrappedValue = nil } }
        )

        self.init(destination: destination(value), isActive: isActive, label: EmptyView.init)
    }
}
