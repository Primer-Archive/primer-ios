//
//  ProductPillView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 2/23/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

/**
 Displays a product variation preview orb in a capsule next to a label view. Has two states based on if it's selected. 
 */
struct ProductPillView: View {
    @Binding var selectedProductID: Int
    var product: ProductModel
    var variationIndex: Int

    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            VariationOrb(product: product, index: Double(variationIndex))
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(lineWidth: 1).foregroundColor((selectedProductID == product.id) ? BrandColors.white.color : BrandColors.white.color.opacity(0.3)))
                .padding(.leading, 2)

            LabelView(text: product.variationName, style: (selectedProductID == product.id) ? .singleLineLight12M : .singleLineTitle12M)
                .padding(.horizontal, BrandPadding.Small.pixelWidth)
                .frame(width: 100)
        }
        .padding(BrandPadding.Tiny.pixelWidth)
        .background((selectedProductID == product.id) ? BrandColors.blueGrey.color : BrandColors.backgroundView.color)
        .cornerRadius(40)
        .shadow(color: Color.black.opacity(0.15), radius: 3)
        .overlay(RoundedRectangle(cornerRadius: 40).strokeBorder(lineWidth: 2).foregroundColor((selectedProductID == product.id) ? BrandColors.white.color : Color.clear))
        .frame(height: 50)
    }
}

// MARK: - Preview

struct ProductPillView_Previews: PreviewProvider {

    static var text = ""
    
    static var previews: some View {
        ZStack {
            PreviewHelperView(axis: .vertical) {
                if let product = loadProduct() {
                    ProductPillView(selectedProductID: .constant(-1), product: product, variationIndex: 0)
                } else {
                    Text(text)
                }
            }.edgesIgnoringSafeArea(.all)
        }
    }
    
    static func loadProduct() -> ProductModel? {
        let decoder = JSONDecoder()
        guard let url = Bundle.main.url(forResource: "product", withExtension: "json") else {
            text = "failed url"
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            text = "failed data"
            return nil
        }
        guard let product = try? decoder.decode(ProductModel.self, from: data) else {
            text = "failed product decode"
            return nil
        }
        return product
    }
}
