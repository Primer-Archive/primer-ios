//
//  VariationText.swift
//  Primer
//
//  Created by James Hall on 8/7/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

public struct VariationText : View{
    var string:String
    var index: Double
    @State private var isAnimating = false
    
    
    public var body: some View {
        Text(string)
            .opacity(isAnimating ? 1 : 0)
            .animation(Animation.easeInOut(duration: 0.40).delay(index * 0.35))
            .shadow(color: Color.black.opacity(0.33), radius: 6, x: 0, y: 0)
            .onAppear {
                self.isAnimating = true
        }
    }
}

struct VariationText_Previews: PreviewProvider {
    static var previews: some View {
        VariationText(string: "This is a test string", index: 1)
    }
}
