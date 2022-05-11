//
//  ButtonSmallIcon.swift
//  Primer
//
//  Created by James Hall on 8/3/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Used to display system icons with appearance defined by `SystemIconStyle`. Set `isButton` to true to use as a button, and pass in the action. Otherwise, displays as icon image only.
 */

public struct SmallSystemIcon: View {
    
    var style: SystemIconStyle
    var isSelected: Bool = false
    var isButton: Bool = false
    var btnAction: () -> Void = {}
    
    // MARK: - Body
    
    public var body: some View {
        if isButton {
            Button(action: {
                self.btnAction()
            }) {
                icon
            }
        } else {
            icon
        }
    }
    
    // MARK: - Icon
    
    var icon: some View {
        Image(systemName: style.symbol)
            .font(style.font)
            .foregroundColor(isSelected ? style.isSelectedForeground : style.foreground)
            .frame(width: style.size.width, height: style.size.height)
            .background(style.background)
            .clipShape(Circle())
    }
}

// MARK: - Preview

struct SmallSystemIcon_Previews: PreviewProvider {

    static var previews: some View {
        
        PreviewHelperView(axis: .vertical) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(SystemIconStyle.allCases, id: \.self) { item in
                        SmallSystemIcon(style: item, isButton: true, btnAction: {})
                    }
                }
            }.padding()
        }
    }
}
