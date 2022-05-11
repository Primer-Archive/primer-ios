//
//  TemporaryPopup.swift
//  Primer
//
//  Created by Sarah Hurtgen on 12/7/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

struct TemporaryPopup: View {
    var labelText: String
    var symbolStyle: SystemIconStyle = .largeCheckmark
    var size: CGSize = CGSize(width: 200, height: 200)
    
    var body: some View {
        VStack(spacing: BrandPadding.Medium.pixelWidth) {
            SmallSystemIcon(style: symbolStyle)
            LabelView(text: labelText, style: .cardHeader)
        }
        .frame(width: size.width, height: size.height)
        .background(BrandColors.backgroundView.color)
        .cornerRadius(BrandPadding.Medium.pixelWidth)
    }
}

struct TemporaryPopup_Previews: PreviewProvider {
    static var previews: some View {
        TemporaryPopup(labelText: "Saved Image")
    }
}
