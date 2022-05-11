//
//  VariationOrbs.swift
//  Primer
//
//  Created by James Hall on 8/7/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

/**
 Holds a horizontal scrolling stack of `ProductPillView` variations. Launches with offset mirroring the edge of our product details card, or scrolled to the selected variation (if not the first).
 */
struct VariationOrbs: View {
    var variations: [ProductModel]
    var selectedVariationIndex: Binding<Double>
    var scrollOffset: CGFloat
    
    @State var selectedProductID: Int
    @State var isInitialLoad = true
    
    @Environment(\.analytics) var analytics
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.horizontal) {

                HStack(spacing: BrandPadding.Small.pixelWidth) {
                    ForEach(variations.indices, id:\.self) { idx in
                        ProductPillView(selectedProductID: $selectedProductID, product: self.variations[idx], variationIndex: idx)
                            .id("ProductPill\(self.variations[idx].id)")
                            .overlay(
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    self.selectedVariationIndex.wrappedValue = Double(idx)
                                    self.selectedProductID = self.variations[idx].id
                                    self.analytics?.didSwitchSwatchMaterial(product:self.variations[idx], isVariation: true)
                                }) {
                                    Rectangle().foregroundColor(.clear)
                                }
                            )
                    }.onChange(of: selectedVariationIndex.wrappedValue, perform: { value in
                        let newSelectionIndex = Int(value)
                        if newSelectionIndex < variations.count {
                            selectedProductID = variations[newSelectionIndex].id
                            scrollView.scrollTo("ProductPill\(selectedProductID)")
                        }
                    })
                }
                .padding(.leading, isDeviceIpad() ? 160 : BrandPadding.Smedium.pixelWidth)
                .padding(.trailing, isDeviceIpad() ? (160.0 + scrollOffset) : (BrandPadding.Smedium.pixelWidth + scrollOffset))
                .offset(x: scrollOffset)

                .onAppear {
                    if let first = variations.first, selectedProductID == -1 {
                        selectedProductID = first.id
                    }
                    
                    if variations.first?.id != selectedProductID {
                        // only scroll to the center if it's not the first product
                        scrollView.scrollTo("ProductPill\(selectedProductID)")
                    }
                }
            }.frame(maxWidth: .infinity)
        }
    }
}
