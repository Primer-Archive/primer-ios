//
//  ProductCardGridView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/29/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine
import Combine

/**
 Reusable ProductCard Grid. Defaults to `.large` style `ProductCard`s on a vertical axis, with 1 row/column. Default behavior appends more products when last few items appear. This should begin to replace the `ProductGridView` as more sections are updated to the new `ProductCard` UI styling.
 */
struct ProductCardGridView: View {
    @Environment(\.analytics) var analytics
    @ObservedObject var productsRepo: Repository<[ProductModel]>
    @Binding var showingSignup: Bool
    @State private var cancellable: AnyCancellable? = nil
    
    var appState: Binding<AppState>
    var client: APIClient
    var location: ViewLocation
    var axis: Axis.Set = .vertical
    var cardSize: ProductCardSize = .large
    var customCardHeight: CGFloat?
    var imageWidth: CGFloat = 250
    var lockedCardWidth: CGFloat? = nil
    var numberOfGridItems: Int = 1
    var shouldFlatten: Bool = false
    var canToggleFavorites: Bool = true
    var cardId: ProductCardScrollId = .unspecified
    var onTap: (Int, Int, Int) -> Void
    var onComplete: () -> Void = {}
    var onFavorite:() -> Void = {}
    var favorites: [Int] {
        self.appState.wrappedValue.favoriteProductIDs
    }
    
    var gridItems: [GridItem] {
        var items: [GridItem] = []
        for _ in 0..<numberOfGridItems {
            items.append(GridItem(.flexible(), spacing: BrandPadding.Small.pixelWidth))
        }
        return items
    }
    
    // MARK: - Body
    var body: some View {
        return Group {
            if productsRepo.requestState == .refresh {
                ActivityIndicatorView()
                    .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 500)
                    
            } else if productsRepo.value.count == 0, productsRepo.requestState == .complete {
                noResultsView
                    .onAppear {
                        self.onComplete()
                    }
            } else {
                switch axis {
                case .horizontal:
                    HStack {
                        LazyHGrid(rows: gridItems, alignment: .top, spacing: BrandPadding.Medium.pixelWidth) {
                            content
                        }.onAppear { onComplete() }

                        if productsRepo.requestState == .append {
                            ActivityIndicatorView()
                                .frame(width: 75)
                                .frame(maxHeight: .infinity)
                        }
                    }
                case .vertical:
                    VStack {
                        LazyVGrid(columns: gridItems, spacing: BrandPadding.Medium.pixelWidth) {
                            content
                        }.onAppear { onComplete() }

                        if productsRepo.requestState == .append {
                            ActivityIndicatorView()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                default:
                    Color.clear
                        .frame(maxWidth: 50, minHeight: 50, maxHeight: 50)
                }
            }
        }.padding(BrandPadding.Small.pixelWidth)
    }
    
    // MARK: - Product Cards
    
    var content: some View {
        if shouldFlatten, let flattened = flattenedProducts {
            return ForEach(flattened.indices, id: \.self) { index in
                ProductCard(product: flattened[index], size: cardSize, height: customCardHeight, imageWidth: imageWidth, lockedWidth: lockedCardWidth, isFavorite: self.favorites.contains(flattened[index].id), favoriteBtnAction: {
                    if self.canToggleFavorites {
                        self.favorite(product: flattened[index])
                    }
                }, unfavoriteBtnAction: {
                    if self.favorites.contains(flattened[index].id) && self.canToggleFavorites {
                        self.unfavorite(product: flattened[index])
                    }
                })
                .id("\(cardId.rawValue)\(flattened[index].id)")
                .onAppear {
                    if index > 0 && flattened.count - index <= 5 {
                        self.productsRepo.append()
                    }
                }
                .onTapGesture {
                    self.onTap(
                        flattened[index].parentId ?? flattened[index].id,
                        flattened[index].variationIndex ?? 0,
                        flattened[index].id)
                    if cardId == .favorites {
                        appState.savedFavorite.wrappedValue = AppState.SavedProduct(id: flattened[index].id, locationId: cardId)
                    } else {
                        appState.savedProduct.wrappedValue = AppState.SavedProduct(id: flattened[index].id, locationId: cardId)
                    }
                }
            }
            .clipped()
        } else {
            return ForEach(productsRepo.value.indices, id: \.self) { index in
                ProductCard(product: productsRepo.value[index], size: cardSize, height: customCardHeight, imageWidth: imageWidth, lockedWidth: lockedCardWidth, isFavorite: favorites.contains(productsRepo.value[index].id), favoriteBtnAction: {
                    if self.canToggleFavorites {
                        self.favorite(product: productsRepo.value[index])
                    }
                }, unfavoriteBtnAction: {
                    if self.favorites.contains(productsRepo.value[index].id) && self.canToggleFavorites {
                        self.unfavorite(product: productsRepo.value[index])
                    }
                })
                .id("\(cardId.rawValue)\(productsRepo.value[index].id)")
                .onAppear {
                    if index > 0 && self.productsRepo.value.count - index <= 5 {
                        self.productsRepo.append()
                    }
                }
                .onTapGesture {
                    self.onTap(
                        productsRepo.value[index].parentId ?? productsRepo.value[index].id,
                        productsRepo.value[index].variationIndex ?? 0,
                        productsRepo.value[index].id)
                    if cardId == .favorites {
                        appState.savedFavorite.wrappedValue = AppState.SavedProduct(id: productsRepo.value[index].id, locationId: cardId)
                    } else {
                        appState.savedProduct.wrappedValue = AppState.SavedProduct(id: productsRepo.value[index].id, locationId: cardId)
                    }
                }
            }
            .clipped()
        }
    }
    
    // MARK: - No Results View
    
    var noResultsView: some View {
        VStack(spacing: BrandPadding.Medium.pixelWidth) {
            LabelView(text: "No results found", style: .search)
            Image("ThinkingFullSizeIllustration")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .padding(BrandPadding.Medium.pixelWidth)
        .frame(maxWidth: isDeviceIpad() ? 428 : .infinity)
    }
    
    // MARK: - Flatten

    public var flattenedProducts: [ProductModel]? {
        var flattened: [ProductModel] = []

        self.productsRepo.value.forEach { product in
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
    
    // MARK: - Favorite

    func favorite(product: ProductModel) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        self.analytics?.didTapFavorite(product, isAdded: true, from: location)
        if AuthController.shared.isLoggedIn, let client = AuthController.shared.apiClient, !appState.favoriteProductIDs.wrappedValue.contains(product.id) {
            self.cancellable = client.addFavoriteProduct(product.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                            case .finished:
                                self.analytics?.favoriteComplete(product)
                                appState.favoriteProductIDs.wrappedValue.append(product.id)
                                self.onFavorite()
                                break
                            case .failure(let error):
                                print(error.localizedDescription)
                        }
                    },
                    receiveValue: { _ in })
        } else {
            UserDefaults.loggedOutFavorite = product.id
            self.showingSignup.toggle()
        }
    }
    
    // MARK: - Unfavorite
    
    func unfavorite(product: ProductModel) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        self.analytics?.didTapFavorite(product, isAdded: false, from: location)
        if AuthController.shared.isLoggedIn, let client = AuthController.shared.apiClient {
            self.cancellable = client.removeFavoriteProduct(product.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                            case .finished:
                                appState.favoriteProductIDs.wrappedValue.removeAll(where: { $0 == product.id })
                                break
                            case .failure(let error):
                                print(error.localizedDescription)
                        }
                    },
                    receiveValue: { _ in
                        client.favoritesRepo.refresh()
                    })
        }
    }
}

// MARK: - Preview

struct ProductCardGridView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        PreviewHelperView(axis: .vertical) {
            VStack {
                if let repo = loadTestProducts() {
                    ScrollView(.vertical) {
                        ProductCardGridView(productsRepo: repo, showingSignup: .constant(false), appState: .constant(.initialState), client: .init(), location: .gridView, numberOfGridItems: 2, onTap: {_,_,_ in })
                    }.frame(height: 200)
                    Divider()
                    ScrollView(.horizontal) {
                        ProductCardGridView(productsRepo: repo, showingSignup: .constant(false), appState: .constant(.initialState), client: .init(), location: .gridView, axis: .horizontal, numberOfGridItems: 1, onTap: {_,_,_ in })
                    }.frame(height: 200)
                    .clipped()
                }
            }
        }
    }

    static func loadTestProducts() -> Repository<[ProductModel]>? {
        var testProducts: [ProductModel] = []
        for _ in 0...7 {
            let decoder = JSONDecoder()
            guard let url = Bundle.main.url(forResource: "product", withExtension: "json") else {
                return nil
            }
            guard let data = try? Data(contentsOf: url) else {
                return nil
            }
            guard let prod = try? decoder.decode(ProductModel.self, from: data) else {
                return nil
            }
            testProducts.append(prod)
        }
        let repo = PreviewTesterRepository(models: testProducts)
        return repo
    }
}

