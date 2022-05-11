//
//  LabelView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 9/21/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Label that pulls from preset `LabelStyle` defaults for things like font and text color.
 */
struct LabelView: View {
    var text: String
    var style: LabelStyle
    private let interface: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    
    // MARK: - Body
    
    var body: some View {
        Text(text)
            .foregroundColor(style.textColor)
            .font(interface == .pad ? style.ipadFont : style.font)
            .lineLimit(style.lineLimit)
            .multilineTextAlignment(style.textAlignment)
            .padding(.leading, style.leadingPadding)
            .truncationMode(style.truncationMode)
    }
}

// MARK: - Preview

struct LabelView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LabelView(text: "Test Label", style: .bodyRegular)
        }
    }
}
