//
//  ProductSwatchView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/7/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine


// MARK: - Product Swatch
/**
 Currently used as a rectangle swatch preview
 */
struct ProductSwatchView: View {
    var product: ProductModel
    var customURL: URL? = nil
    var customWidth: CGFloat? = nil
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment:.topTrailing) {
            if product.featuredImages.count > 0, let url = customURL ?? product.featuredImages[product.featuredProductImage - 1] {
                RemoteImageView(url: url, width: customWidth) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                }
            } else {
                switch product.material.diffuse.content {
                case .color(let color):
                    color.swiftUIColor
                case .constant(let constant):
                    SwiftUI.Color(white: constant)
                default:
                    Color.gray
                }
            }
        }
    }
}
