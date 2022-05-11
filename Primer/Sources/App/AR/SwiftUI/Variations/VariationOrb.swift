//
//  VariationOrb.swift
//  Primer
//
//  Created by James Hall on 8/7/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

public struct VariationOrb : View{
    var product: ProductModel
    var index: Double
    
    @State private var isAnimating = false
    
    
    public var body: some View {
        ZStack{
            ProductOrbView(product:product,priority: 1)
                .frame(maxWidth: 40, maxHeight: 40)
                .cornerRadius(40)
        }
        .animation(Animation.easeInOut(duration: 0.35).delay(index * 0.25))
        .onAppear {
            self.isAnimating = true
        }
    }
}

struct VariationOrb_Previews: PreviewProvider {
    static var previews: some View {
        let decoder = JSONDecoder()
        guard
            let url = Bundle.main.url(forResource: "product", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let product = try? decoder.decode(ProductModel.self, from: data)
            
            else { return AnyView(Text("Failed parsing")) }
        
        return AnyView(
            VariationOrb(
            product: product,
            index:0)
        )
        
    }
}
