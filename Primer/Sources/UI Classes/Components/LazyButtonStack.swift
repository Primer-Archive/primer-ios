//
//  LazyButtonStack.swift
//  Primer
//
//  Created by Sarah Hurtgen on 11/2/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

struct LazyButtonStack<Content: View>: View {
    
    let axis: Axis.Set
    let content: Content
    var vPadding: BrandPadding
    var hPadding: BrandPadding
    var spacing: CGFloat?

    init(axis: Axis.Set, spacing: CGFloat? = nil, vPadding: BrandPadding = .Medium, hPadding: BrandPadding = .Medium, @ViewBuilder content: () -> Content) {
        self.axis = axis
        self.spacing = spacing
        self.hPadding = hPadding
        self.vPadding = vPadding
        self.content = content()
    }
    
    var body: some View {
        return ScrollView(axis) {
            switch axis {
            case .horizontal:
                LazyHStack(spacing: spacing) {
                    content
                }.padding(.vertical, vPadding.pixelWidth)
                .padding(.horizontal, hPadding.pixelWidth)
            case .vertical:
                LazyVStack(spacing: spacing) {
                    content
                }.padding(.vertical, vPadding.pixelWidth)
                .padding(.horizontal, hPadding.pixelWidth)
            default:
                content
            }
        }
    }
}

struct LazyButtonStack_Previews: PreviewProvider {
    static var previews: some View {
        LazyButtonStack(axis: .horizontal, content: {
            CategoryButton(text: "Sample 1", hasDropdown: false, btnAction: {})
            CategoryButton(text: "Sample 2", btnAction: {})
            CategoryButton(text: "Sample 3", btnAction: {})
        })
    }
}
