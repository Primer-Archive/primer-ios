//
//  ExploreBarView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 3/25/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

/**
 Used as a Sticky header in the `BrandPageView`, toggles between two states based on if it is "Pinned" or not. Expects a `CategoryButton` to be passed for the `content`.
 */
struct ExploreBarView<Content: View>: View {
    @Namespace var backButtonNamespace
    @Binding var isHeaderPinned: Bool
    var exitPage: () -> Void
    let content: Content
    
    init(isHeaderPinned: Binding<Bool>, exitPage: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self._isHeaderPinned = isHeaderPinned
        self.exitPage = exitPage
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            SmallSystemIcon(style: .backChevron, isButton: true, btnAction: exitPage)
                .background(BrandColors.navy.color)
                .matchedGeometryEffect(id: "UniversalBack", in: backButtonNamespace)
                .frame(width: isHeaderPinned ? 30 : 0, height: 30)
                .clipShape(Circle())
                .padding(.trailing, BrandPadding.Tiny.pixelWidth)

            Spacer().frame(width: isHeaderPinned ? 0 : 1, height: 30)
                .matchedGeometryEffect(id: "UniversalBack", in: backButtonNamespace, isSource: true)
                
            VStack {
                LabelView(text: "Explore products", style: .bodyMedium)
            }

            Spacer()

            content
        }.frame(height: 50)
        .padding(.horizontal, isHeaderPinned ? BrandPadding.Small.pixelWidth : 0)
        .background(BrandColors.backgroundView.color)
        .cornerRadius(BrandPadding.Large.pixelWidth)
        .overlay(
            RoundedRectangle(cornerRadius: BrandPadding.Large.pixelWidth).stroke(lineWidth: isHeaderPinned ? 2 : 0).foregroundColor(BrandColors.white.color)
        )
        .shadow(color: Color.black.opacity(isHeaderPinned ? 0.6 : 0), radius: 10, x: 0.0, y: 0.0)
        .padding(.horizontal, isHeaderPinned ? BrandPadding.Small.pixelWidth : BrandPadding.Smedium.pixelWidth)
        .padding(.top, BrandPadding.Medium.pixelWidth)
    }
}
