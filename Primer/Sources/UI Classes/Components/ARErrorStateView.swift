//
//  ARErrorStateView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 2/24/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI

struct ARErrorStateView: View {
    var style: ARTrackingErrorStyle
    
    // MARK: - Body
    
    var body: some View {
        if style != .none {
            HStack(spacing: BrandPadding.Medium.pixelWidth) {
                SmallSystemIcon(style: style.symbol)
                    .padding(.leading, 2)
                LabelView(text: style.message, style: .errorStateLight)
                Spacer()
            }.padding(BrandPadding.Tiny.pixelWidth)
            .background(BrandColors.burntRed.color)
            .cornerRadius(42)
            .shadow(color: BrandColors.burntRed.color.opacity(0.5), radius: 6, x: 0.0, y: 0.0)
        }
    }
}

// MARK: - Preview

struct ARErrorStateView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            VStack(spacing: 30) {
                ARErrorStateView(style: .insufficientFeatures)
                ARErrorStateView(style: .cantFindWall)
                ARErrorStateView(style: .excessiveMotion)
                ARErrorStateView(style: .lowLight)
            }.padding()
        }
    }
}
