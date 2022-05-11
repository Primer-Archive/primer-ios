//
//  CategoryLink.swift
//  Primer
//
//  Created by James Hall on 7/20/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine


struct CategoryLink: View {
    @State private var isActive: Bool = false
    var tappedFromSearch: Bool
    var category: CategoryModel

    var onSelectProduct: (Repository<[ProductModel]>, Int, Int) -> Void
    
    init(tappedFromSearch: Bool, category: CategoryModel, onSelectProduct: @escaping ((Repository<[ProductModel]>, Int,Int) -> Void)){
        self.tappedFromSearch = tappedFromSearch
        self.category = category
        self.onSelectProduct = onSelectProduct
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if self.category.images.count > 0 {
                RemoteImageView(url: self.category.images[0], width: isDeviceIpad() ? 260 : 140) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
        }
        .frame(width: isDeviceIpad() ? 260 : 140, height: isDeviceIpad() ? 240 : 110)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: SwiftUI.Color.black.opacity(0.3), radius: 6.0, x: 0.0, y: 0.0)
        .overlay(self.categoryText)
    }

    var categoryText: some View {
        VStack{
            Text(self.category.name)
                .font(.system(size: isDeviceIpad() ? 16 : 14, weight: .medium, design: .rounded))
                .foregroundColor(BrandColors.white.color)
        }
        .shadow(radius: 24)
        .cornerRadius(isDeviceIpad() ? 80 : 48)
        .padding(isDeviceIpad() ? 80 : 12)
    }
}
