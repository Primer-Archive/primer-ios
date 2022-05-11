//
//  ButtonWithText.swift
//  Primer
//
//  Created by James Hall on 9/15/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Text only button with transparent background. `LabelStyle` defaults to `.buttonMedium`.
 */
public struct ButtonWithText: View {
    var btnText: String
    var labelStyle: LabelStyle = .buttonMedium
    var btnAction: () -> Void
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: {
            self.btnAction()
        }) {
            LabelView(text: btnText, style: self.labelStyle)
        }
    }
}

// MARK: - Preview

struct ButtonWithText_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            VStack(spacing: 50) {
                ButtonWithText(btnText: "Sample Medium", btnAction: {})
                ButtonWithText(btnText: "Sample SemiBold", labelStyle: .buttonSemibold) {}
            }
        }
    }
}
