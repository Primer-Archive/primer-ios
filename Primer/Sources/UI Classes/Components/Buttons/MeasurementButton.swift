//
//  MeasurementButton.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/21/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Semi-transparent overlay button for displaying the Width and Height of a users current Swatch placement.
 */
struct MeasurementButton: View {
    @Binding var isSelected: Bool
    let measurementHelper: MeasurementHelper
    var btnAction: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: self.btnAction) {
            HStack(spacing: BrandPadding.Smedium.pixelWidth) {
                LabelView(text: "\(measurementHelper.stringWidth) ×  \(measurementHelper.stringHeight)", style: .transparentButton)
                Image(systemName: SFSymbol.rulerFill.rawValue)
                    .font(Font.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(BrandColors.white.color)
            }.padding(.horizontal, BrandPadding.Medium.pixelWidth)
        }
        .frame(height: 42)
        .background(isSelected ? BrandColors.darkBlue.color.opacity(0.85) : ButtonColor.transparent.background)
        .cornerRadius(21)
    }

}

// MARK: - Preview

struct MeasurementButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView().edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                
                // default
                MeasurementButton(isSelected: .constant(false), measurementHelper: MeasurementHelper(width: 30, height: 23), btnAction: {})
                
                // selected
                MeasurementButton(isSelected: .constant(true), measurementHelper: MeasurementHelper(width: 30, height: 23), btnAction: {})
            }
        }
    }
}
