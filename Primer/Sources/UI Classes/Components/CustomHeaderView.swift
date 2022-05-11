//
//  CustomHeaderView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 9/21/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Leading side holds `SmallSystemIcon` to handle navigation, with a centered title formatted using a `.cardHeader` style `LabelView`.
 
 Optional `trailingIcon` and `preTrailingIcon`  allow for trailing  for the icon images  (ex. if a user is logged in, the logout icon may be needed on the trailing side).
 */
struct CustomHeaderView: View {
    var leadingIcon: SystemIconStyle
    var text: String
    var preTrailingIcon: SystemIconStyle? = nil
    var trailingIcon: SystemIconStyle? = nil
    var leadingBtnAction: () -> Void = {}
    var preTrailingBtnAction: () -> Void = {}
    var trailingBtnAction: () -> Void = {}
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            VStack {
                LabelView(text: text, style: .cardHeader)
                    .frame(height: 36)
            }
            
            HStack {
                SmallSystemIcon(style: leadingIcon, isButton: true, btnAction: leadingBtnAction)
                Spacer()
                
                // For "Easter Egg" Alt App Icon option
                #if !APPCLIP
                if let preTrailingIconName = preTrailingIcon {
                    SmallSystemIcon(style: preTrailingIconName, isButton: true, btnAction: preTrailingBtnAction)
                }
                #endif

                if let trailingIconName = trailingIcon {
                    SmallSystemIcon(style: trailingIconName, isButton: true, btnAction: trailingBtnAction)
                }
            }.frame(maxWidth: .infinity)
        }
        .frame(height: 36)
        .padding(EdgeInsets(top: BrandPadding.Smedium.pixelWidth, leading: BrandPadding.Smedium.pixelWidth, bottom: BrandPadding.Medium.pixelWidth, trailing: BrandPadding.Smedium.pixelWidth))
    }
}

// MARK: - Preview

struct CustomHeaderView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        PreviewHelperView(axis: .vertical) {
            VStack(spacing: 20) {
                CustomHeaderView(leadingIcon: .x12, text: "Title")
                CustomHeaderView(leadingIcon: .x12, text: "Title", trailingIcon: .profileCircle)
                CustomHeaderView(
                    leadingIcon: .x12,
                    text: "Title",
                    preTrailingIcon: .paintbrush,
                    trailingIcon: .profileCircle)
            }
        }
    }
}
