//
//  ProductCard.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/26/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine


enum ProductCardSize {
    case small
    case medium
    case large
}

// MARK: - Product Card
/**
 Intended for use as main way of displaying products throughout app whenever not present in an AR view.
 `.small` displays a circular swatch material with two labels
 `.medium` displays a background image with an overlay of a circlular swatch material with two labels
 `.large` displays a background image with an overlay of a circlular swatch material with two labels, as well as a footer including a third label.
 */
struct ProductCard: View {
    
    var product: ProductModel
    var size: ProductCardSize
    var height: CGFloat? = nil
    var imageWidth: CGFloat = 250 // fallback flexible max width
    var lockedWidth: CGFloat? = nil // sets exact width
    var isFavorite: Bool
    var showsFavoriteBadge: Bool = true
    var favoriteBtnAction: () -> Void
    var unfavoriteBtnAction: () -> Void
    var categoryName: String {
        switch product.productCategory {
        case 1:
            return "Paint"
        case 2:
            return "Tile"
        case 3:
            return "Wallpaper"
        default:
            return ""
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        switch size {
    
        // MARK: - Small
        
        case .small:
            VStack(spacing: BrandPadding.Tiny.pixelWidth) {
                previewCircle
                LabelView(text: product.name, style: .smallSwatchTitle)
                LabelView(text: product.brandName, style: .smallSwatchSubtitle)
                
                // setting max width here results in cards that can be unevenly spaced (if ones label is longer)
                // keeping at fixed width for now for consistency
            }.frame(width: 90)
            .padding(.top, BrandPadding.Tiny.pixelWidth) // padding keeps shadow from getting clipped
            
        // MARK: - Medium
        
        case .medium:
            ZStack {
                ProductSwatchView(product: product, customURL: product.featuredImageOne, customWidth: imageWidth)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    .cornerRadius(21, corners: [.bottomLeft, .bottomRight])
                    .overlay(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.4), Color.white]), startPoint: .top, endPoint: .bottom))
                VStack {
                    previewCircle
                        .padding(.bottom, 6)
                    LabelView(text: product.name, style: .medSwatchTitle)
                    LabelView(text: product.brandName, style: .medSwatchSubtitle)
                }.padding(.horizontal, 6)
            }
            .frame(height: height ?? 140)
            .overlay(FavoriteBadge(isVisible: showsFavoriteBadge, isFavorite: isFavorite, favoriteAction: favoriteBtnAction, unfavoriteAction: unfavoriteBtnAction), alignment: .topTrailing)
            .cornerRadius(20)
            
        // MARK: - Large
        
        case .large:
            ZStack {
                ProductSwatchView(product: product, customURL: product.featuredImageOne, customWidth: lockedWidth ?? imageWidth)
                    .allowsHitTesting(false) // this needs to stay false because images that appear clipped are still overlapping hidden, blocking other cards
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    .overlay(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.5)]), startPoint: .top, endPoint: .bottom).cornerRadius(20))
                    .cornerRadius(25, corners: [.bottomLeft, .bottomRight])
                VStack {
                    Spacer()
                    previewCircle
                        .padding(.top, 30)
                        .padding(.bottom, BrandPadding.Small.pixelWidth)
                    LabelView(text: product.name, style: .largeSwatchTitle)
                        .padding(.horizontal, BrandPadding.Small.pixelWidth)
                    LabelView(text: categoryName, style: .largeSwatchSubtitle)
                        .padding(.horizontal, BrandPadding.Small.pixelWidth)
                    Spacer()
                    LabelView(text: product.brandName, style: .largeSwatchFooter)
                        .frame(height: 30)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                }
            }
            .frame(height: height ?? 260)
            .frame(minWidth: lockedWidth, maxWidth: lockedWidth ?? imageWidth)
            .overlay(FavoriteBadge(isVisible: showsFavoriteBadge, isFavorite: isFavorite, favoriteAction: favoriteBtnAction, unfavoriteAction: unfavoriteBtnAction), alignment: .topTrailing)
            .cornerRadius(20)
        }
    }
    
    var previewCircle: some View {
        if product.productType == .productWithVariations, let variationIndex = product.variationIndex, (product.variations?.count ?? -1) > variationIndex, let variation = product.variations?[variationIndex] {
            return PreviewCircle(type: .swatch(product: variation), size: orbSize(), hasShadow: true)
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 5))
        } else {
            return PreviewCircle(type: .swatch(product: product), size: orbSize(), hasShadow: true)
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 5))
        }
    }
    
    func orbSize() -> CGSize {
        
        guard let height = height else {
            if let lockedWidth = lockedWidth, lockedWidth > 300 {
                return CGSize(width: lockedWidth / 4, height: lockedWidth / 4)
            } else
            if imageWidth > 300 {
                return CGSize(width: imageWidth / 4, height: imageWidth / 4)
            }
            return CGSize(width: 65, height: 65)
        }

        guard let lockedWidth = lockedWidth else {
            if height > imageWidth, imageWidth > 300 {
                return CGSize(width: imageWidth / 4, height: imageWidth / 4)
            } else if height < imageWidth, height > 300 {
                return CGSize(width: height / 4, height: height / 4)
            }
            return CGSize(width: 65, height: 65)
        }

        if height > lockedWidth, lockedWidth > 300 {
            return CGSize(width: lockedWidth / 4, height: lockedWidth / 4)
        } else if height < lockedWidth, height > 300 {
            return CGSize(width: height / 4, height: height / 4)
        }

        return CGSize(width: 65, height: 65)
    }
}

// MARK: - Preview

struct ProductCard_Previews: PreviewProvider {
    static var text = ""
    
    static var previews: some View {
        ZStack {
            PreviewHelperView(axis: .horizontal) {
                if let product = loadProduct() {
                    VStack(spacing: 20) {
                        ProductCard(product: product, size: .large, isFavorite: true, favoriteBtnAction: {}, unfavoriteBtnAction: {})
                        ProductCard(product: product, size: .medium, isFavorite: true, favoriteBtnAction: {}, unfavoriteBtnAction: {})
                        ProductCard(product: product, size: .small, isFavorite: false, favoriteBtnAction: {}, unfavoriteBtnAction: {})
                    }.frame(maxHeight: .infinity)
                    .padding()
                    .background(BrandColors.backgroundView.color)
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
