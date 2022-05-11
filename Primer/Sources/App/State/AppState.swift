import Foundation
import SwiftUI
import ARKit
import PrimerEngine
import Combine
import SystemConfiguration

struct AppState {
    
    var productCollection: Repository<[ProductModel]> = FeaturedProductsRepository() {
        didSet {
            currentIndex = 1
            currentVariationIndex = 0
        }
    }
    
    // displayed above orbs to show user what they're currently viewing
    var orbCollectionString: String = "Inspiration"

    var lastIndex: Double = 1.0
    
    var currentIndex: Double = 1.0
    
    var variationVersion: Int = 3
    
    //this is the index for a product variation
    //this will only change if the product has a variation and
    //is changed via the variation orbs
    var currentVariationIndex: Double = 0.0

    var isShowingProductDetails: Bool = true
    
    var ignoreIndexChange: Bool = false
    
    var viewingBuy: Bool = false
    
    var showMeasurementHelper: Bool = false
    
    var showPhotoPermissions: Bool = false
    
    var visibleSheet: VisibleSheet? = nil
    
    var engineState = EngineState()
    
    var currentUser = UserModel()
    
    var isShowingNUX = !UserDefaults.hasSeenIntro
    
//    Show inspiration feed instead of camera on launch
//    var visibleSheet: VisibleSheet? = .browser

    var recordingState = RecordingState.notRecording
    
    var isCapturingMedia: Bool = false
    var tempCapturedImage: UIImage? = nil
    var tempVideoURL: URL? = nil
    
    var selectedBrandName: String = ""
    
    var showSuccessSwatchPlacement: Bool = false
    var showWallBlendingPlacement: Bool = false
    var shownProductsCount:Int = 0
    var showBrowseMoreProducts: Bool = false
    
    var swatchProgressType: CompletedSwatchStepType = .auto
        
    // MAKR: - Recording State
    
    enum RecordingState {
        case notRecording
        case recording(amountComplete: CGFloat)
        
        var isRecording: Bool {
            if case .recording = self {
                return true
            } else {
                return false
            }
        }
        
        var amountComplete: CGFloat {
            switch self {
            case .notRecording:
                return 0.0
            case .recording(let amountComplete):
                return amountComplete
            }
        }
    }
    
    var hasPromptedReview: Bool{
     
        get{
            let infoDictionaryKey = kCFBundleVersionKey as String
            guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
                else { fatalError("Expected to find a bundle version in the info dictionary") }
            
            let lastVersionPromptedForReview = UserDefaults.lastVersionPromptedForReview ?? ""
            
            return lastVersionPromptedForReview == currentVersion
        }
        set{
            let infoDictionaryKey = kCFBundleVersionKey as String
            guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
                else { fatalError("Expected to find a bundle version in the info dictionary") }
            
            UserDefaults.lastVersionPromptedForReview = currentVersion
        }
    }
    
    
    
    fileprivate init() {}
    
    // Returns the closest valid index into the product collection for the current index
    var roundedProductIndex: Int? {
        guard !productCollection.value.isEmpty else { return nil }
        let closestIndex = Int(currentIndex.rounded()) - 1 // our current index has a bookend. EngineOverlayContent.swift
        let range = ClosedRange(productCollection.value.indices)
        return max(min(closestIndex, range.upperBound), range.lowerBound)
    }
    
    // Returns the selected product for the current index, unless the product collection is empty
    var selectedProduct: ProductModel? {
        guard let roundedIndex = roundedProductIndex else { return nil }
        return productCollection.value[roundedIndex]
    }
    
    var selectedProductForDetails: ProductModel? {
        guard let product = selectedProduct else { return nil }
        switch product.productType{
            case .product:
                return product
            case .productWithVariations:
                guard let variations = product.variations else { return nil }
                return variations[Int(currentVariationIndex)]
        }
    }
    

    var selectedProductMaterial: MaterialModel? {
        guard let product = selectedProduct else { return nil }
        switch product.productType{
            case .product:
                return product.material
            case .productWithVariations:
                guard let variations = product.variations else { return nil }
                return variations[Int(currentVariationIndex)].material
        }                
    }
    
    var savedProduct: SavedProduct? = nil
    var savedFavorite: SavedProduct? = nil
    
    var selectedBrandId: Int = 0
    var hasSavedBrand: Bool = false
    var savedBrandManager: SavedBrandManager = SavedBrandManager(brand: nil)
    var selectedCollectionId: Int?
    
    var needToUpdateFavorites: Bool = false
    var favoriteProductsChange = PassthroughSubject<Void, Never>()
    
    var favoriteProductIDs: [Int] = UserDefaults.favoriteProductIDs {
        willSet {

            UserDefaults.favoriteProductIDs = newValue

            favoriteProductsChange.send()
            needToUpdateFavorites = true
        }
    }
    
    var hasCameraAccess:Bool{
        get{
            return CameraAuthorizationController.shared.hasCameraAccess
        }
    }
    
    var hasNetworkAccess:Bool {

        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return (isReachable && !needsConnection)
    }
    
    // MARK: - Help Modal
    
    enum HelpModal {
        case cameraAccessDenied
        case noNetworkDetected
        case swatchPlacementConfirmation
        case browseMoreProductsCTA
        case wallBlendingHelp
        case none
    }
    
    var showModal: Bool {
        if case .none = helpModalType {
            return false
        }
        //we do a treatment to the button vs a modal here.
        else if case .browseMoreProductsCTA = helpModalType{
            return false
        }
        else {
            return true
        }
    }
    var helpModalType: HelpModal{
        var isAppClip = false
        #if APPCLIP
            isAppClip = true
        #endif
        
        if(!hasCameraAccess && !self.isShowingNUX){
            return .cameraAccessDenied
        }else if(!hasNetworkAccess && !self.isShowingNUX){
            return .noNetworkDetected
        }else if(!UserDefaults.hasShownPlacementHelper && showSuccessSwatchPlacement && engineState.swatch != nil && !isAppClip){
            return .swatchPlacementConfirmation
        }else if (shownProductsCount >= 6 && !UserDefaults.hasSeenBrowseProductsHelper && engineState.swatch != nil){
            return .browseMoreProductsCTA
        }else if (!UserDefaults.hasSeenWallBlendingHelp && engineState.isLocalSwatchShadingEnabled && showWallBlendingPlacement) {
            return .wallBlendingHelp
        }
        return .none
        
    }

}

// MARK: - Visible Sheet

extension AppState {
    
    enum VisibleSheet: Equatable, Identifiable {
        case browser //brand webview
        case capturePreview(fileURL: URL) //share video
        case imagePreview(image: UIImage)
        case saved // favorites
        case inspiration //products button
        case brandView //appclip
        case about
        
        var id: Int {
            switch self {
            case .browser:
                return 0
            case .capturePreview:
                return 1
            case .brandView:
                return 2
            case .saved:
                return 3
            case .inspiration:
                return 4
            case .imagePreview:
                return 5
            case .about:
                return 6
            }
        }
    }
}

extension AppState {
    
    // a helper to track a previously tapped item to return to on sheet-reopen
    struct SavedProduct {
        var id: Int
        var locationId: ProductCardScrollId = .unspecified
        var scrollToId: String {
            return "\(locationId.rawValue)\(id)"
        }
    }
    
}

extension AppState {
    
    static var initialState: AppState {
        AppState()
    }
    
}

// MARK: - User Defaults handling

extension AppState {
    var hasRecorded: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "hideVideoTooltip")
        }
        set {
            UserDefaults.standard.set(true, forKey: "hideVideoTooltip")
        }
    }
    
    var hasClearedCameraTip: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "hideCameraTooltip")
        }
        set {
            UserDefaults.standard.set(true, forKey: "hideCameraTooltip")
        }
    }
}

extension AppState {
    public static func canUseLidar() -> Bool { ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) }
}
