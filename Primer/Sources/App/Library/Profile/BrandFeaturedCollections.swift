//
//  BrandFeaturedCollections.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/13/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine
import Combine



// MARK: Brand Featured Collections

struct BrandFeaturedCollections: View {
    @Environment(\.analytics) var analytics
    @StateObject var collectionsRepo = ProductCollectionsRepository()
    var savedBrand: SavedBrandManager
    var isNavHidden: Binding<Bool>
    var appState: Binding<AppState>
    var client: APIClient
    var containerWidth: CGFloat
    var onSelectProduct: (Repository<[ProductModel]>, Int, Int) -> Void

    // MARK: - Body
    
    var body: some View {
        if collectionsRepo.value.count == 0 {
            ActivityIndicatorView()
                .padding()
                .opacity(collectionsRepo.value.count > 0 ? 0: 1)
                .onAppear() {
                    if let brand = savedBrand.brand {
                        collectionsRepo.setBrandId(brandID: brand.id)
                        savedBrand.refreshBrandId()
                    }
                }
        } else {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(collectionsRepo.value.indices, id: \.self) { index in
                        BrandFeaturedCollectionCardView(
                            savedBrand: savedBrand,
                            collection: collectionsRepo.value[index],
                            isNavHidden: isNavHidden,
                            appState: appState,
                            client: client,
                            cardWidth: collectionsRepo.value.count > 1 ? (isDeviceIpad() ? containerWidth * 0.4 : containerWidth * 0.6) : (isDeviceIpad() ? containerWidth * 0.5 : containerWidth - 40), cardIndex: index, onSelectProduct: onSelectProduct)
                            .analytics(analytics)
                            .onAppear {
                                if index > 0 && collectionsRepo.value.count - index <= 5 {
                                    collectionsRepo.append()
                                }
                            }
                    }
                }.padding(.horizontal, BrandPadding.Medium.pixelWidth)
            }
        }
    }
}

// MARK: - Collection Scroll View

struct BrandFeaturedCollectionCardView: View {
    @Environment(\.analytics) var analytics
    @StateObject var collectionRepo: ProductCollectionRepository
    @State var savedBrand: SavedBrandManager
    @State private var cancellable: AnyCancellable? = nil
    @State var showSignUp: Bool = false
    var collection: ProductCollectionModel
    var cardId: ProductCardScrollId = .brandFeaturedCollection
    var isNavHidden: Binding<Bool>
    var appState: Binding<AppState>
    var client: APIClient
    var cardWidth: CGFloat
    var cardIndex: Int
    
    var onSelectProduct: (Repository<[ProductModel]>, Int, Int) -> Void
     
    init(savedBrand: SavedBrandManager, collection: ProductCollectionModel, isNavHidden: Binding<Bool>, appState: Binding<AppState>, client: APIClient, cardWidth: CGFloat, cardIndex: Int, onSelectProduct: @escaping (Repository<[ProductModel]>, Int, Int) -> Void) {
        self._collectionRepo = StateObject(wrappedValue: ProductCollectionRepository())
        self._savedBrand = State(wrappedValue: savedBrand)
        self.collection = collection
        self.isNavHidden = isNavHidden
        self.appState = appState
        self.client = client
        self.cardWidth = cardWidth
        self.cardIndex = cardIndex
        self.onSelectProduct = onSelectProduct
    }
    
    // MARK: - Body
    
    var body: some View {
        if collectionRepo.value.count == 0, collectionRepo.requestState != .complete {
            ActivityIndicatorView()
                .frame(width: cardWidth > 0 ? cardWidth : 260, height: 220)
                .onAppear {
                    self.collectionRepo.setCollectionId(collectionId: collection.id)
                }
        } else {
            ProductCollectionCard(collectionRepo: collectionRepo, collection: collection, shouldOffsetTimer: (cardIndex % 2 != 0), cardWidth: cardWidth)
                .onTapGesture {
                    isNavHidden.wrappedValue = false
                    self.savedBrand.tappedIndex = cardIndex
                    self.appState.selectedCollectionId.wrappedValue = savedBrand.savedCollection?.id
                    self.appState.savedProduct.wrappedValue = nil
                    // constructs the label text for product details footer
                    if let brand = savedBrand.brand {
                        self.appState.orbCollectionString.wrappedValue = "\(brand.name), \(collection.name)"
                    }
                }
        }
    }
}

// MARK: - Preview
//
//struct BrandFeaturedCollections_Previews: PreviewProvider {
//    static var previews: some View {
//        BrandFeaturedCollections()
//    }
//}
