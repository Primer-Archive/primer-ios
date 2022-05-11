//
//  SearchBarView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/28/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

// MARK: - Search Bar
/**
 Animated Search bar. Slides when tapped splitting into a back button and search bar, and then expands back to single "button" appearance when "back" button is tapped.
 */
struct SearchBarView: View {
    @Environment(\.analytics) var analytics
    @Binding var text: String
    @Binding var isSearching: Bool
    var customInactiveText: String? = nil
    var scrollToAction: () -> Void
    var exitSearchAction: () -> Void
    var clearSearchTextAction: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            HStack(spacing: BrandPadding.Smedium.pixelWidth) {
                if isSearching {
                    SmallSystemIcon(style: .backChevron, isButton: true, btnAction: {
                        if isSearching {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            scrollToAction()
                            exitSearchAction()
                            withAnimation {
                                // clear text to avoid it overlaying with placeholder string
                                text = ""
                                self.isSearching = false
                            }
                        }
                    }).allowsHitTesting(isSearching)
                }
                
                TextField("", text: $text)
                    .modifier(SearchFieldModifier(text: $text, isSearching: $isSearching, inactiveText: customInactiveText ?? "Search & find products", onTap: {
                        scrollToAction()
                        analytics?.searchBarTapped()
                        withAnimation {
                            if !isSearching {
                                isSearching = true
                            }
                        }
                    }, clearTextAction: {
                        clearSearchTextAction()
                    }))
            }
            .padding(BrandPadding.Smedium.pixelWidth)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

struct SearchBarView_Previews: PreviewProvider {

    static var previews: some View {
        
        PreviewHelperView(axis: .vertical) {
            VStack {
                SearchBarView(text: .constant(""), isSearching: .constant(false), scrollToAction: {}, exitSearchAction: {}, clearSearchTextAction: {})
                SearchBarView(text: .constant(""), isSearching: .constant(true), scrollToAction: {}, exitSearchAction: {}, clearSearchTextAction: {})
            }
        }
    }
}
