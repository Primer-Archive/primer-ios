//
//  PreviewHelperView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/30/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 A helper to more easily view dark and light mode versions of previews. Pass in which axis works best for that specific preview, as well as the content to be displayed in each color scheme.
 */
struct PreviewHelperView<Content: View>: View {
    
    let schemes: [ColorScheme] = [.light, .dark]
    let axis: Axis.Set
    let content: Content

    init(axis: Axis.Set, @ViewBuilder content: () -> Content) {
        self.axis = axis
        self.content = content()
    }
    
    var body: some View {
        switch axis {
        case .vertical:
            VStack {
                colorSchemedContent
            }
        case .horizontal:
            HStack {
                colorSchemedContent
            }
        default:
            content
        }
    }
    
    var colorSchemedContent: some View {
        ForEach(schemes.indices, id: \.self) { index in
            content
                .background(BrandColors.backgroundView.color)
                .environment(\.colorScheme, schemes[index])
        }
    }
}
