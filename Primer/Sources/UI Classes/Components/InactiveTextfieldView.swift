//
//  InactiveTextfieldView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/4/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI

struct InactiveTextfieldView: View {
    var text: String
    
    var body: some View {
        HStack {
            LabelView(text: text, style: .bodyInactive)
                .padding(.leading, BrandPadding.Small.pixelWidth)
                .padding(.trailing, BrandPadding.Small.pixelWidth)
                .frame(height: 52)
                .foregroundColor(BrandColors.textfieldText.color)
            Spacer()
        }
        .background(BrandColors.inactiveBackground.color)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrandColors.whiteToggleInactive.color, lineWidth: 2))
        .cornerRadius(10)
    }
}

struct InactiveTextfieldView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            InactiveTextfieldView(text: "email@emailtown.com")
                .padding()
        }
    }
}
