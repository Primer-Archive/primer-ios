//
//  PopOverView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 11/11/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 A reusable PopOver overlay, pass in `content` to slide in/out of view with a dimmed background. Default behavior dismisses when background is tapped. Add a `SwipeModifier` to the `content` view on initialization to allow for swipe to dismiss interaction.
 
 Intended to eventually replace the `PopOverContentView` so that only one popover holder is used throughout the app.
 */
struct PopOverView<Content: View>: View {
    @Environment(\.presentationMode) var presentationMode
    @State var showModal: Bool = false
    @State var isVisible: Bool = false
    var bindingVisible: Binding<Bool>?
    var content: Content
    var offset: CGFloat = 0
    var showModalOffset: CGFloat
    var alignment: Alignment
    var dismissAction: () -> Void
    
    init(bindingVisible: Binding<Bool>? = nil, isVisible: State<Bool>? = nil, alignment: Alignment = .top, offset: CGFloat = 0, showModalOffset: CGFloat = UIScreen.main.bounds.size.height * 0.4, dismissAction: @escaping () -> Void = {}, @ViewBuilder content: () -> Content) {
        if let binding = bindingVisible {
            self.bindingVisible = binding
        }
        if let visibleState = isVisible {
            self._isVisible = visibleState
        }
        self.alignment = alignment
        self.showModalOffset = showModalOffset
        self.dismissAction = dismissAction
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        if let binding = bindingVisible, showModal != binding.wrappedValue {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.33)) {
                    self.showModal.toggle()
                }
            }
        } else if bindingVisible == nil, (showModal != isVisible) {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.33)) {
                    self.showModal.toggle()
                }
            }
        }
        return
            ZStack {
                SwiftUI.Color.black.opacity(showModal ? 0.75 : 0)
                .edgesIgnoringSafeArea(.vertical)
                .overlay(
                    content
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: showModalOffset)
                        .offset(y: showModal ? offset : showModalOffset)
                        .edgesIgnoringSafeArea(.bottom)
                    ,
                    alignment: .bottom
                )
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture(perform: {
                withAnimation(.easeInOut(duration: 0.33)) {
                    isVisible = false
                    if let _ = bindingVisible {
                        bindingVisible?.wrappedValue = false
                    }
                    dismissAction()
                }
            })
    }
}

struct PopOverView_Previews: PreviewProvider {
    static var previews: some View {
        PopOverView(alignment: .center, offset: 0, showModalOffset: 0, content: {})
    }
}
