import PrimerEngine
import SwiftUI
import Mixpanel

//AR session time
//Which materials are being previewed in AR, and time associated with that material
//Successful mounting of the swatch
//Screen-recording start (tapping and holding that orb)
//Which brands are being tapped on in the Library view
//Which products are being tapped on in the Inspiration view
//Total session time in app
//Share sheets coming up, in both the profile view and the “share video” view

public final class Analytics {
    
    private let mixpanel: MixpanelInstance
    public var currentUser:UserModel?
    private let lengthFormatter = LengthFormatter()
    
    
    private var viewTimers:[String : Date] = [String : Date]()
    
        
    public init() {
        mixpanel = Mixpanel.initialize(token: ENV.mixpanelToken)
        #if APPCLIP
        mixpanel.registerSuperProperties(["AppClip":true])
        #endif
        mixpanel.flush()
    }
    
    public func productProps(_ product: ProductModel) -> [String: MixpanelType] {
        let properties: [String:MixpanelType] = [
            "product_id": product.id,
            "product_name": product.name,
            "brand_id": product.brandId,
            "brand_name": product.brandSlug
        ]
        
        return properties
    }
    
    // MARK: - Swatches
    
    public func didMountSwatch(product: ProductModel?, swatch: Swatch) {
        guard let prod = product else { return }
        
        let properties: [String:MixpanelType] = [
            "product_id": prod.id,
            "product_name": prod.name,
            "brand_id": prod.brandId,
            "brand_name": prod.brandSlug
        ]
        
        if AppState.canUseLidar() {
            mixpanel.track(event: "Mounted swatch", properties: properties)
        } else {
            self.trackTimingEvent(event: "Mounted swatch", properties: properties)
        }
    }
    
    public func swatchInstructionsAppeared() {
        self.viewTimers.updateValue(Date(), forKey: "Mounted swatch")
    }
    
    public func didCompleteSwatchStep(_ progressStep: Int, type: CompletedSwatchStepType) {
        let properties: [String:MixpanelType] = [
            "complete_type": type.rawValue
        ]
        
        mixpanel.track(event: "Mount swatch step \(progressStep) complete", properties: properties)
    }
    
    public func didSkipSwatchTutorial() {
        mixpanel.track(event: "Skipped swatch tutorial")
    }
    
    public func didRestartSwatchTutorial(fromTips: Bool) {
        let properties: [String : MixpanelType] = [
            "from_tips": fromTips
        ]
        
        mixpanel.track(event: "Restarted swatch tutorial", properties: properties)
    }
    
    public func didMoveSwatch(product: ProductModel?, swatch: Swatch) {
        guard let prod = product else { return }
        
        let properties: [String:MixpanelType] = [
            "product_id": prod.id,
            "product_name": prod.name,
            "swatch_width":swatch.size.width,
            "swatch_height": swatch.size.height,
            "brand_id": prod.brandId,
            "brand_name": prod.brandSlug
        ]
        
        mixpanel.track(event: "Moved swatch", properties: properties)
    }
    
    public func didResizeSwatch(product: ProductModel?, swatch: Swatch) {
        guard let prod = product else { return }
        
        let properties: [String:MixpanelType] = [
            "product_id": prod.id,
            "product_name": prod.name,
            "swatch_width": swatch.size.width,
            "swatch_height": swatch.size.height,
            "brand_id": prod.brandId,
            "brand_name": prod.brandSlug
        ]
        
        mixpanel.track(event: "Resized swatch", properties: properties)
    }
    
    public func didClearSwatch() {
        mixpanel.track(event: "Cleared swatch")
    }
    
    public func didViewMoreProductOrb(location:String){
        let properties: [String:MixpanelType] = [
            "location": location
        ]
        mixpanel.track(event: "View More Product Orb", properties: properties)

    }
    
    // MARK: - Sharing
    
    public func didTapShareProduct(prod: ProductModel) {
        
        let properties: [String:MixpanelType] = [
            "product_id": prod.id,
            "product_name": prod.name,
            "brand_id": prod.brandId,
            "brand_name": prod.brandSlug
        ]
        
        mixpanel.track(event: "Shared Product from Details", properties: properties)
    }
    
    public func didTapShareVideo(product: ProductModel?, durationTime: Float64) {
        guard let prod = product else { return }
        
        let properties: [String:MixpanelType] = [
            "product_id": prod.id,
            "product_name": prod.name,
            "video_duration": durationTime,
            "brand_id": prod.brandId,
            "brand_name": prod.brandSlug
        ]
        
        mixpanel.track(event: "Shared Video", properties: properties)
    }

    private func getActivityTypeDesc(activityType: UIActivity.ActivityType?) -> String {
        var desc = ""
        
        if let at = activityType{
            switch at{
                case .airDrop:
                    desc += "Airdrop"
                    break
                case .copyToPasteboard:
                    desc += "Pasteboard"
                    break
                case .mail:
                    desc += "Mail"
                    break
                case .message:
                    desc += "Message"
                    break
                case .postToFacebook:
                    desc += "Facebook"
                    break
                case .postToTwitter:
                    desc += "Twitter"
                    break
                case .saveToCameraRoll:
                    desc += "Camera Roll"
                    break
                case nil:
                    desc += "nil"
                    break
                default:
                    if(at.rawValue == "com.tinyspeck.chatlyio.share"){
                        desc += "Slack"
                    }else{
                        desc += "\(at.rawValue)"
                    }
                    break
            }
        }
        return desc
    }

    public func didSharePreview(activityType: UIActivity.ActivityType?, product: ProductModel?, previewType: CapturedPreviewType, social: String?) {
            
        var desc: String
        if activityType != nil {
            desc = getActivityTypeDesc(activityType: activityType)
        } else if let social = social {
            desc = social
        } else {
            desc = "invalid"
        }
            
        var properties: [String:MixpanelType]
        if let prod = product {
            properties = [
                "activity": desc,
                "preview_type": previewType.rawValue,
                "product_id": prod.id,
                "product_name": prod.name,
                "brand_id": prod.brandId,
                "brand_name": prod.brandSlug
               ]
        } else {
            properties = [
                "activity": desc,
                "preview_type": previewType.rawValue
            ]
        }
            
        mixpanel.track(event: "Capture Shared", properties: properties)
    }

    public func didCancelShare(product: ProductModel?, previewType: CapturedPreviewType) {

        var properties: [String:MixpanelType]
        if let prod = product {
            properties = [
                "preview_type": previewType.rawValue,
                "product_id": prod.id,
                "product_name": prod.name,
                "brand_id": prod.brandId,
                "brand_name": prod.brandSlug
            ]
        } else {
            properties = [
                "preview_type": previewType.rawValue
            ]
        }
        mixpanel.track(event: "Cancelled Share", properties: properties)
    }
 
    // MARK: - About page
    
    public func didTapAboutItem(_ item: AboutItem) {
        let properties: [String:MixpanelType] = [
            "item": item.analyticsString
        ]
        
        mixpanel.track(event: "Tapped About Page Item", properties: properties)
    }
    
    
    // MARK: - Accounts

    public func createAccountComplete(_ type: AccountType, location: ViewLocation) {
        let properties: [String: MixpanelType] = [
            "account_type": type.rawValue,
            "location": location.rawValue
        ]
        
        mixpanel.track(event: "Account Created", properties: properties)
    }

    public func signInMixpanelUser(_ user: UserModel) {
        let properties: [String: MixpanelType] = [
            "$name": user.name,
            "$email": user.email
        ]
        
        currentUser = user
        mixpanel.identify(distinctId: "\(user.id)")
        mixpanel.people.set(properties: properties)
    }
    
    public func signOutMixpanelUser() {
        currentUser = nil
        mixpanel.reset()
    }
    
    public func signInComplete(_ type: AccountType) {
        let properties: [String: MixpanelType] = [
            "account_type": type.rawValue
        ]
        
        mixpanel.track(event: "Sign In Complete", properties: properties)
    }
    
    public func signInTapped(_ type: AccountType) {
        let properties: [String: MixpanelType] = [
            "account_type": type.rawValue
        ]
        
        mixpanel.track(event: "Sign In Tapped", properties: properties)
    }
    
    public func signUpTapped(_ type: AccountType, location: ViewLocation) {
        let properties: [String: MixpanelType] = [
            "account_type": type.rawValue,
            "location": location.rawValue
        ]
        
        mixpanel.track(event: "Sign Up Tapped", properties: properties)
    }
    
    public func didTapSIWEmailNav() {
        mixpanel.track(event: "Start Sign In")
    }

    public func didTapToExitSignIn() {
        mixpanel.track(event: "Exit Sign In")
    }
    
    public func didTapCreateAccountNav(from location: ViewLocation) {
        let properties: [String: MixpanelType] = [
            "location": location.rawValue
        ]
        
        mixpanel.track(event: "Start Create Account", properties: properties)
    }
    
    public func didTapCreateAccount(from location: ViewLocation) {
        let properties: [String: MixpanelType] = [
            "location": location.rawValue
        ]
        
        mixpanel.track(event: "Create Account Tapped", properties: properties)
    }
    
    public func didAcknowldegeNUXTutorial() {
        mixpanel.track(event: "Acknowledged Place & Resize NUX View")
    }
    
    public func skipNUXAccountCreate() {
        mixpanel.track(event: "Skip NUX Account Creation")
    }
    
    public func didTapToExitAccountCreation() {
        mixpanel.track(event: "Exit Account Creation")
    }

    public func didTapForgotPW() {
        mixpanel.track(event: "Forgot Password")
    }
    
    public func didTapLogOutMenu() {
        mixpanel.track(event: "Start Log Out")
    }
    
    public func didLogOut() {
        mixpanel.track(event: "Logged Out")
    }
    
    public func didCancelLogout() {
        mixpanel.track(event: "Log Out Cancelled")
    }
    
    public func subscribedToNewsletter(from accountType: AccountType, location: ViewLocation) {
        let properties: [String:MixpanelType] = [
            "account_type": accountType.rawValue,
            "location": location.rawValue
        ]
        
        mixpanel.track(event: "Subscribed to Newsletter", properties: properties)
    }
    
    // MARK: - Surveys
    
    public func didRespondToSurveyPrompt(response: String) {
        let properties: [String : MixpanelType] = [
            "response": response
        ]
        
        mixpanel.track(event: "Responded to Pre Survey Prompt", properties: properties)
    }
    
    public func didTapSurveySelection(_ selection: SurveyResponse, surveyId: Int) {
        let properties: [String : MixpanelType] = [
            "current_survey_id": surveyId,
            "question_id": selection.questionId,
            "response": selection.response
        ]
        
        mixpanel.track(event: "Tapped Survey Selection", properties: properties)
    }
    
    public func didStartSurvey(id: Int) {
        self.viewTimers.updateValue(Date(), forKey: "Viewed Survey")
    }
    
    public func didEndSurvey(id: Int, questionsAnswered: Int, submittedResponse: Bool) {
        let properties: [String : MixpanelType] = [
            "current_survey_id": id,
            "questions_answered": questionsAnswered,
            "submitted_response": submittedResponse
        ]
        
        self.trackTimingEvent(event: "Viewed Survey", properties: properties)
    }
    
    public func tappedEmailFeedbackFromSurvey(id: Int) {
        let properties: [String : MixpanelType] = [
            "current_survey_id": id
        ]
        
        mixpanel.track(event: "Tapped To Email Feedback from Survey", properties: properties)
    }
    
    // MARK: - Deep Links
    
    public func trackDeepLinkForBrand(brand: BrandModel){
        let properties: [String:MixpanelType] = [
            "brand_name": brand.name,
            "brand_id": brand.id
        ]
        
        mixpanel.track(event: "Load Deep Link For Brand", properties: properties)
    }
    public func trackDeepLinkForProduct(product: ProductModel){
        let properties: [String:MixpanelType] = [
            "product_id": product.id,
            "product_name": product.name,
            "brand_id": product.brandId,
            "brand_name": product.brandSlug
        ]
        
        mixpanel.track(event: "Load Deep Link For Product", properties: properties)
    }
    
    public func didTapShareBrand(brand: BrandModel) {
        let properties: [String:MixpanelType] = [
            "brand_name": brand.name,
            "brand_id": brand.id
        ]
        
        mixpanel.track(event: "Shared brand", properties: properties)
    }
    
    public func didGiveIntent(intent: String) {
        let properties: [String:MixpanelType] = ["intent": intent]
        
        mixpanel.track(event: "User Intent", properties: properties)
    }
    
    // MARK: - Favoriting
    
    public func didTapFavorite(_ product: ProductModel, isAdded: Bool, from location: ViewLocation) {
        let properties: [String: MixpanelType] = [
            "button_location": location.rawValue,
            "product_id": product.id,
            "product_name": product.name,
            "brand_id": product.brandId,
            "brand_name": product.brandSlug
        ]
        
        if isAdded {
            mixpanel.track(event: "Favorite Initiated", properties: properties)
        } else {
            mixpanel.track(event: "Favorite Removed", properties: properties)
        }
    }
    
    public func favoriteComplete(_ product: ProductModel) {
        let properties: [String: MixpanelType] = [
            "product_id": product.id,
            "product_name": product.name,
            "brand_id": product.brandId,
            "brand_name": product.brandSlug
        ]
        
        mixpanel.track(event: "Favorite Complete", properties: properties)
    }
    
    public func didTapToExitFavorites() {
        mixpanel.track(event: "Exit Favorites")
    }

    // MARK: - Product
    
    public func didViewProductDetails(product: ProductModel){
        let properties = productProps(product)
        
        mixpanel.track(event: "View Product Details", properties: properties)
    }
    
    public func didOpenProductsSheetFromPrompt(product: ProductModel?){
        var properties: [String:MixpanelType] = [:]
        if let product = product {
            properties = [
                "product_id": product.id,
                "product_name": product.name,
                "brand_id": product.brandId,
                "brand_name": product.brandSlug
                
            ]
        }
        
        mixpanel.track(event: "Opened Product Sheet From Browse Prompt", properties: properties)
    }
    
    public func acknowledgedBrowseProductPrompt(product: ProductModel?){
        var properties: [String:MixpanelType] = [:]
        if let product = product {
            properties = [
                "product_id": product.id,
                "product_name": product.name,
                "brand_id": product.brandId,
                "brand_name": product.brandSlug
                
            ]
        }
        
        mixpanel.track(event: "Acknowledged Browse Prompt", properties: properties)
    }
     
    // MARK: - Search and Filter
    
    public func searchBarTapped() {
        mixpanel.track(event: "Search Bar Tapped")
    }
    
    public func searchSuggestionTapped(from category: String, tappedSelection: String) {
        var properties: [String: MixpanelType] = [:]
        properties = [
            "category": category,
            "tapped_selection": tappedSelection
        ]
        
        mixpanel.track(event: "Search Suggestion Tapped", properties: properties)
    }
    
    public func searchFired(_ searchString: String) {
        var properties: [String: MixpanelType] = [:]
        properties = [
            "search_string": searchString
        ]
        
        mixpanel.track(event: "Search Fired", properties: properties)
    }
    
    public func searchResults(for searchString: String, filters: [SearchFilterModel], resultsFound: Bool, location: ViewLocation = .searchResult) {
        var properties: [String: MixpanelType] = [:]
        properties = [
            "results_found": resultsFound,
            "search_string": searchString,
            "location": location.rawValue
        ]
        
        let newProperties = properties.merging(applyFiltersToProperties(filters: filters)){ (_, new) in new }
        
        mixpanel.track(event: "Search Results Returned", properties: newProperties)
        self.didLoadSearchResults() // fires time tracker for search abandoned event
    }
    
    public func searchResultsTapped(_ product: ProductModel, searchString: String, filters: [SearchFilterModel], location: ViewLocation = .searchResult) {
        var properties = [String: MixpanelType]()
        properties = [
            "product_id": product.id,
            "product_name": product.name,
            "brand_id": product.brandId,
            "brand_name": product.brandSlug,
            "product_category": product.productCategory,
            "search_string": searchString,
            "location": location.rawValue
        ]
        let newProperties = properties.merging(applyFiltersToProperties(filters: filters)){ (_, new) in new }
        
        mixpanel.track(event: "Search Result Tapped", properties: newProperties)
    }
    
    public func searchResultsAbandoned(query: String, filters: [SearchFilterModel], resultsFound: Bool) {
        let properties: [String: MixpanelType] = [
            "query": query,
            "results_returned": resultsFound
        ]
        let newProperties = properties.merging(applyFiltersToProperties(filters: filters)) { (_, new) in new }
        self.trackTimingEvent(event:"Search Abandoned", properties: newProperties)
    }
    
    public func applyFiltersToProperties(filters: [SearchFilterModel]) -> [String:MixpanelType]
    {
        var properties = [String: MixpanelType]()
        
        for filter in filters {
            var filterItems: [FilterItem] = []
            if let selectedItems = filter.items?.filter({$0.isSelected}) {
                filterItems.append(contentsOf: selectedItems)
            }
            properties.updateValue(filterItems.map({ $0.name }).joined(separator: ", "), forKey: "Filter_" + filter.name)
        }
        
        return properties
    }
    
    public func filterCategoryTapped(_ category: String) {
        var properties: [String: MixpanelType] = [:]
        properties = [
            "category": category
        ]
        
        mixpanel.track(event: "Filter Category Tapped", properties: properties)
    }
    
    public func filterApplied(for category: String, filter: FilterItem, currentSearch: String) {
        var properties: [String: MixpanelType] = [:]
        properties = [
            "category": category,
            "added_filter": filter.name,
            "search_string": currentSearch
        ]
        
        mixpanel.track(event: "Filter Added", properties: properties)
    }
    
    public func filtersReset(for category: String) {
        var properties: [String: MixpanelType] = [:]
        properties = [
            "category": category
        ]
        
        mixpanel.track(event: "Filter Reset", properties: properties)
    }
    
    // MARK: - Placement
    
    public func retriedSwatchPlacement(product: ProductModel?){
        var properties: [String:MixpanelType] = [:]
        if let product = product {
            properties = [
                "product_id": product.id,
                "product_name": product.name,
                "brand_id": product.brandId,
                "brand_name": product.brandSlug
                
            ]
        }
        
        mixpanel.track(event: "Retried Swatch Placement From Swatch Prompt", properties: properties)
    }
    
    public func successfullyPlacedSwatch(product: ProductModel?){
        var properties: [String:MixpanelType] = [:]
        if let product = product {
            properties = [
                "product_id": product.id,
                "product_name": product.name,
                "brand_id": product.brandId,
                "brand_name": product.brandSlug
                
            ]
        }
        
        mixpanel.track(event: "Reported Success From Swatch Prompt", properties: properties)
    }
    
    // MARK: - Misc
    
    public func viewedAlternateIcons() {
        mixpanel.track(event: "Alternate Icons Viewed")
    }
    
    public func didTapAlternateIcon(_ selectedIcon: String) {
        let properties: [String: MixpanelType] = [
            "selection": selectedIcon,
        ]
        mixpanel.track(event: "Selected Alternate Icon", properties: properties)
    }
    
    public func didTapMeasurementsButton() {
        mixpanel.track(event: "Measurements Button Tapped")
    }
    
    public func didSwitchSwatchMaterial(product: ProductModel, isVariation:Bool = false){
        let properties: [String:MixpanelType] = [
            "product_id": product.id,
            "product_name": product.name,
            "brand_id": product.brandId,
            "brand_name": product.brandSlug,
            "is_variation": isVariation
        ]
        
        mixpanel.track(event: "User Changed Swatch", properties: properties)
    }

    public func didTapExpandedBuyButton(product:ProductModel?){
        guard let prod = product else { return }
        
        let properties: [String:MixpanelType] = [
            "product_id": prod.id,
            "product_name": prod.name,
            "brand_id": prod.brandId,
            "brand_name": prod.brandSlug
        ]
        
        mixpanel.track(event: "Expanded Buy Button Pressed", properties: properties)
    }
    
    public func didTapMiniBuyButton(product:ProductModel?){
        guard let prod = product else { return }
        
        let properties: [String:MixpanelType] = [
            "product_id": prod.id,
            "product_name": prod.name,
            "brand_id": prod.brandId,
            "brand_name": prod.brandSlug
        ]
        
        mixpanel.track(event: "Mini Buy Button Pressed", properties: properties)
    }
    
    public func didSelectCategoryInLibrary(category: CategoryModel){
        let properties: [String:MixpanelType] = [
            "category_name": category.name,
            "category_id": category.id
        ]


        mixpanel.track(event: "Selected category", properties: properties)
    }
    
    public func didTurnWallBlendingOn(product: ProductModel?) {
        guard let prod = product else { return }
        
        let properties = productProps(prod)
        
        mixpanel.track(event: "Activated wall blending", properties: properties)
    }
    
    public func didTurnWallBlendingOff(product: ProductModel?) {
        guard let prod = product else { return }
        
        let properties = productProps(prod)
        
        mixpanel.track(event: "Deactivated wall blending", properties: properties)
    }
    public func didSelectBrandInLibrary(brand: BrandModel) {
        let properties: [String:MixpanelType] = [
            "brand_name": brand.name,
            "brand_id": brand.id
        ]


        mixpanel.track(event: "Selected brand", properties: properties)
    }
    
    public func didSelectProductInInspirationView(product: ProductModel) {
        let properties: [String:MixpanelType] = [
            "product_id": product.id,
            "product_name": product.name,
            "brand_id": product.brandId,
            "brand_name": product.brandSlug
        ]
        
        mixpanel.track(event: "Selected product from inspiration view", properties: properties)
    }
    
    public func didSelectFeaturedProduct(_ product: ProductModel, from collection: ProductCollectionModel) {
        let properties: [String:MixpanelType] = [
            "product_id": product.id,
            "product_name": product.name,
            "brand_id": product.brandId,
            "brand_name": product.brandSlug,
            "collection": collection.name
        ]
        
        mixpanel.track(event: "Selected Featured Product", properties: properties)
    }
    
    public func didOpenProductsSheet() {
        mixpanel.track(event: "Opened products sheet")
    }

    public func trackPromptedForReview(){
        mixpanel.track(event: "Did prompt for review")
    }
    
    public func photoPermissionsSelected(_ selection: Int, location: ViewLocation) {
        
        var permissionType: PhotoPermissionType
        
        switch selection {
        case 0:
            permissionType = .notDetermined
        case 1:
            permissionType = .restricted
        case 2:
            permissionType = .denied
        case 3:
            permissionType = .authorized
        case 4:
            permissionType = .limited
        default:
            permissionType = .unknown
        }
        
        let properties: [String : MixpanelType] = [
            "selection": permissionType.rawValue,
            "location": location.rawValue
        ]
        
        mixpanel.track(event: "Photo Permission Selected", properties: properties)
    }
    
    public func cameraPermissionsSelected(_ selection: Int, location: ViewLocation) {
        
        var permissionType: CameraPermissionType
        
        switch selection {
        case 0:
            permissionType = .notDetermined
        case 1:
            permissionType = .restricted
        case 2:
            permissionType = .denied
        case 3:
            permissionType = .authorized
        default:
            permissionType = .unknown
        }
        
        let properties: [String : MixpanelType] = [
            "selection": permissionType.rawValue,
            "location": location.rawValue
        ]
        
        mixpanel.track(event: "Camera Permission Selected", properties: properties)
    }
    
    public func didTapGoToPhotoSettings(from location: ViewLocation) {
        let properties: [String:MixpanelType] = [
            "location": location.rawValue
        ]
        
        mixpanel.track(event: "Tapped to Photo permission settings", properties: properties)
    }
    
    public func didTapGoToCameraSettings(from location: ViewLocation) {
        let properties: [String:MixpanelType] = [
            "location": location.rawValue
        ]
        
        mixpanel.track(event: "Tapped to Camera permission settings", properties: properties)
    }
    
    // MARK: - View All
    
    public func didViewAllForCollection(brand: BrandModel, collection:ProductCollectionModel){
        let properties: [String:MixpanelType] = [
            "brand_name": brand.name,
            "brand_id": brand.id,
            "collection_name": collection.name,
            "collection_id" : collection.id
        ]
        
        mixpanel.track(event: "View All Brand Collection", properties: properties)
    }
    
    public func didViewBrandLink(brand: BrandModel){
        let properties: [String:MixpanelType] = [
            "brand_id": brand.id,
            "brand_name": brand.name,
            "brand_slug": brand.slug,
            "brank_link": brand.featuredLinkUrl
        ]
        
        mixpanel.track(event: "Tap Brand Link", properties: properties)
    }
    
    public func didViewForCollection(brand: BrandModel, collection:ProductCollectionModel, product: ProductModel){
        let properties: [String:MixpanelType] = [
            "brand_name": brand.name,
            "brand_id": brand.id,
            "collection_name": collection.name,
            "collection_id" : collection.id,
            "product_name": product.name,
            "product_id": product.id
        ]
        
        mixpanel.track(event: "View Brand Collection Product", properties: properties)
    }
    
    public func didViewFavoriteProduct(product: ProductModel){
        let properties: [String:MixpanelType] = [
            "product_id": product.id,
            "product_name": product.name,
            "brand_id": product.brandId,
            "brand_name": product.brandSlug
        ]
        
        mixpanel.track(event: "View Favorite Product", properties: properties)
    }
    
    public func trackAppClipAttribution(utm: String?){
        var properties: [String:MixpanelType] = [ : ]
        
        if let utm_string = utm {
            if utm_string.contains("clip-button"){
                properties = [
                    "Source" : "View Button"
                ]
            }
        }
        
        mixpanel.track(event: "App Clip Loaded", properties: properties)
    }
    
    public func captureInitiated(_ type: CapturedPreviewType, for product: ProductModel?) {

        let properties: [String: MixpanelType] = [
            "product_id": product?.id ?? "No product selected",
            "product_name": product?.name ?? "No product selected",
            "brand_id": product?.brandId ?? "No product selected",
            "brand_name": product?.brandSlug ?? "No product selected",
            "preview_type": type.rawValue
        ]
        
        mixpanel.track(event: "Captured Initiated", properties: properties)
    }
    
    
    // MARK: - Time tracking events
    
    public func didStartNUXExperience(){
        self.viewTimers.updateValue(Date(), forKey: "NUX Experience")
    }
    public func didEndNUXExperience(){
        self.trackTimingEvent(event: "NUX Experience")
    }

    public func didStartProductsView(){
        self.viewTimers.updateValue(Date(), forKey: "Viewing Products")
    }
    public func didEndProductsView(){
        self.trackTimingEvent(event:"Viewing Products")
    }
    
    public func didStartInspirationView(){
        self.viewTimers.updateValue(Date(), forKey: "Viewing Inspiration")
    }
    public func didEndInspirationView(){
        self.trackTimingEvent(event:"Viewing Inspiration")
    }
    
    public func didStartLibraryView(){
        self.viewTimers.updateValue(Date(), forKey: "Viewing Library")
    }
    public func didEndLibraryView(){
        self.trackTimingEvent(event:"Viewing Library")
    }
    
    public func didStartFavoriteView(){
        self.viewTimers.updateValue(Date(), forKey: "Viewing Favorites")
    }
    public func didEndFavoriteView(){
        self.trackTimingEvent(event:"Viewing Favorites")
    }
    
    public func didStartAboutView() {
        self.viewTimers.updateValue(Date(), forKey: "Viewing About Page")
    }
    public func didEndAboutView() {
        self.trackTimingEvent(event:"Viewing About Page")
    }
    
    public func didLoadSearchResults() {
        self.viewTimers.updateValue(Date(), forKey: "Search Abandoned")
    }
        
    public func didStartBrandView(brand: BrandModel){
        self.viewTimers.updateValue(Date(), forKey: "Viewing Brand")
    }
    public func didEndBrandView(brand: BrandModel){
        let properties: [String:MixpanelType] = [
            "brand_id": brand.id,
            "brand_name": brand.name
        ]
        self.trackTimingEvent(event:"Viewing Brand", properties: properties)
    }
    
    public func didStartNuxView(viewName: String){
        self.viewTimers.updateValue(Date(), forKey: "NUX View Time")
    }
    public func didEndNuxView(viewName: String){
        let properties: [String:MixpanelType] = [
            "view_name": viewName
        ]
        self.trackTimingEvent(event:"NUX View Time", properties: properties)
    }
    
    public func didStartBuyButtonVisit(product: ProductModel?){
        if (product == nil) { return }
        self.viewTimers.updateValue(Date(), forKey: "Product Buy Web View Time")
    }
    public func didEndBuyButtonVisit(product: ProductModel?){
        guard let prod = product else { return }
        let properties: [String:MixpanelType] = [
            "product_id": prod.id,
            "product_name": prod.name,
            "brand_id": prod.brandId,
            "brand_name": prod.brandSlug
        ]
        self.trackTimingEvent(event:"Product Buy Web View Time", properties: properties)
        
    }
    
    public func capturePreview(_ type: CapturedPreviewType, for product: ProductModel?) {
        switch type {
        case .appStill, .nativeStill:
            guard let prod = product else { return }
            let properties: [String: MixpanelType] = [
                "product_id": prod.id,
                "product_name": prod.name,
                "brand_id": prod.brandId,
                "brand_name": prod.brandSlug,
                "preview_type": type.rawValue,
                "duration": 0
            ]
            mixpanel.track(event: "Captured Preview", properties: properties)
        case .appVideo, .nativeVideo:
            self.viewTimers.updateValue(Date(), forKey: "Captured Preview")
        }
    }
    
    public func finishedPreviewCapture(_ type: CapturedPreviewType, for product: ProductModel?) {
        guard let prod = product else { return }
        let properties: [String: MixpanelType] = [
            "product_id": prod.id,
            "product_name": prod.name,
            "brand_id": prod.brandId,
            "brand_name": prod.brandSlug,
            "preview_type": type.rawValue
        ]
        
        self.trackTimingEvent(event: "Captured Preview", properties: properties)
    }
    
    private func trackTimingEvent(event:String, properties: [String:MixpanelType]? = nil){
        let currentTime = Date()
        if let startTime = self.viewTimers.removeValue(forKey: event) {
            let interval = currentTime.timeIntervalSince(startTime)
            self.viewTimers.removeValue(forKey: event)
            if var properties = properties {
                properties.updateValue(interval, forKey: "duration")
                mixpanel.track(event:event, properties: properties)
            }else{
                let properties = [
                    "duration": interval
                ]
                mixpanel.track(event:event, properties: properties)
            }
            
        }else{
            let properties: [String:MixpanelType] = [
                "issue": "NO VIEW TIMER",
                "details": event
            ]            
            mixpanel.track(event: "Error Logged", properties: properties)
        }
    }
        
}

// MARK: - Extension

extension View {
    
    func analytics(_ analytics: Analytics?) -> some View {
        environment(\.analytics, analytics)
    }
    
}
