//
//  GradientLoaderView.swift
//  Primer
//
//  Created by James Hall on 9/2/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI


struct GradientLoaderView: View {
    
    @State var gradient = [BrandColors.orange.color, BrandColors.yellow.color]
    @State var startPoint = UnitPoint(x: 0, y: 0)
    @State var endPoint = UnitPoint(x: 0, y: 2)
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(gradient: Gradient(colors: self.gradient), startPoint: self.startPoint, endPoint: self.endPoint))
            .onAppear{
                
                withAnimation (Animation.easeInOut(duration: 10).repeatForever(autoreverses: true)){
                    self.startPoint = UnitPoint(x: 1, y: -1)
                    self.endPoint = UnitPoint(x: 0, y: 1)
                }
            }
    }
}
