//
//  MeasurementsExpandedView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/21/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI


/**
 Displays when user taps on `MeasurementButton` while in AR experience. Calculates swatch measurement data and is stored within the `PopOverMeasurementsView`.
 */
struct MeasurementsExpandedView: View {
    var isPaint: Bool
    var measurementHelper: MeasurementHelper

    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            LabelView(text: "Real world measurements for \nyour AR swatch", style: .bodyRegular)
                .frame(height: 40)
                .padding(.vertical, BrandPadding.Medium.pixelWidth)
            
            HStack(alignment: .top, spacing: BrandPadding.Smedium.pixelWidth) {
                VStack(alignment: .trailing, spacing: BrandPadding.Smedium.pixelWidth) {
                    LabelView(text: "Width:", style: .bodyRegular)
                    LabelView(text: "Height:", style: .bodyRegular)
                    LabelView(text: "Sq feet:", style: .bodyRegular)
                    LabelView(text: "Sq meters:", style: .bodyRegular)
                    if isPaint {
                        LabelView(text: "Paint gallons:", style: .bodyRegular)
                    }
                }
                
                VStack(alignment: .leading, spacing: BrandPadding.Smedium.pixelWidth) {
                    LabelView(text: measurementHelper.stringWidth, style: .bodySemibold)
                    LabelView(text: measurementHelper.stringHeight, style: .bodySemibold)
                    LabelView(text: measurementHelper.squaredFeet, style: .bodySemibold)
                    LabelView(text: measurementHelper.squaredMeters, style: .bodySemibold)
                    if isPaint {
                        VStack(alignment: .leading) {
                            LabelView(text: measurementHelper.gallons, style: .bodySemibold)
                            LabelView(text: "for one coat", style: .subtleFooter)
                        }
                    }
                }
            }.frame(maxWidth: .infinity)
            
            HStack(alignment: .bottom) {
                Spacer()
                Image("ThinkingIllustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 70)
            }
        }
        .background(BrandColors.backgroundView.color)
        .cornerRadius(20)
        .padding(BrandPadding.Smedium.pixelWidth)
    }
}

// MARK: - Preview

struct MeasurementsExpandedView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementsExpandedView(isPaint: false, measurementHelper: MeasurementHelper(width: 13, height: 112))
            .padding()
    }
}
