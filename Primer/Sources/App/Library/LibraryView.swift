import SwiftUI
import Combine
import PrimerEngine


struct LibraryView: View {
    
    var client: APIClient
    
    var appState: Binding<AppState>
    
    var selectedBrandId: Int
    
    var onSelectProduct: ([ProductModel], Int, Int) -> Void
    
    @Environment(\.analytics) var analytics
    
//    @ObservedObject private var brandsController: RequestController<[BrandModel]>
        
    init(client: APIClient, appState:Binding<AppState>, selectedBrandId: Int? = nil, onSelectProduct: @escaping ([ProductModel], Int, Int) -> Void) {
        self.client = client
        self.appState = appState
        self.onSelectProduct = onSelectProduct
//        self.brandsController = client.brandsController
        self.selectedBrandId = selectedBrandId ?? 0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16) {
//                    ForEach(brandsController.value) { brand in
//
//                        BrandLink(
//                            brand: brand,
//                            selectedBrandId: self.selectedBrandId,
//                            client: self.client, appState: appState).analytics(self.analytics)
//                    }
//                    .transition(AnyTransition.opacity.animation(.default))
                    
                }
            .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 80 : 16)
            .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
            .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 80 : 16)
            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .navigationBarTitle("Brands", displayMode: .large)
        }
        .onAppear {
            self.analytics?.didStartLibraryView()
//            self.brandsController.refresh()
            
            if(!UserDefaults.hasSeenBrowseProductsHelper){
                UserDefaults.hasSeenBrowseProductsHelper = true
            }
        }
        .onDisappear{
            self.analytics?.didEndLibraryView()
        }
        .tabItem {
            SwiftUI.Image(systemName: "book.fill")
            Text("Library")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView(client: APIClient(accessToken: "foo"), appState: .constant(.initialState), onSelectProduct: { _,_,_ in })
    }
}
