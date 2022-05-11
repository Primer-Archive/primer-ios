//
//  SwipeModifier.swift
//  Primer
//
//  Created by Sarah Hurtgen on 11/3/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

struct SwipeModifier: ViewModifier {
    @GestureState private var offset: CGSize = CGSize.zero
    @State private var dragging = false
    @Binding var currentPosition: CGFloat
    @Binding var isVisible: Bool
    var originalHeight: CGFloat = 0
    var offsetHeight: CGFloat
    var dismissAction: () -> Void = {}
    
    // MARK: - Body
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top, content: {
            content
        })
        .offset(y: max(-(UIScreen.main.bounds.height / 3), offset.height))
        .animation(dragging ? Animation.default : {
            Animation.interpolatingSpring(stiffness: 220.0, damping: 40.0, initialVelocity: 3.0)
        }())
        .gesture(DragGesture(minimumDistance: 1)
            .updating($offset) { value, state, transaction in
                state = value.translation
            }
            .onChanged { _ in
                self.dragging = true
            }
            .onEnded(onDragEnded)
        )
    }
    
    private func onDragEnded(value: DragGesture.Value) {
        dragging = false
        let dragDirection = value.predictedEndLocation.y - value.location.y
        
        if dragDirection > originalHeight {
            withAnimation {
                isVisible = false
                dismissAction()
            }
            currentPosition = offsetHeight
        } else {
            withAnimation {
                isVisible = true
            }
            isVisible = true
        }
    }
}

struct SwipeModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            VStack {
                Text("Tester")
            }
            .frame(height: UIScreen.main.bounds.height / 3)
            .frame(maxWidth: .infinity)
            .background(BrandColors.backgroundView.color)
            .modifier(SwipeModifier(currentPosition: .constant(300), isVisible: .constant(true), originalHeight: 0, offsetHeight: 300, dismissAction: {}))
        }.frame(maxHeight: .infinity)
    }
}
