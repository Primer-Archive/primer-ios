//
//  BrandCollectionGridView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 2/11/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

/**
 The scrollable destination view for a brands featured collection
 */
struct BrandCollectionGridView: View {
    @Environment(\.analytics) var analytics
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var savedBrand: SavedBrandManager
    @State var showSignUp: Bool = false
    @Binding var isNavHidden: Bool
    @Binding var tappedBack: Bool
    var appState: Binding<AppState>
    var client: APIClient
    var cardId: ProductCardScrollId
    var onSelectProduct: (Repository<[ProductModel]>, Int, Int) -> Void
    
    // MARK: - Body
    
    var body: some View {
        ScrollViewReader { scrollview in
            ScrollView(.vertical) {
                VStack {
                    if let collectionRepo = savedBrand.savedCollectionRepo {
                        
                        // MARK: - Products
                        
                        ProductCardGridView(
                            productsRepo: collectionRepo,
                            showingSignup: $showSignUp,
                            appState: appState,
                            client: client,
                            location: .gridView,
                            numberOfGridItems: isDeviceIpad() ? 3 : 2,
                            shouldFlatten: true,
                            cardId: cardId,
                            onTap: { parentOrProductId, variationIndex, productId in
                                self.onSelectProduct(collectionRepo, parentOrProductId, variationIndex)
                            })
                            .analytics(analytics)
                            .onAppear {
                                isNavHidden = false
                                if let tappedProduct = appState.savedProduct.wrappedValue, tappedProduct.locationId == cardId {
                                    scrollview.scrollTo("\(tappedProduct.scrollToId)", anchor: .center)
                                    appState.savedProduct.wrappedValue = nil
                                }
                            }
                            .sheet(isPresented: $showSignUp, content: {
                                FavoritesView(appState: appState,
                                            favoriteProductIDs: appState.favoriteProductIDs,
                                            client: client,
                                            location: .brandViewPopup) { _, _, _ in
                                }.analytics(analyticInstance)
                            })
                    }
                }
            }
        }.background(BrandColors.backgroundView.color)
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitle(savedBrand.savedCollection?.name ?? "", displayMode: .inline)
        .navigationBarHidden(isNavHidden)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
          Button(action: {
            self.appState.selectedCollectionId.wrappedValue = nil
            self.tappedBack = true
            isNavHidden = true
            self.presentationMode.wrappedValue.dismiss()
          }) {
            Image(systemName: SFSymbol.chevronLeft.rawValue)
                .frame(width: 30, height: 40)
        })
    }
}

//struct BrandCollectionGridView_Previews: PreviewProvider {
//    static var previews: some View {
//        BrandCollectionGridView()
//    }
//}
