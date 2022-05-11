//
//  OrbGridView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/18/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

// MARK: - Orb Grid

struct OrbGridView: View {

    var products: [ProductModel]
    var gridWidth: CGFloat
    var gridHeight: CGFloat = 180

    var maxDisplayed: Int {
        return gridWidth > 250 ? 21 : 13
    }
    
    var rows: Int {
        if products.count <= 5 {
            return products.count <= 5 ? 1 : (products.count <= maxDisplayed ? 2 : 3)
        } else {
            return products.count <= maxDisplayed ? 2 : 3
        }
    }
    
    var itemCountPerRow: Int {
        let number = products.count - (products.count % rows)
        return number / rows
    }
    
    var spacing: CGFloat {
        return products.count <= maxDisplayed ? 10 : 5
    }
    
    // MARK: - Body
    
    var body: some View {
        
        VStack(spacing: .none) {
            ForEach(0..<rows) { rowIndex in
                HStack(spacing:spacing) {
                    ForEach(0..<itemCountPerRow) { index in
                        VStack(spacing: 0) {
                            let product = products[(rowIndex * itemCountPerRow) + index]

                            if product.productType == .productWithVariations, let variationIndex = product.variationIndex, (product.variations?.count ?? -1) > variationIndex, let variation = product.variations?[variationIndex] {
                                PreviewCircle(type: .swatch(product: variation), size: orbSize(), hasShadow: true)
                                    .overlay(Circle().strokeBorder(BrandColors.white.color, lineWidth: 4))
                            } else {
                                PreviewCircle(type: .swatch(product: product), size: orbSize(), hasShadow: true)
                                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 4))
                            }
                        }
                    }
                }
                .padding(.leading, isEvenRow(rowIndex) ? 0 : orbSize().width + (spacing))
            }
        }.frame(width: gridWidth, height: gridHeight)
    }

    // MARK: - Helper Functions
    
    func orbSize() -> CGSize {
        if gridWidth > 250 {
            return products.count <= 21 ? CGSize(width: 68, height: 68) : CGSize(width: 48, height: 48)
        } else {
            return products.count <= 13 ? CGSize(width: 68, height: 68) : CGSize(width: 48, height: 48)
        }
    }
    
    func isEvenRow(_ index: Int) -> Bool {
        return index == 0 || index == 2
    }
    
    func toggledOffsetX(for index: Int) -> CGFloat {
        return isEvenRow(index) ? 0 : orbSize().width / 2 + (spacing / 2)
    }
}

// MARK: - Preview
//
//struct OrbGridView_Previews: PreviewProvider {
//    static var previews: some View {
//        OrbGridView()
//    }
//}
