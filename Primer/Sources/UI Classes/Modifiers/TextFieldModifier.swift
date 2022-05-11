//
//  TextFieldModifier.swift
//  Primer
//
//  Created by Sarah Hurtgen on 9/18/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

// MARK: - TextField Modifier
/**
 Sets up custom defaults for `TextField`, with variables to support custom `keyboardType`, `textContentType`, and `autoCapitalization`.

 */
struct TextFieldModifier: ViewModifier {
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = .none
    var autoCapitalization: UITextAutocapitalizationType = .none
    
    // MARK: - Body
    
    func body(content: Content) -> some View {
        content
            .padding(.leading, BrandPadding.Small.pixelWidth)
            .padding(.trailing, BrandPadding.Small.pixelWidth)
            .frame(height: 52)
            .textFieldStyle(PlainTextFieldStyle())
            .font(LabelStyle.textfield.font)
            .keyboardType(self.keyboardType)
            .textContentType(self.textContentType)
            .autocapitalization(self.autoCapitalization)
            .foregroundColor(BrandColors.textfieldText.color)
            .disableAutocorrection(true)
            .background(BrandColors.backgroundBW.color)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.09), radius: 4, x: 0.0, y: 2)
    }
}

// MARK: - Preview

struct TextFieldModifier_Previews: PreviewProvider {
    static var previews: some View {
        
        VStack(spacing: 15) {
            TextField("textfield", text: .constant("textfield"))
                .modifier(TextFieldModifier(keyboardType: .emailAddress, textContentType: .emailAddress))

            TextField("textfield as overlay", text: .constant(""))
                .modifier(TextFieldModifier(keyboardType: .emailAddress, textContentType: .emailAddress))
            
        }.padding()
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
        .background(BrandColors.sand.color)
    }
}
