//
//  TextEditorModifier.swift
//  Primer
//
//  Created by Sarah Hurtgen on 3/12/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Sets up custom styling for a multi-line `TextEditor` view.
 */
struct TextEditorModifier: ViewModifier {
    @Binding var text: String
    var width: CGFloat
    var height: CGFloat

    init(text: Binding<String>, width: CGFloat, height: CGFloat) {
        self._text = text
        self.width = width
        self.height = height
        UITextView.appearance().backgroundColor = .clear
    }
    
    // MARK: - Body
    
    func body(content: Content) -> some View {
        ZStack {
            // textfield
            content
                .coordinateSpace(name: "textviewLayer")
                .padding(.horizontal, BrandPadding.Small.pixelWidth)
                .frame(maxWidth: .infinity, maxHeight: height)
                .background(BrandColors.whiteToggleDeepBlue.color)
                .font(LabelStyle.textEditor.font)
                .keyboardType(.default)
                .textContentType(.none)
                .autocapitalization(.none)
                .foregroundColor(BrandColors.buttonGreyToggleSoftWhite.color)
        }
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrandColors.softWhiteToggleGrey.color, lineWidth: 2).allowsHitTesting(false))
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

struct TextEditorView_Previews: PreviewProvider {
    @State static var text: String = ""
    
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            TextEditor(text: $text)
                .modifier(TextEditorModifier(text: $text, width: 400, height: 100))
                .frame(width: 400, height: 100)
                .padding()
        }
    }
}
