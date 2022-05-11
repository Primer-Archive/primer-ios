//
//  FadingLabel.swift
//  Primer
//
//  Created by Sarah Hurtgen on 11/2/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 A shortcut view to handle the Labels that should had the "fade" affect as they scroll towards the top of a view.
 */
struct FadingLabel: View {
    
    var text: String
    var style: LabelStyle
    var offset: CGFloat?
    
    var body: some View {
        GeometryReader { proxy in
            LabelView(text: text, style: style)
                .opacity(Double((proxy.frame(in: .global).minY - (offset ?? 0)) / 94))
        }
    }
}

struct FadingLabel_Previews: PreviewProvider {
    static var previews: some View {
        FadingLabel(text: "Test", style: .bodyMedium)
    }
}
