//
//  FeaturedProductCollectionsView.swift
//  Primer
//
//  Created by James Hall on 7/20/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine


/**
 This is the Featured Collection that displays the current themed featured products at the top of the Products Drawer.
 */
struct FeaturedProductCollectionsView: View {
    @Environment(\.analytics) var analytics
    @StateObject var collectionRepo = ProductCollectionRepository()
    @ObservedObject var featuredRepos: Repository<[ProductCollectionModel]>
    var client: APIClient
    var appState: Binding<AppState>
    var onTap: (Repository<[ProductModel]>, Int, Int) -> Void
    var isDeviceIpad: Bool = (UIDevice.current.userInterfaceIdiom == .pad)

    init(client: APIClient, appState: Binding<AppState>, onTap: @escaping (Repository<[ProductModel]>, Int, Int) -> Void) {
        self.client = client
        self.appState = appState
        self.onTap = onTap
        self.featuredRepos = client.featuredCollectionRepo
    }
       
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(self.featuredRepos.value) { featuredProductCollection in
                FadingLabel(text: featuredProductCollection.name, style: .sectionHeader, offset: 70)
                    .frame(maxHeight: 34)
                    .padding(.vertical, isDeviceIpad ? BrandPadding.Smedium.pixelWidth : 0)
                
                // setup to support if there were more than one featured collection at a time
                ScrollView(.horizontal) {
                        LazyHStack(spacing: isDeviceIpad ? 24 : 16) {
                            ForEach(featuredProductCollection.products ?? [], id: \.id) { product in
                                ProductCard(product: product, size: .medium, height: isDeviceIpad ? 190 : 150, isFavorite: false, showsFavoriteBadge: false, favoriteBtnAction: {}, unfavoriteBtnAction: {})
                                    .onTapGesture {
                                        //we are returning all of the products in the featuredCollectionRepo results.
                                        //so pass down that info
                                        collectionRepo.loadedLastPage = true
                                        collectionRepo.setProductsAndID(products: featuredProductCollection.products!,
                                                                        collectionId: featuredProductCollection.id)
                                        self.analytics?.didSelectFeaturedProduct(product, from: featuredProductCollection)
                                        self.onTap(collectionRepo, product.id, 0)
                                        // sets label text for product details footer
                                        self.appState.orbCollectionString.wrappedValue = "\(featuredProductCollection.name)"
                                    }
                                //as of right now, we're not appending featurd products, we'll send all at once.
//                                    .onAppear {
//                                        let location = featuredProductCollection.products!.firstIndex(of: product) ?? -1
//                                        if location > 0 && collectionRepo.value.count - location <= 5 {
//                                            collectionRepo.append()
//                                        }
//                                    }
                            }
                            .frame(width: isDeviceIpad ? 300 : 240, height: isDeviceIpad ? 240 : 182)
                        }.padding(.horizontal, BrandPadding.Medium.pixelWidth)
                        .padding(.bottom, isDeviceIpad ? BrandPadding.Tiny.pixelWidth : BrandPadding.Small.pixelWidth)
                }
            }
        }.frame(height: CGFloat(self.featuredRepos.value.count) * (isDeviceIpad ? 280 : 226))
    }
    
    // MARK: - Flatten
    
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
