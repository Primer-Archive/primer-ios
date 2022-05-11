//
//  ContentView.swift
//  PrimerAppClip
//
//  Created by James Hall on 6/29/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import Combine
import PrimerEngine
import AuthenticationServices

fileprivate var client = APIClient()




internal let analyticInstance = Analytics()

private let deepLinkHandler = DeepLinkHandler(client: client, analyticInstance: analyticInstance)


struct MainView: View {
    
    @State var appState: AppState = .initialState
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State internal var hideProductDetailsCard = false
    
    @State internal var isShowingMenuOption = false
    
    @State var measurementCardOffset: CGFloat = 100
    
    @State var isLoading = true
    
    @State var timer: PermissionsTimer?
    
    @ObservedObject private var authController = CameraAuthorizationController.shared
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var bottomSpacing: CGFloat {
            return 75
    }
    
    
    private var showingVariations: Bool {
        return appState.selectedProduct != nil && appState.selectedProduct?.variations != nil
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(spacing:0.0){
                    EngineContainer(proxy: proxy, appState: self.$appState, client: client).analytics(analyticInstance)
                        .frame(height: UIScreen.main.bounds.height - self.bottomSpacing)
                    
                    MainNavView(
                        bottomInset:proxy.safeAreaInsets.bottom,
                        buttons:[
                            MainNavViewItem(buttonText: "Products", buttonIconName: SFSymbol.rectangleOnRectFill.rawValue, buttonAction: {
                                analyticInstance.didOpenProductsSheet()
                                self.appState.visibleSheet = .brandView
                                self.isShowingMenuOption.toggle()
                                if(self.appState.helpModalType == .browseMoreProductsCTA){
                                    UserDefaults.hasSeenBrowseProductsHelper = true
                                    analyticInstance.didOpenProductsSheetFromPrompt(product: self.appState.selectedProduct)
                                }
                            }),
                            MainNavViewItem(buttonText: "Saved", buttonIconName: SFSymbol.heartTextSquareFill.rawValue, buttonAction:{
                                self.appState.visibleSheet = .saved
                                self.isShowingMenuOption.toggle()
                            }),
                            MainNavViewItem(buttonText: "Account", buttonIconName: SFSymbol.personCropCircleFill.rawValue, buttonAction:{
                                
                                self.appState.visibleSheet = .about
                                self.isShowingMenuOption.toggle()
                            }),
                        ])

                }
                .overlay(MainViewOverlays(appState:self.$appState).analytics(analyticInstance))
                
                PopOverView(bindingVisible: $appState.showMeasurementHelper, alignment: .bottom, offset: 0, showModalOffset: UIScreen.main.bounds.height / 2) {
                    MeasurementsExpandedView(isPaint: appState.selectedProduct?.productCategory == 1, measurementHelper: MeasurementHelper(width: appState.engineState.swatch?.size.width, height: appState.engineState.swatch?.size.height))
                        .frame(maxWidth: 420)
                        .modifier(SwipeModifier(currentPosition: $measurementCardOffset, isVisible: $appState.showMeasurementHelper, offsetHeight: UIScreen.main.bounds.height / 2, dismissAction: {}))
                }
                
                if !UserDefaults.hasSeenIntro {
                    NUXView(appState: self.$appState) {
                        UserDefaults.hasSeenIntro = true
                    }
                        .opacity(self.appState.isShowingNUX ? 1 : 0)
                        .transition(.opacity)
                        .analytics(analyticInstance)
                }
                
            }
        }
        .onAppear {
            if !appState.hasCameraAccess && UserDefaults.hasSeenIntro {
                authController.requestAccess(completion: { success in
                    analyticInstance.cameraPermissionsSelected(authController.authorizationStatus.rawValue, location: .appClipNux)
                    if success {
                        self.appState.engineState.isRunning = true
                    } else {
                        print("fail")
                    }
                })
            } else {
                if timer == nil {
                    self.timer = PermissionsTimer(sinkAction: startAndResetEngine)
                }
            }
        //            client.brandsController.refresh()
            if let userID = AuthController.shared.siwaToken {
                let appleIDProvider = ASAuthorizationAppleIDProvider()
                appleIDProvider.getCredentialState(forUserID: userID) { (state, error) in
                    DispatchQueue.main.async {
                        switch state {
                            case .authorized: // valid user id
                                client = AuthController.shared.apiClient ?? client
                                client.getCurrentUser()
                                .receive(on: DispatchQueue.main)
                                .sink(
                                    receiveCompletion: { _ in },
                                    receiveValue: { user in
                                        analyticInstance.signInMixpanelUser(user)
                                        AuthController.shared.currentUser = user
                                        if let favoriteIds = user.favorite_product_ids {
                                            self.appState.favoriteProductIDs = favoriteIds
                                        } else {
                                            self.appState.favoriteProductIDs = []
                                        }
                                    })
                                .store(in: &cancellables)
                                break
                            case .revoked: // user revoked authorization
                                AuthController.shared.logOut()
                                break
                            case .notFound: //not found
                                AuthController.shared.logOut()
                                break
                            default:
                                break
                        }
                    }
                }
            }
        }
        .background(BrandColors.navy.color)
        .edgesIgnoringSafeArea(.all)
        .sheet(item: $appState.visibleSheet, content: sheetContent(for:))
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb, perform: respondTo)
        
        // set brand label for details card
        
        .onChange(of: appState.hasCameraAccess, perform: { value in
            if value {
                if self.appState.engineState.isRunning {
                    DispatchQueue.main.async {
                        self.appState.engineState.resetTime = Date().timeIntervalSinceReferenceDate
                    }
                } else {
                    self.appState.engineState.isRunning = true
                }
            }
        })
        .onChange(of: appState.productCollection.value.count, perform: { _ in
            if appState.orbCollectionString == "Inspiration" {
                let product = appState.selectedProduct?.brandSlug ?? ""
                let brand = client.brandsRepo.value.filter { $0.slug == product }
                if brand.count > 0 {
                    appState.orbCollectionString = brand[0].name
                }
            }
        })
    }
    
    func startAndResetEngine() {
        if appState.hasCameraAccess {
            self.appState.engineState.isRunning = true
            DispatchQueue.main.async {
                self.appState.engineState.resetTime = Date().timeIntervalSinceReferenceDate
            }
            
            if appState.engineState.isRunning {
                self.timer = nil
            }
        }
    }
    
    func respondTo(_ activity: NSUserActivity?) {
        
        // Guard against faulty data.
        guard activity != nil else { return }
        guard activity!.activityType == NSUserActivityTypeBrowsingWeb else { return }
        guard let incomingURL = activity?.webpageURL else { return }
        handleDeepLink(incomingURL: incomingURL)
        
        
        // Update the user interface based on URL components passed to the app clip.
    }

    private func handle(engineEvent: EngineEvent, swatch:Swatch) {
    }
    
    
    private func sheetContent(for sheet: AppState.VisibleSheet) -> AnyView {
        
        let onSelectProduct: (Repository<[ProductModel]>, Int, Int) -> Void = { repo, productId, variationIndex in
            
            let productIndex = repo.value.firstIndex(where: { $0.id == productId }) ?? 0
            if self.appState.currentIndex != (Double(productIndex) + 1) {
                self.appState.ignoreIndexChange = true
            }
            self.appState.productCollection = repo
            self.appState.currentVariationIndex = Double(variationIndex)
            self.appState.currentIndex = Double(productIndex) + 1 //we now add a "More Products orb at the beginning, so we have an offset of 1.
            
            self.appState.visibleSheet = nil
            
        }
        
        switch sheet {
            case .capturePreview(let fileURL):
                let view = CapturePreviewView(videoFileURL: fileURL, selectedProduct: appState.selectedProduct).analytics(analyticInstance)
                return AnyView(view)
            case .imagePreview(let image):
                let view = CapturePreviewView(image: image, selectedProduct: appState.selectedProduct).analytics(analyticInstance)
                return AnyView(view)
            case .brandView:
                return AnyView(NavigationView{ BrandViewWrapper(appState: self.$appState, client: client, onSelectProduct: onSelectProduct)})
                
            case .saved:
                let view = FavoritesView(appState: self.$appState,
                                         favoriteProductIDs: $appState.favoriteProductIDs, client: client, location: .favoritesDrawer, onTap:onSelectProduct).analytics(analyticInstance)
                return AnyView(view)
            case .inspiration:
                let view = BrandViewWrapper(appState: self.$appState, client: client, onSelectProduct: onSelectProduct).analytics(analyticInstance)
                return AnyView(NavigationView{ view })
            case .browser:
                //                let view = ProductsView(client: client,onSelectProduct: onSelectProduct, onTap: onSelectProduct).analytics(analyticInstance)
                let view = BrandViewWrapper(appState: self.$appState, client: client, onSelectProduct: onSelectProduct).analytics(analyticInstance)
                return AnyView(view)
            case .about:
                let view = AboutPageView(appState: $appState, client: client).analytics(analyticInstance)
                return AnyView(view)
        }
        
    }
   
}

struct BrandViewWrapper: View {
    @Binding var appState: AppState
    var client: APIClient
    var onSelectProduct: (Repository<[ProductModel]>, Int, Int) -> Void
    
    var body: some View {
        let product = appState.selectedProduct?.brandSlug ?? ""
        let brand = client.brandsRepo.value.filter { $0.slug == product }
        let savedBrand = appState.savedBrandManager
        if brand.count > 0 {
            GeometryReader { proxy in
                BrandPageView(savedBrand: savedBrand, appState: $appState, client: client, containerWidth: proxy.size.width, onSelectProduct: onSelectProduct).analytics(analyticInstance)
                    .onAppear {
                        savedBrand.brand = brand[0]
                    }
            }
            .animation(nil)
        } else {
            Color.gray
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}


//MARK: - View Events
extension MainView{
    private func handleDeepLink(incomingURL: URL) {
        let boundHandler = deepLinkHandler.bind(appState: appState, cancellables: cancellables) { state in
            self.appState = state
        }
        boundHandler.handle(incomingURL: incomingURL)
    }
}



/*
 .backgroundPreferenceValue(BottomCardAnchorKey.self) { anchor in
 self.bottomCardBackground(cardAnchor: anchor, proxy: proxy)
 }
 */
