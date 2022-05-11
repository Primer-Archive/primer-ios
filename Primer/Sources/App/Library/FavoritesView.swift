import SwiftUI
import Combine
import PrimerEngine


// MARK: - Favorites View

struct FavoritesView: View {
    var appState: Binding<AppState>
    @Binding var favoriteProductIDs: [Int]
    
    var client: APIClient
    var location: ViewLocation
    var onTap: (Repository<[ProductModel]>, Int, Int) -> Void

    @Environment(\.analytics) var analytics
    @Environment(\.presentationMode) var presentationMode
    
    @State private var cancellable: AnyCancellable? = nil
    @State private var presentIconModal = false
    @State private var presentNewsletterSignup = false
    @State private var presentFallbackNewsletter = false
    @State var isLoadingSIWA: Bool = false
    @State var isLoadingNewsletter: Bool = false
    
    @State var newsletterUserId: String = ""
    @State var newsletterEmail: String = ""
    @State var selectedIntent: Persona = .unselected
    @State var optInSubscription: Bool = true
    var favoritesText: String {
        if !AuthController.shared.isLoggedIn {
            return "Create an account to start favoriting."
        } else {
            return "Quit waiting and get favoriting!"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        
        NavigationView {
            ZStack(alignment: .topTrailing) {
                BackgroundView()
                    .edgesIgnoringSafeArea(.all)
                    .navigationBarHidden(true)
                    
                VStack(spacing: 0) {
                    
                    #if APPCLIP
                    CustomHeaderView(leadingIcon: .x12, text: "Favorited Products", leadingBtnAction: {
                            self.analytics?.didTapToExitFavorites()
                            appState.savedFavorite.wrappedValue = nil
                            if appState.visibleSheet.wrappedValue == .saved {
                                self.appState.visibleSheet.wrappedValue = nil
                            } else {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        })
                    #else
                    CustomHeaderView(leadingIcon: .x12, text: "Favorited Products", trailingIcon: .paintbrush, leadingBtnAction: {
                            self.analytics?.didTapToExitFavorites()
                            if appState.visibleSheet.wrappedValue == .saved {
                                self.appState.visibleSheet.wrappedValue = nil
                            } else {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }, trailingBtnAction: {
                            self.analytics?.viewedAlternateIcons()
                            self.presentIconModal = true
                        }
                    )
                    #endif

                    if favoriteProductIDs.isEmpty {
                        noFavoritesView
                    } else {
                        GeometryReader { proxy in
                        VStack {
                            RemoteFavoritesView(appState: appState, client: client, containerWidth: proxy.size.width, onTap: onTap)
                                .id(favoriteProductIDs)
                                .analytics(analytics)
                            
                            //if we're not logged in and we have products
                            //let's show them a login option.
                            if !AuthController.shared.isLoggedIn {
                                VStack {
                                    LabelView(text: favoritesText, style: .bodyMedium)
                                        .padding(BrandPadding.Medium.pixelWidth)
                                    
                                    ButtonSignInWithApple(isLoading: $isLoadingSIWA, appState: appState, buttonType: .signIn, client: self.client, location: location) { error in
                                        print("login error: \(error) - \(error.localizedDescription)")
                                    } completeSignupAction: { user in
                                        displayNewsletterPrompt(for: user)
                                    }.analytics(self.analytics)
                                    .frame(maxWidth:310, maxHeight:48)
                                    .cornerRadius(0)
                                    .padding(.bottom, 40)
                                }
                                .frame(maxWidth: .infinity)
                                .background(BrandColors.softBackground.color)
                            }
                        }.edgesIgnoringSafeArea(.bottom)
                        }.sheet(isPresented: $presentFallbackNewsletter) {
                            NewsletterView(email: $newsletterEmail, persona: $selectedIntent, isSubscribed: $optInSubscription, isLoading: $isLoadingNewsletter, completeAction: {
                                submitNewsletterPreferences(for: "\(newsletterUserId)")
                            }).analytics(analytics)
                        }
                    }
                }
                .disabled(isLoadingSIWA)
                .overlay(ActivityIndicatorView().opacity(isLoadingSIWA ? 1.0 : 0.0))
            }
        }
        
        // MARK: - Action Sheet
        
        .tabItem {
            SwiftUI.Image(systemName: SFSymbol.heartFill.rawValue)
            Text("Saved")
        }

        .sheet(isPresented: $presentIconModal, content: {
            altIconModalView
                .background(BrandColors.backgroundView.color)
                .edgesIgnoringSafeArea(.all)
        })
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            self.analytics?.didStartFavoriteView()
        }
        .onDisappear{
            self.analytics?.didEndFavoriteView()
        }
        
    }
    
    // MARK: - Alt Icon View
    
    private var altIconModalView: some View {
        return VStack {
            EmptyView()
            // file not scoped to AppClips
            #if !APPCLIP
            AltIconModalView(header: "App Icons", btnAction: {
                $presentIconModal.wrappedValue = false
            }).analytics(self.analytics)
            #endif
        }
    }

    // MARK: - No Fav View

    public var videoURL: URL? {
        return URL(string: isDeviceIpad() ? Video.remoteIpadFavoriting.rawValue : Video.remoteIphoneFavoriting.rawValue)
    }
    
    private var noFavoritesView: some View {
        GeometryReader { proxy in
            if !AuthController.shared.isLoggedIn || presentNewsletterSignup {
                LoggedOutOptionsView(presentNewsletterSignup: $presentNewsletterSignup, appState: appState, client: client, location: location, proxy: proxy, mainText: favoritesText).analytics(analytics)
            } else {
                VStack(alignment: .center, spacing: BrandPadding.Medium.pixelWidth) {
                    VideoPlayerView(
                        fileURL: videoURL,
                        frameSize: CGSize(width: proxy.size.width, height: isDeviceIpad() ? (proxy.size.height * 0.47) : (proxy.size.height * 0.4)))
                        .aspectRatio(contentMode: .fit)
                        .background(BrandColors.navy.color)
                    VStack(alignment: .leading, spacing: BrandPadding.Small.pixelWidth) {
                        VStack(alignment: .leading, spacing: BrandPadding.Smedium.pixelWidth) {
                            LabelView(text: "Collect your favorites to cycle through them quickly.", style: .nuxTitleLeading)
                                .frame(height: 60)
                            LabelView(text: favoritesText, style: .nuxDescriptionLeading)
                        }
                        .padding(.horizontal, BrandPadding.Tiny.pixelWidth)

                        Spacer().frame(minHeight: 0, maxHeight: isDeviceCompact() ? 10 : 40)
                    }.padding(.vertical, BrandPadding.Small.pixelWidth)
                    .padding(.horizontal, BrandPadding.Medium.pixelWidth)
                    .frame(maxWidth: isDeviceIpad() ? 380 : .infinity)
                    Spacer()
                }
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(0)
    }
    
    // MARK: - Newsletter Opt in
    /* keeping this for the edge case of older users who have favorites from before accounts were real and then select to SIWA outside of our standard "LoggedOutOptionsView" */
    func displayNewsletterPrompt(for user: UserModel) {
        newsletterEmail = user.email
        newsletterUserId = "\(user.id)"
        presentFallbackNewsletter = true
    }

    func submitNewsletterPreferences(for userId: String) {
        guard userId != "" else {
            print("invalid user for submitting newsletter preferences")
            return
        }

        isLoadingNewsletter = true
        cancellable = self.client
            .updateIntentAndNewsletter(userid: userId, intent: selectedIntent.parsingFriendly, subscribe: optInSubscription)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingNewsletter = false
                    self.cancellable = nil
                    switch completion {
                        case .finished:
                            presentFallbackNewsletter  = false
                            break
                        case .failure(let error):
                            print("newsletter pref error: \(error)")
                    }
            },
                receiveValue: { user in
                    isLoadingNewsletter = false
                    analytics?.didGiveIntent(intent: selectedIntent.rawValue)
                    if optInSubscription {
                        analytics?.subscribedToNewsletter(from: .siwa, location: location)
                    }
            })
    }
}

// MARK: - Remote Favorites View

private struct RemoteFavoritesView: View {
    var appState: Binding<AppState>
    
    var client: APIClient
    
    var onTap: (Repository<[ProductModel]>, Int,Int) -> Void
    
    @Environment(\.analytics) var analytics
    
    var containerWidth: CGFloat
    
    init(appState:Binding<AppState>, client:APIClient, containerWidth: CGFloat, onTap: @escaping (Repository<[ProductModel]>, Int,Int)-> Void) {
        self.appState = appState
        self.containerWidth = containerWidth
        self.onTap = onTap
        self.client = client
    }
    
    var body: some View {
        ZStack{
            if (self.client.favoritesRepo.value.count == 0 && self.client.favoritesRepo.requestState == .complete) || appState.needToUpdateFavorites.wrappedValue {
                ActivityIndicatorView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(BrandColors.backgroundView.color)
                    .onAppear() {
                        self.client.favoritesRepo.refresh()
                        appState.needToUpdateFavorites.wrappedValue = false
                    }
            } else {
                ScrollViewReader { scrollview in
                    ScrollView(.vertical) {
                        ProductCardGridView(
                            productsRepo: client.favoritesRepo,
                            showingSignup: .constant(false),
                            appState: appState,
                            client: client,
                            location: .featuredView,
                            numberOfGridItems: isDeviceIpad() ? 3 : 2,
                            canToggleFavorites: true,
                            cardId: .favorites,
                            onTap: { parentOrProductId, variationIndex, productId in
                                if let product = self.client.favoritesRepo.value.first(where: { $0.id == productId }) {
                                    self.analytics?.didViewFavoriteProduct(product: product)
                                    self.onTap(self.client.favoritesRepo, product.id, 0)
                                    // sets label text for product details footer
                                    self.appState.orbCollectionString.wrappedValue = "Favorites"
                                }
                       }).analytics(self.analytics)
                        .onAppear {
                            if let tappedProduct = appState.savedFavorite.wrappedValue, tappedProduct.locationId == .favorites {
                                scrollview.scrollTo("\(tappedProduct.scrollToId)", anchor: .center)
                                appState.savedFavorite.wrappedValue = nil
                            }
                        }
                    }
                }
            }
        }
        
    }
}

// MARK: - Preview

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView(
            appState:.constant(.initialState),
            favoriteProductIDs: .constant([]), client: APIClient(accessToken: "a"), location: .favoritesDrawer, onTap: { _,_,_ in })
            .environment(\.colorScheme, .dark)
    }
}
