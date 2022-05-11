import SwiftUI
import PrimerEngine
import SafariServices
import Combine
import MapleBacon
/**
 The product detail view that displays the current products information with the`ProductDetailCard`, and handles the logic for favoriting, sharing, and purchases.
 */

struct ProductDetailsView: View {
    @Environment(\.analytics) var analytics
    @Binding var isExpanded: Bool
    @State private var cancellable: AnyCancellable? = nil
    @State private var error: Error? = nil
    @State private var isLoadingSIWA: Bool = false
    @State private var offset = CGSize.zero
    @State private var shareableImage: UIImageView = UIImageView()
    @State var isShareReady: Bool = false
    
    var appState: Binding<AppState>
    var client: APIClient
    var product: ProductModel?
    var isRecording: Bool
    
    @Binding var favorites: [Int]
    
    var showCameraToolTip: Binding<Bool>
    let detailsWidth: CGFloat = UIScreen.main.bounds.size.width - 32
    let maxPadWidth: CGFloat = 520
    
    private let cardAnimation:Animation = Animation.interpolatingSpring(mass: 1.0, stiffness: 10, damping: 10, initialVelocity: 4)
    
    var viewMoreByBrand: (Int) -> Void
    
    // MARK: - Body
    
    var body: some View {
        if product != nil || product?.id ?? -1 > 0 {
            return AnyView(
                VStack {
                    ProductDetailCard(favorites: $favorites, isExpanded: $isExpanded, isLoadingSIWA: $isLoadingSIWA, isShareReady: $isShareReady, appState: appState, client: client, product: product, shareAction: share, buyAction: buy, favoriteAction: handleFavorite)
                        .cornerRadius(20)
                        .padding(.horizontal, isDeviceIpad() ? 160 : 16)
                        .onTapGesture {
                            if !isExpanded {
                                withAnimation(.easeInOut(duration: 0.33)) {
                                    if let product = product {
                                        analytics?.didViewProductDetails(product: product)
                                    }
                                    isExpanded.toggle()
                                }
                            }
                        }
                        
                        .onAppear {
                            if self.appState.viewingBuy.wrappedValue {
                                self.appState.viewingBuy.wrappedValue = false
                                self.analytics?.didEndBuyButtonVisit(product: product)
                            }
                            generateShareImage(from: product?.featuredImageOne)
                        }
                    
                        .onChange(of: product?.featuredImageOne, perform: { productImageURL in
                            shareableImage.image = nil
                            isShareReady = false
                            generateShareImage(from: productImageURL)
                        })
                }
            )
        } else { return AnyView(EmptyView())}
    }
                
    // MARK: - Share
       
    func generateShareImage(from url: URL?) {
        guard let urlString = url?.absoluteString else { return }
        guard let resizedURL = URL(string: "\(urlString)?w=800") else { return }

        self.cancellable = MapleBacon.shared.image(with: resizedURL)
          .receive(on: DispatchQueue.main)
          .sink(receiveValue: { image in
            self.shareableImage.image = image
            self.isShareReady = true
          })
    }

    private func share() {

        guard let product = product else { return }
        self.analytics?.didTapShareProduct(prod: product)
        
        DispatchQueue.main.async {
            let vc = ProductShareActivityController(product: product, image: shareableImage.image)

            let scene = UIApplication.shared.connectedScenes.first as! UIWindowScene
            var presentingViewController = scene.windows.first!.rootViewController!
            presentingViewController.modalPresentationStyle = .fullScreen

            if let popoverController = vc.popoverPresentationController {
                popoverController.sourceView = presentingViewController.view //to set the source of your alert
                popoverController.sourceRect = CGRect(x: presentingViewController.view.bounds.midX, y: presentingViewController.view.bounds.midY, width: 0, height: 0) // you can set this as per your requirement.
            }

            while let presented = presentingViewController.presentedViewController {
                presentingViewController = presented
            }

            presentingViewController.present(vc, animated: true, completion: nil)
        }
    }
    
    // MARK: - Favoriting
    
    func handleFavorite() {
        guard let product = product else { return }
        
        if self.favorites.contains(product.id) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            
            if isExpanded {
                self.analytics?.didTapFavorite(product, isAdded: false, from: .expandedDetailView)
            } else {
                self.analytics?.didTapFavorite(product, isAdded: false, from: .miniDetailView)
            }
            
            if AuthController.shared.isLoggedIn, let client = AuthController.shared.apiClient {
                self.cancellable = client.removeFavoriteProduct(product.id)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                                case .finished:
                                    self.favorites.removeAll(where: { $0 == product.id })
                                    break
                                case .failure(let error):
                                    print(error.localizedDescription)
                            }
                        },
                        receiveValue: { _ in })
            } else {
                if self.favorites.count > 0 && self.favorites.contains(product.id) {
                    self.favorites.removeAll(where: { $0 == product.id })
                } else {
                    self.appState.visibleSheet.wrappedValue = .saved
                }
            }
        } else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            
            if isExpanded {
                self.analytics?.didTapFavorite(product, isAdded: true, from: .expandedDetailView)
            } else {
                self.analytics?.didTapFavorite(product, isAdded: true, from: .miniDetailView)
            }
            
            if AuthController.shared.isLoggedIn, let client = AuthController.shared.apiClient, !appState.favoriteProductIDs.wrappedValue.contains(product.id) {
                self.cancellable = client.addFavoriteProduct(product.id)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                                case .finished:
                                    self.analytics?.favoriteComplete(product)
                                    self.favorites.append(product.id)
                                    break
                                case .failure(let error):
                                    print(error.localizedDescription)
                            }
                        },
                        receiveValue: { _ in })
            } else {
                UserDefaults.loggedOutFavorite = product.id
                if self.favorites.count > 0 && self.favorites.contains(product.id) {
                    self.favorites.removeAll(where: { $0 == product.id })
                } else {
                    self.appState.visibleSheet.wrappedValue = .saved
                }
            }
        }
    }
    
    // MARK: - Buy
    
    private func buy() {
        if isExpanded {
            
        } else {
            self.analytics?.didTapMiniBuyButton(product: self.product)
        }
        
//        self.viewingBuy = true
        self.appState.viewingBuy.wrappedValue = true
        let url = product?.purchaseLink ?? URL(string: "https://www.primer.com")!
        let viewController = SFSafariViewController(url: url)
        
        let windowScenes = UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
        
        guard let scene = windowScenes.first else { return }
        guard let windowSceneDelegate = scene.delegate as? UIWindowSceneDelegate else { return }
        self.analytics?.didStartBuyButtonVisit(product: product)
        windowSceneDelegate.window??.rootViewController?.present(viewController, animated: true, completion: nil)
    }
}
            
// MARK: - Preview

struct ProductDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let decoder = JSONDecoder()
        guard
            let url = Bundle.main.url(forResource: "product", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let product = try? decoder.decode(ProductModel.self, from: data)
        
        else {
            return AnyView(ProductDetailsView(
                            isExpanded: .constant(false),
                            appState:.constant(.initialState),
                            client:APIClient(accessToken: "123456"),
                            isRecording: false,
                            favorites:  .constant([]),
                            showCameraToolTip: .constant(true),
                            viewMoreByBrand: { _ in }))
            
        }
        return AnyView(ProductDetailsView(
                        isExpanded: .constant(false),
                        appState:.constant(.initialState),
                        client:APIClient(accessToken: "123456"),
                        product: product,
                        isRecording: false,
                        favorites:  .constant([]),
                        showCameraToolTip: .constant(true),
                        viewMoreByBrand: { _ in }))
        
    }
}
