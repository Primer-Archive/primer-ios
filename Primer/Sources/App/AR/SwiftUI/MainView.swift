import SwiftUI
import PrimerEngine
import Combine
import Photos
#if !targetEnvironment(simulator)
import StoreKit
#endif

import AuthenticationServices

private var bottomCardHeight: CGFloat = 60.0
fileprivate var client = APIClient()
internal let analyticInstance = Analytics()

private let maxScale: CGFloat = 2

private let deepLinkHandler = DeepLinkHandler(client: client, analyticInstance: analyticInstance)

struct MainView: View {
    
    @State var appState: AppState = .initialState
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State internal var isShowingMenuOption = false
    @State private var alertItem: AlertItem? = nil
    @State var currentSurvey: SurveyModel = SurveyModel()
    @State var showSurvey: Bool = false
    @State var showRatingPrompt: Bool = false
    
    @State var measurementCardOffset: CGFloat = 100
    @State var permissionsOffset: CGFloat = 100
    
    @State var isAtMaxScale = false
    
    @Environment(\.navigationCoordinator) var navigation
        
    //lets hope this is a temporary solution, ideally we find a better way to
    //make the EngineContainer and MainNav view share the screen
    //with a home button, proxy.safeAreaInsets.bottom is 34, otherwise it's 0.
    let navHeight: CGFloat = 34
    
    var bottomSpacing: CGFloat {
        if #available(iOS 14.0, *) {
            return 75
        }
        
        return 60
    }

    // MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(spacing:0.0){
                    
                    EngineContainer(proxy: proxy, appState: self.$appState, client: client).analytics(analyticInstance)
                        .frame(height: UIScreen.main.bounds.height - self.bottomSpacing)

                    
                    MainNavView(
                        bottomInset:self.getBottom(proxy:proxy),
                        buttons:[
                            MainNavViewItem(buttonText: "Products", buttonIconName: SFSymbol.rectangleOnRectFill.rawValue, buttonAction: {
                            analyticInstance.didOpenProductsSheet()
                            self.appState.visibleSheet = .inspiration
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
                
                // MARK: - Popovers
                
                // measurements popover
                PopOverView(bindingVisible: $appState.showMeasurementHelper, alignment: .bottom, offset: 0, showModalOffset: UIScreen.main.bounds.height / 2) {
                    MeasurementsExpandedView(isPaint: appState.selectedProduct?.productCategory == 1, measurementHelper: MeasurementHelper(width: appState.engineState.swatch?.size.width, height: appState.engineState.swatch?.size.height))
                        .frame(maxWidth: 420)
                        .modifier(SwipeModifier(currentPosition: $measurementCardOffset, isVisible: $appState.showMeasurementHelper, offsetHeight: UIScreen.main.bounds.height / 2, dismissAction: {}))
                }
                
                // camera permissions popover
                PopOverView(bindingVisible: $appState.showPhotoPermissions, alignment: .bottom, offset: 0, showModalOffset: UIScreen.main.bounds.height / 1.5, dismissAction: hidePhotoPermissions) {
                    
                    if PHPhotoLibrary.authorizationStatus() == .notDetermined {
                        PhotoPermissionsView(permissionState: .initial, closeBtnAction: hidePhotoPermissions, ctaBtnAction: displayPermissionsPrompt)
                            .frame(maxWidth: 420)
                            .modifier(SwipeModifier(currentPosition: $permissionsOffset, isVisible: $appState.showPhotoPermissions, offsetHeight: UIScreen.main.bounds.height / 1.5, dismissAction: hidePhotoPermissions))
                    } else if PHPhotoLibrary.authorizationStatus() == .denied {
                        PhotoPermissionsView(permissionState: .denied, closeBtnAction: hidePhotoPermissions, ctaBtnAction: navigateToSettings)
                            .frame(maxWidth: 420)
                            .modifier(SwipeModifier(currentPosition: $permissionsOffset, isVisible: $appState.showPhotoPermissions, offsetHeight: UIScreen.main.bounds.height / 1.5, dismissAction: hidePhotoPermissions))
                    }
                }
                
                .alert(item: $alertItem) { alertItem in
                    guard let primary = alertItem.primaryButton, let secondary = alertItem.secondaryButton else {
                        return Alert(title: Text("Error Loading"), dismissButton: .cancel(Text("Ok")))
                    }
                    return Alert(title: alertItem.title, message: alertItem.message, primaryButton: primary, secondaryButton: secondary)
                }

                // MARK: - NUX
                
                if !UserDefaults.hasSeenIntro {
                    NUXView(onFinished: { sheet in
                        appState.visibleSheet = sheet
                        withAnimation(.easeInOut(duration: 0.45)) {
                            self.appState.isShowingNUX = false
                        }
                    }, onCameraAllowed: {
                        self.appState.engineState.isRunning = true
                    }).opacity(self.appState.isShowingNUX ? 1 : 0)
                        .transition(.opacity)
                        .analytics(analyticInstance)
                }
                
                
            }
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(item: $appState.visibleSheet, content: sheetContent(for:))
        .onReceive(navigation.deepLinkURL) {
            let incomingURL = $0
            
            self.handleDeepLink(incomingURL: incomingURL)
            
        }
        .onAppear(perform: didAppear)
        .onChange(of: currentSurvey, perform: { survey in
            self.handleDisplayingSurvey(survey)
        })
        .overlay(survey)
    }
    
    // MARK: - Survey
    
    var survey: some View {
        VStack {
            if showSurvey {
                SurveyFullscreenView(client: client, survey: currentSurvey, isActive: $showSurvey, shouldShowRating: $showRatingPrompt).analytics(analyticInstance)
                    .onDisappear {
                        if showRatingPrompt {
                            displayAppStorePrompt()
                        }
                    }
            }
        }
    }
    
    func loadPreSurveyPrompt() {
        alertItem = AlertItem(
            title: Text("Make Primer even better"),
            message: Text("Take our 30-second survey to shape the future of Primer"),
            primaryButton: .default(Text("No thanks")) {
                analyticInstance.didRespondToSurveyPrompt(response: "No thanks")
            },
            secondaryButton: .default(Text("Okay")) {
                analyticInstance.didRespondToSurveyPrompt(response: "Okay")
                withAnimation {
                    self.showSurvey = true
                }
            }
        )
    }

    func loadSurvey(for user: UserModel?) {
        client.fetchCurrentSurvey()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error loading survey: \n\(error)")
                    }
                },
                receiveValue: { survey in
                    self.currentSurvey = survey
                    if let currentId = user?.id {
                        self.currentSurvey.userId = "\(currentId)"
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func handleDisplayingSurvey(_ survey: SurveyModel) {
        if UserDefaults.lastSurveyViewed == survey.id {
            return
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 180.0) { // show after three minutes
                UserDefaults.lastSurveyViewed = survey.id
                withAnimation {
                    self.loadPreSurveyPrompt()
                }
            }
        }
    }
    
    func displayAppStorePrompt() {
        #if !targetEnvironment(simulator)
        if !self.appState.hasPromptedReview {
            if let windowScene = UIApplication.shared.windows.first?.windowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
            self.appState.hasPromptedReview = true
            analyticInstance.trackPromptedForReview()
        }
        #endif
    }
    
    // MARK: - Photo Permissions
    
    func hidePhotoPermissions() {
        withAnimation {
            appState.showPhotoPermissions = false
        }
        appState.isCapturingMedia = false
        appState.tempVideoURL = nil
        appState.tempCapturedImage = nil
    }
    
    func displayPermissionsPrompt() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite,handler: { (status) in
            analyticInstance.photoPermissionsSelected(status.rawValue, location: .photoPermissionTooltip)
            
            if status == .authorized || status == .limited {
                DispatchQueue.main.async {
                    if let newImage = appState.tempCapturedImage {
                        analyticInstance.capturePreview(.appStill, for: appState.selectedProduct)
                        appState.visibleSheet = .imagePreview(image: newImage)
                        hidePhotoPermissions()
                    } else if let url = appState.tempVideoURL {
                        analyticInstance.capturePreview(.appVideo, for: appState.selectedProduct)
                        appState.visibleSheet = .capturePreview(fileURL: url)
                        hidePhotoPermissions()
                    } else {
                        hidePhotoPermissions()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    hidePhotoPermissions()
                }
            }
        })
    }
    
    func navigateToSettings() {
        DispatchQueue.main.async {
            appState.tempVideoURL = nil
            appState.tempCapturedImage = nil
            appState.isCapturingMedia = false
            analyticInstance.didTapGoToPhotoSettings(from: .photoPermissionTooltip)
        }
        if let url = NSURL(string: UIApplication.openSettingsURLString) as URL? {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func getBottom(proxy:GeometryProxy) -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let sceneDelegate = windowScene.delegate as? SceneDelegate,
            let window = sceneDelegate.window else {
                return 0
        }
        
        if(window.safeAreaInsets.bottom > proxy.safeAreaInsets.bottom){
            return window.safeAreaInsets.bottom
        }else{
            return proxy.safeAreaInsets.bottom
        }
    }
}



//MARK: - Deep Link Handling
extension MainView{
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
            case .imagePreview(let image):
                let view = CapturePreviewView(image: image, selectedProduct: appState.selectedProduct).analytics(analyticInstance)
                return AnyView(view)
        case .capturePreview(let fileURL):
            let view = CapturePreviewView(videoFileURL: fileURL, selectedProduct: appState.selectedProduct).analytics(analyticInstance)
            return AnyView(view)
            
        case .brandView:
            let view = ProductsView(client: client, appState: $appState,selectedBrandId: appState.selectedBrandId, onSelectProduct: onSelectProduct).analytics(analyticInstance)
            //            return AnyView(view)
            return AnyView(view)
        
        case .saved:
            let view = FavoritesView(appState:self.$appState,
                                     favoriteProductIDs: $appState.favoriteProductIDs, client: client,
                                     location: .favoritesDrawer,
                                     onTap: onSelectProduct).analytics(analyticInstance)
            return AnyView(view)
            
        case .inspiration:
            let view = ProductsView(client: client, appState: $appState, selectedBrandId: appState.selectedBrandId, onSelectProduct: onSelectProduct).analytics(analyticInstance)
                return AnyView(view)
        case .browser:
            let view = ProductsView(client: client, appState: $appState,onSelectProduct: onSelectProduct).analytics(analyticInstance)
            return AnyView(view)
        case .about:
            let view = AboutPageView(appState: $appState, client: client).analytics(analyticInstance)
            return AnyView(view)
        }
        
    }
    
    // MARK: - didAppear
    
    private func didAppear() {
        if appState.viewingBuy {
            return
        }

        if AuthController.shared.isLoggedIn {
            client = AuthController.shared.apiClient ?? client
            client.getCurrentUser()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { user in
                        analyticInstance.signInMixpanelUser(user)
                        loadSurvey(for: user)
                        AuthController.shared.currentUser = user
                        if let favoriteIds = user.favorite_product_ids {
                            self.appState.favoriteProductIDs = favoriteIds
                        }else{
                            self.appState.favoriteProductIDs = []
                        }
                })
                .store(in: &cancellables)
        } else {
            self.loadSurvey(for: nil)
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: OperationQueue.main) { notification in
            analyticInstance.capturePreview(.nativeStill, for: appState.selectedProduct)
        }
        
        NotificationCenter.default.addObserver(forName: UIScreen.capturedDidChangeNotification, object: nil, queue: OperationQueue.main) { notification in
            let isCaptured = UIScreen.main.isCaptured
            if isCaptured {
                analyticInstance.capturePreview(.nativeVideo, for: appState.selectedProduct)
            } else {
                analyticInstance.finishedPreviewCapture(.nativeVideo, for: appState.selectedProduct)
            }
        }
        
        if(!self.appState.isShowingNUX){
            self.appState.engineState.isRunning = true
        }

        appState.productCollection = client.productsRepo
        if appState.productCollection.value.count == 0 {
            self.appState.productCollection.refresh()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { products in
                        if self.appState.productCollection.value.isEmpty {
                            self.appState.productCollection.refresh()
                            self.appState.currentIndex = 1.0
                        }
                })
                .store(in: &cancellables)
        } else {
            if self.appState.productCollection.value.isEmpty {
                self.appState.productCollection.refresh()
                self.appState.currentIndex = 1.0
            }
        }
        return
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



struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            MainView()
        }
    }
}
