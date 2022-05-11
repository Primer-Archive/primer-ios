//
//  SwipeableCarousel.swift
//  Primer
//
//  Created by Sarah Hurtgen on 3/29/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Custom swipeable carousel for use when `TabView PageStyleTabView()` is not working as expected. Pass in views in the same way as a TabView. Pagination dots not included.
 */
struct SwipeableCarousel<Content: View>: View {
    @GestureState private var translation: CGFloat = 0
    @Binding var selection: Int
    let count: Int
    let content: Content
    
    init(count: Int, selection: Binding<Int>, @ViewBuilder content: () -> Content) {
        self.count = count
        self._selection = selection
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                self.content.frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width, alignment: .leading)
            .offset(x: -CGFloat(self.selection) * geometry.size.width)
            .offset(x: self.translation)
            .animation(.interactiveSpring(), value: selection)
            .animation(.interactiveSpring(), value: translation)
            .gesture(
                DragGesture().updating(self.$translation) { value, state, _ in
                    state = value.translation.width
                }.onEnded { value in
                    let offset = value.translation.width / geometry.size.width
                    let newIndex = (CGFloat(self.selection) - offset).rounded()
                    self.selection = min(max(Int(newIndex), 0), self.count - 1)
                }
            )
        }
    }
}
