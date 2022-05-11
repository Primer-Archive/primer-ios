//
//  ProductCollectionCard.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/6/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

// MARK: - Card

struct ProductCollectionCard: View {
    
    @State var timer: ImageTimer?
    @State var featuredIndex: Int = 0
    @State var animationStarted: Bool = false
    var collectionRepo: ProductCollectionRepository
    var collection: ProductCollectionModel
    var shouldFlatten: Bool = true
    var shouldOffsetTimer: Bool = false
    var cardWidth: CGFloat
    
    // MARK: - Body
    
    var body: some View {
        
        ZStack(alignment: .top) {
            
            // non - animated background image (for initial load)
            if (shouldFlatten ? flattenedProducts(collectionRepo.value).count > 0 : collectionRepo.value.count > 0),
               let product = shouldFlatten ? flattenedProducts(collectionRepo.value)[0] : collectionRepo.value[0] {
                ProductSwatchView(product: product, customURL: product.featuredImageOne, customWidth: cardWidth)
                    .frame(minWidth: 0, maxWidth: cardWidth, minHeight: 0, maxHeight: 200, alignment: .center)
                    .overlay(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
                    .clipped()
                    .opacity(animationStarted ? 0 : 1)
            }
            
            // animating images
            ForEach(shouldFlatten ? flattenedProducts(collectionRepo.value).indices : collectionRepo.value.indices, id: \.self) { index in
                let product = shouldFlatten ? flattenedProducts(collectionRepo.value)[index] : collectionRepo.value[index]
                ProductSwatchView(product: product, customURL: product.featuredImageOne, customWidth: cardWidth)
                    .frame(minWidth: 0, maxWidth: cardWidth, minHeight: 0, maxHeight: 200, alignment: .center)
                    .overlay(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
                    .clipped()
                    .opacity(index == featuredIndex ? 1 : 0)
                    .animation (
                        Animation
                            .linear(duration: 3)
                    )
            }

            OrbGridView(products: shouldFlatten ? flattenedProducts(collectionRepo.value) : collectionRepo.value, gridWidth: cardWidth)
                .padding(.bottom, 30)
                .frame(width: cardWidth, height: 220)
            
        }
        .overlay(
            HStack {
                SmallSystemIcon(style: .tripleSquares)
                LabelView(text: collection.name, style: .smallCategoryLight)
                Spacer()
            }.padding(.horizontal, BrandPadding.Tiny.pixelWidth)
            .background(BrandColors.navy.color),
            alignment: .bottom
        )
        .cornerRadius(20)
        .onAppear {
            if timer == nil {
                if shouldOffsetTimer {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        self.timer = ImageTimer(sinkAction: iterateThroughImages)
                    }
                } else {
                    self.timer = ImageTimer(sinkAction: iterateThroughImages)
                }
            }
        }
        .onDisappear {
            timer = nil
            animationStarted = false
        }
    }
    
    // MARK: - Helper Functions
    
    func iterateThroughImages() {
        animationStarted = true
        if (featuredIndex + 1) < (shouldFlatten ? flattenedProducts(collectionRepo.value).count : collectionRepo.value.count) {
            featuredIndex += 1
        } else {
            featuredIndex = 0
        }
    }
    
    public func flattenedProducts(_ products: [ProductModel]) -> [ProductModel] {
        var flattened: [ProductModel] = []

        products.forEach { product in
            if product.productType == .product {
                flattened.append(product)
            } else {
                if let variations = product.variations {
                    variations.forEach { variation in
                        flattened.append(variation)
                    }
                }
            }
        }
        return flattened
    }
}

// MARK: - Preview
//
//struct ProductCollectionCard_Previews: PreviewProvider {
//    static var previews: some View {
//        PreviewHelperView(axis: .vertical) {
//            ScrollView(.horizontal) {
//                HStack(spacing: 20) {
//                    ProductCollectionCard(products: loadTestProducts(), collectionName: "Test Collection", cardWidth: 220)
//                }.padding()
//            }
//        }.frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//
//    static func loadTestProducts() -> [ProductModel] {
//        var testProducts: [ProductModel] = []
//        for _ in 0...20 {
//            let decoder = JSONDecoder()
//            guard let url = Bundle.main.url(forResource: "product", withExtension: "json") else {
//                return testProducts
//            }
//            guard let data = try? Data(contentsOf: url) else {
//                return testProducts
//            }
//            guard let prod = try? decoder.decode(ProductModel.self, from: data) else {
//                return testProducts
//            }
//            testProducts.append(prod)
//        }
//        return testProducts
//    }
//
//}
private struct OffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = .zero
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}
