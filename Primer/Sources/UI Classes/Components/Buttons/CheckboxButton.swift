//
//  CheckboxButton.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/4/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI

struct CheckboxButton: View {
    @Binding var isSelected: Bool
    var btnAction: () -> Void

    var body: some View {
        
        ZStack {
            if isSelected {
                SmallSystemIcon(style: .checkmark)
            } else {
                Rectangle()
                    .foregroundColor(BrandColors.white.color)
            }
        }
        .background(BrandColors.white.color)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrandColors.blue.color, lineWidth: 2))
        .frame(width: 36, height: 36)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0.0, y: 0.0)
        .onTapGesture {
            btnAction()
        }
    }
}

struct CheckboxButton_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            CheckboxButton(isSelected: .constant(true), btnAction: {})
                .padding()
        }
    }
}
