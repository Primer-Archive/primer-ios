//
//  FeaturedProductsView.swift
//  Primer
//
//  Created by James Hall on 7/20/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine
import Combine

/**
 Sets up the "Inspiration" product grid. Lazy loads cells and fetches from API when 5 cells away from the bottom. Displays in two columns on ipad, single column for iphone.
 */
struct FeaturedProductsView: View {
    var appState: Binding<AppState>
    var client: APIClient
    
    @Environment(\.analytics) var analytics
    @State var imageSizes: [Int] = []
    @State private var cancellable: AnyCancellable? = nil
    @ObservedObject var productsRepo: Repository<[ProductModel]>

    var containerWidth: CGFloat
    var onTap: (Int, Int, Int) -> Void
    
    private static let columnCount = UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
    private static let gutterWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 24 : 4
    
    let textHeight: CGFloat = 24
    let textTopPadding: CGFloat = 12
    
    var tileWidth: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return (containerWidth / 2) - 40
        } else {
            return containerWidth - 40
        }
    }
    
    var columns: [GridItem] {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [GridItem(.adaptive(minimum: tileWidth), spacing: 24), GridItem(.adaptive(minimum: tileWidth))]
        } else {
            return [GridItem(.fixed(tileWidth))]
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: BrandPadding.Small.pixelWidth) {
            ForEach(productsRepo.value.indices, id: \.self) { item in
                self.view(for: item)
                .onAppear {
                    let location = self.productsRepo.value.firstIndex(of: self.productsRepo.value[item]) ?? -1
                    if location > 0 && self.productsRepo.value.count - location <= 5 {
                        self.productsRepo.append()
                    }
                }
            }
        }.padding(.horizontal, BrandPadding.Medium.pixelWidth)
    }
    
    // MARK: - Tile
    
    private func view(for index: Int) -> some View {
        let product = productsRepo.value[index]
        let isFavorite = self.appState.wrappedValue.favoriteProductIDs.contains(product.id)
        let result: AnyView
        
        if let firstImageURL = (product.featuredImages[product.featuredProductImage - 1] as URL?) {
            let view =
                VStack(spacing: 5) {
                    RemoteImageView(url: firstImageURL, width: self.tileWidth) { image in
                        image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: self.tileWidth, height: self.tileWidth)
                    }.frame(width: tileWidth, height: tileWidth)
                    .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: SwiftUI.Color.black.opacity(0.3), radius: 6.0, x: 0.0, y: 0.0)
                    .overlay(FavoriteBadge(isFavorite: isFavorite, favoriteAction: {
                        self.favorite(product: product)
                    }, unfavoriteAction: {
                        self.unfavorite(product: product)
                    }), alignment: .topTrailing)
                    .onTapGesture {
                        self.analytics?.didSelectProductInInspirationView(product: product)
                        self.onTap(product.parentId ?? product.id,
                                   product.variationIndex ?? 0,
                                   product.id)
                    }.padding(.bottom, BrandPadding.Tiny.pixelWidth)
                    
                    HStack(alignment: .bottom) {
                        LabelView(text: product.name, style: .cardTitle)
                        Spacer()
                    }.frame(maxWidth: tileWidth)

                    HStack(alignment: .bottom) {
                        LabelView(text: product.brandName, style: .cardSubtitle)
                        Spacer()
                    }.frame(maxWidth: tileWidth)
                    
                }
                .padding(.top, BrandPadding.Medium.pixelWidth)
            result = AnyView(view)
        } else {
            let glyph = Image(systemName: SFSymbol.exclamationTriangleFill.rawValue)
                .foregroundColor(Color.secondary)
            let view = glyph
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray)
                .onTapGesture {
                    self.onTap(product.parentId ?? product.id,
                               product.variationIndex ?? 0,
                               product.id)
                }
            result = AnyView(view)
        }
        return result
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
    
    // MARK: - Set Favorite
    
    func favorite(product: ProductModel) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        self.analytics?.didTapFavorite(product, isAdded: true, from: .featuredView)
        if AuthController.shared.isLoggedIn, let client = AuthController.shared.apiClient, !appState.favoriteProductIDs.wrappedValue.contains(product.id) {
            self.cancellable = client.addFavoriteProduct(product.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                            case .finished:
                                self.analytics?.favoriteComplete(product)
                                appState.favoriteProductIDs.wrappedValue.append(product.id)
                                break
                            case .failure(let error):
                                print(error.localizedDescription)
                        }
                    },
                    receiveValue: { _ in })
        } else {
            UserDefaults.loggedOutFavorite = product.id
        }
    }
    
    // MARK: - Remove Favorite
    
    func unfavorite(product: ProductModel) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        self.analytics?.didTapFavorite(product, isAdded: false, from: .featuredView)
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
                    receiveValue: { _ in })
        }
    }
}
