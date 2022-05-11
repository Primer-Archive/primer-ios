//
//  ProductDetailCard.swift
//  Primer
//
//  Created by Sarah Hurtgen on 12/9/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

/**
 This card toggles between two main states, expanded and compact - displaying an overview of the current product. Defaults to the compact version, and expands based on it's `isExpanded` binding.
 
 The App Clips version for this displays a SIWA button while expanded (and logged out) instead of the favorite button.
 */
struct ProductDetailCard: View {

    @Namespace var cardNamespace
    @Namespace var imageNamespace
    @Namespace var buttonBackerNamespace
    @Namespace var leftButtonNamespace
    @Namespace var rightButtonNamespace
    
    @Binding var favorites: [Int]
    @Binding var isExpanded: Bool
    @Binding var isLoadingSIWA: Bool
    @Binding var isShareReady: Bool
    
    var appState: Binding<AppState>
    var client: APIClient
    var product: ProductModel?
    let gradient = Gradient(colors: [
                        BrandColors.shadowedBackground.color,
                        BrandColors.shadowedBackground.color,
                        BrandColors.shadowedBackground.color,
                        BrandColors.shadowedBackground.color.opacity(0)])
    let shareAction: () -> Void
    let buyAction: () -> Void
    let favoriteAction: () -> Void

    // MARK: - Body
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                
                // MARK: - Compact View
                
                VStack {
                if !isExpanded, let product = product {
                    HStack(spacing: 0) {
                        
                        // thumbnail image
                        RemoteImageView(url: product.featuredImages.first, width: 54) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .matchedGeometryEffect(id: "ImageView", in: imageNamespace, anchor: .bottomLeading, isSource: true)
                        .frame(width: 54, height: 54)
                        .cornerRadius(13)
                        .padding(.horizontal, 7)
                        .id("ThumbnailID\(product.id)")

                        VStack(alignment: .leading) {
                            LabelView(text: product.name, style: .cardTitle)
                            LabelView(text: "\(product.brandName)\(product.brandName.count >= 20 ? "\n" : " - ")view details", style: .cardSubtitleLeading)
                        }

                        Spacer()
                        
                        // MARK: - Compact Buttons
                        
                        HStack {
                            SmallSystemIcon(style: .cartFill, isButton: true, btnAction: buyAction)
                                .matchedGeometryEffect(id: "LeftButton", in: leftButtonNamespace, isSource: true)
                            SmallSystemIcon(style: self.favorites.contains(product.id) ? .heartFill : .heartOutline, isButton: true, btnAction: favoriteAction)
                                .matchedGeometryEffect(id: "RightButton", in: rightButtonNamespace, isSource: true)
                        }
                        .padding(.horizontal, BrandPadding.Small.pixelWidth)
                        .matchedGeometryEffect(id: "Buttons", in: buttonBackerNamespace, isSource: true)
                    }
                    .padding(.top, 7)
                    .frame(maxHeight: 60)
                    .matchedGeometryEffect(id: "ProductCard", in: cardNamespace, isSource: false)
                }
                    
                    // MARK: - Compact Footer
                    
                    HStack(spacing: 0) {
                        LabelView(text: "Products:", style: .singleLineLight12M).opacity(0.70)
                            .padding(.trailing, 4)
                        LabelView(text: "\(appState.wrappedValue.orbCollectionString)", style: .singleLineLight12M)
                        Spacer()
                        SmallSystemIcon(style: .rectangleFillOnRectFill).opacity(0.70)
                    }
                    .frame(height: isExpanded ? 0 : 28)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, BrandPadding.Smedium.pixelWidth)
                    .background(BrandColors.blueGrey.color)
                }
                
                
                // MARK: - Expanded View
                
                if isExpanded, let product = product {
                    VStack {
                        ZStack(alignment: .bottom) {
                            
                            // this applies the background for when a user "pulls" on the scrollview
                            VStack {
                                BrandColors.navy.color
                                BrandColors.backgroundView.color
                            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: BrandPadding.Medium.pixelWidth) {
                                    
                                    // full size images
                                    CarouselView(product: product, isExpanded: isExpanded)
                                        .background(isExpanded ? BrandColors.navy.color : BrandColors.backgroundView.color)
                                        .matchedGeometryEffect(id: "ImageView", in: imageNamespace, anchor: .bottomLeading)
                                        .frame(maxWidth: .infinity, idealHeight: 360)
                                        .frame(height: isDeviceIpad() ? nil : 340)
                                        .id("CarouselID\(product.id)")

                                    HStack(spacing: 0) {
                                        VStack(alignment: .leading) {
                                            LabelView(text: product.name, style: .cardHeader)
                                            LabelView(text: product.brandName, style: .bodyMedium) // link this to product brand page once state management is ready, and set style to .buttonMedium
                                        }
                                        
                                        if let brand = client.brandsRepo.value.first(where: { $0.id == product.brandId }) {
                                            Spacer()
                                            
                                            PreviewCircle(type: .brand(url: brand.logo), size: CGSize(width: 37, height: 37), hasShadow: true)
                                                .id("BrandCircle\(brand.id)")
                                        }
                                    }.padding(.horizontal, BrandPadding.Medium.pixelWidth)
                                        
                                    LabelView(text: product.description.capitalizingFirstLetter(), style: .bodyLeading)
                                        .padding(.horizontal, BrandPadding.Medium.pixelWidth)
                                    
                                    // MARK: - Info Chart
                                    // Rounded Rect Chart, to be used when we have product price, material, details, etc
//                                    GeometryReader { proxy in
//                                        HStack(spacing: 0) {
//
//                                            LazyVStack(alignment: .trailing, spacing: BrandPadding.Tiny.pixelWidth) {
//                                                LabelView(text: "Price", style: .bodyTrailingMedium)
//                                                LabelView(text: "Material", style: .bodyTrailingMedium)
//                                            }.frame(width: (proxy.size.width / 2) - 10)
//                                            Spacer()
//                                                .frame(width: BrandPadding.Medium.pixelWidth)
//                                            LazyVStack(alignment: .leading, spacing: BrandPadding.Tiny.pixelWidth) {
//                                                LabelView(text: "$__ per roll", style: .bodyLeading) // - add price
//                                                LabelView(text: "Material Example", style: .bodyLeading) // - add material
//                                            }.frame(width: (proxy.size.width / 2) - 10)
//                                        }
//                                        .frame(maxWidth: .infinity)
//                                        .padding(.vertical, BrandPadding.Medium.pixelWidth)
//                                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(BrandColors.softWhiteToggleGrey.color, lineWidth: 1))
//                                    }
//                                    .padding(.horizontal, BrandPadding.Medium.pixelWidth)
                                    
                                    Spacer()
                                        .frame(minHeight: 100)
                                }.background(BrandColors.backgroundView.color)
                            }.overlay(LinearGradient(gradient: gradient, startPoint: .bottom, endPoint: .top).frame(height: isExpanded ? 120 : 0).allowsHitTesting(false), alignment: .bottom)
                            
                            // MARK: - Header Buttons
                            
                            VStack {
                                HStack {
                                    SmallSystemIcon(style: .x12, isButton: true) {
                                        withAnimation(.easeInOut(duration: 0.33)) {
                                            isExpanded.toggle()
                                        }
                                    }
                                    Spacer()
                                    SmallSystemIcon(style: .shareSquareNavy, isButton: true, btnAction: shareAction)
                                        .opacity(isShareReady ? 1 : 0.5)
                                        .allowsHitTesting(isShareReady)
                                }.padding(BrandPadding.Small.pixelWidth)
                                
                                Spacer()
                            }
                            
                            // MARK: - Expanded Buttons
                            
                            HStack(spacing: 10) {
                                Button("Buy") {
                                    buyAction()
                                }
                                .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .sandBlueOutline, cornerRadius: 30))

                                .matchedGeometryEffect(id: "LeftButton", in: leftButtonNamespace)
                                
                                #if !APPCLIP
                                Button(self.favorites.contains(product.id) ? "Unfavorite" : "Favorite") {
                                    favoriteAction()
                                }
                                .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blueFilledAndOutline, cornerRadius: 30))

                                .matchedGeometryEffect(id: "RightButton", in: rightButtonNamespace)
                                #else
                                if !AuthController.shared.isLoggedIn {
                                    ButtonSignInWithApple(isLoading: $isLoadingSIWA,
                                        appState:appState,
                                        buttonType: .signIn, client: self.client, location: .expandedDetailView)
                                    { error in
                                        print("Error")
                                    } completeSignupAction: { _ in
                                        //
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: 48)
                                    .cornerRadius(100)
                                } else {
                                    Button(self.favorites.contains(product.id) ? "Unfavorite" : "Favorite") {
                                        favoriteAction()
                                    }
                                    .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blueFilledAndOutline, cornerRadius: 30))
                                }
                                #endif
                            }
                            .padding(.horizontal, BrandPadding.Medium.pixelWidth)
                            .padding(.vertical, BrandPadding.Smedium.pixelWidth)
                            .background(BrandColors.backgroundView.color)
                            .matchedGeometryEffect(id: "Buttons", in: buttonBackerNamespace)
                        }

                    }.matchedGeometryEffect(id: "ProductCard", in: cardNamespace)
                    .background(BrandColors.backgroundView.color)
                    .frame(maxHeight: 650)
                }
            }
        }
        .frame(maxWidth: isDeviceIpad() ? 520 : .infinity)
        .background(BrandColors.backgroundView.color)
    }
    
}

// MARK: - Preview

struct ProductDetailView_Previews: PreviewProvider {
    static var text = ""

    static var previews: some View {
        ZStack {
            if let product = loadProduct() {
                GeometryReader { proxy in
                    ProductDetailCard(favorites: .constant([]), isExpanded: .constant(false), isLoadingSIWA: .constant(false), isShareReady: .constant(true), appState: .constant(.initialState), client: APIClient(), product: product, shareAction: {}, buyAction: {}, favoriteAction: {})
                    
                }
            } else {
                Text(text)
            }
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
