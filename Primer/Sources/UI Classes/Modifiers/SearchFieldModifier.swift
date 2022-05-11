//
//  SearchFieldModifier.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/28/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Modifies appearance of TextField to appear like a search bar. Uses layered text to create custom placeholder fonts/colors. When used with a `Textfield` logic should be applied to clear the Binding var `text` to avoid seeing two strings layered at once. 
 */
struct SearchFieldModifier: ViewModifier {
    
    @Binding var text: String
    @Binding var isSearching: Bool
    var inactiveText: String
    var onTap: () -> Void
    var clearTextAction: () -> Void

    // MARK: - Body
    
    func body(content: Content) -> some View {
        ZStack {
            
            // custom placeholder coloring/text
            HStack(spacing: 0) {
                // magnifying glass icon
                SmallSystemIcon(style: isSearching ? .searchGrey : .searchWhite)
                if !isSearching {
                    LabelView(text: inactiveText, style: .searchInactive)
                    Spacer()
                } else {
                    LabelView(text: text.isEmpty ? "Search" : "", style: .search)
                    Spacer()
                }
            }
            .padding(.leading, 4)
            .allowsHitTesting(false)
                
            // textfield
            content
                .padding(.leading, isSearching ? 40 : 0)
                .padding(.trailing, isSearching ? BrandPadding.Small.pixelWidth : 0)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .textFieldStyle(PlainTextFieldStyle())
                .font(LabelStyle.search.font)
                .keyboardType(.default)
                .textContentType(.none)
                .autocapitalization(.none)
                .foregroundColor(isSearching ? BrandColors.buttonGreyToggleSoftWhite.color : BrandColors.white.color)
                .disableAutocorrection(true)
                .onTapGesture {
                    self.onTap()
                }
                
            if isSearching && !text.isEmpty {
                HStack {
                    Spacer()
                    SmallSystemIcon(style: .xFillSearch, isButton: true, btnAction: {
                        clearTextAction()
                        text = ""
                    })
                    .padding(.horizontal, BrandPadding.Tiny.pixelWidth)
                }
            }
        }
        .background(isSearching ? BrandColors.whiteToggleDeepBlue.color : BrandColors.navy.color)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrandColors.softWhiteToggleGrey.color, lineWidth: isSearching ? 1 : 0).allowsHitTesting(false))
    }
}

// MARK: - Preview

struct SearchFieldModifier_Previews: PreviewProvider {

    static var previews: some View {
        
        PreviewHelperView(axis: .vertical) {
            VStack(spacing: 15) {
                TextField("", text: .constant(""))
                    .modifier(SearchFieldModifier(text: .constant(""), isSearching: .constant(true), inactiveText: "Search & find products", onTap: {}, clearTextAction: {}))
                TextField("", text: .constant(""))
                    .modifier(SearchFieldModifier(text: .constant(""), isSearching: .constant(false), inactiveText: "Search & find products", onTap: {}, clearTextAction: {}))
            }.padding()
            .frame(minWidth: 300, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
        }
    }
}
