//
//  ProductDetailMiniCardTest.swift
//  Primer
//
//  Created by Adam Debreczeni on 7/7/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

struct ProductDetailMiniCardTest: View {
    
    @State private var isExpanded: Bool = true
    private let viewAnimation:Animation = Animation.easeInOut(duration: 2.55)
    
    var body: some View {
        VStack {
            Button("Open") {
                withAnimation(self.viewAnimation){
                    self.isExpanded.toggle()
                }
            }
            Image("backTextureDiffuse")
                .resizable()
                .frame(width: isExpanded ? 60 : 300, height: isExpanded ? 60 : 300, alignment: .center)
                .offset(x: isExpanded ? -100 : 0, y: isExpanded ? -32 : 0)
            .layoutPriority(1.0)
            
            Text("Product Title")
            .padding()
            .layoutPriority(1.0)
            
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum quis nunc odio. Morbi bibendum, dui ac rutrum lobortis, sem turpis scelerisque mi, a pulvinar justo risus vel eros. Integer a sollicitudin diam. Curabitur a porta nunc. In condimentum sed leo ut sagittis. Vestibulum ante ipsum primis in faucibus orci luctus et.")
                .padding()
            .frame(alignment: .bottom)
            .layoutPriority(0.0)
            
            HStack {
                Button("Button One") {
                    print("do something!")
                }
                .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue))
                Button("Button Two") {
                    print("do something!")
                }
                    
                .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue))
            }
            .layoutPriority(1.0)
            .frame(alignment: .bottom)
        }
        .frame(width: 300.00, height: isExpanded ? 68 : 600, alignment: .top)
        .padding()
        .clipped(antialiased: true)
        .cornerRadius(20)
    }
}

//private func cardArea() -> some View{
//    Text("derp")
//}

struct ProductDetailMiniCardTest_Previews: PreviewProvider {
    static var previews: some View {
        ProductDetailMiniCardTest()
    }
}
