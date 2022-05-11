//
//  VisualEffectView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 12/4/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Used to add Blur effect on orb overlays. This is only intended to be used in place of SwiftUI `.blur(radius:)` when the blur needs to be added as an overlay, and cannot be applied to the view itself.
 */
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}
