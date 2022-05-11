

import SwiftUI
import PrimerEngine


// MARK: - Products View
/**
 Holds the items displayed in the "Products" drawer, wrapped in the Search and Filter components. Toggles to brand page, and displays on re-open if previously saved brand available.
 */
struct ProductsView: View {
    @Environment(\.analytics) var analytics
    @ObservedObject var searchManager: SearchManager
    @ObservedObject var savedBrand: SavedBrandManager
    @State var tappedFilterIndex: Int = 0
    @State var tappedFilter: SearchFilterModel? = nil
    @State var presentFilterModal: Bool = false
    @State var showSignUp: Bool = false
    @State var isBrandActive: Bool = false
    @State var tappedBrand: BrandModel?
    
    var client: APIClient
    var appState: Binding<AppState>
    var selectedBrandId: Int
    var onSelectProduct: (Repository<[ProductModel]>, Int, Int) -> Void
        
    init(client: APIClient, appState: Binding<AppState>, selectedBrandId: Int? = nil, onSelectProduct: @escaping ((Repository<[ProductModel]>, Int,Int) -> Void)){
        self.client = client
        self.selectedBrandId = selectedBrandId ?? 0
        self.appState = appState
        self.onSelectProduct = onSelectProduct
        self.searchManager = client.searchManager
        self.savedBrand = appState.savedBrandManager.wrappedValue
        if let previouslyTappedBrand = savedBrand.brand {
            tappedBrand = previouslyTappedBrand
        }
    }

    // MARK: - Body
    
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                
                if !appState.hasSavedBrand.wrappedValue {
                SearchView(client: client, appState: appState, onSelectProduct: onSelectProduct, content: {
                    VStack(spacing: 0) {
                            Spacer().frame(height: 1)
                                .id("ScrollTop")
                        
                            if searchManager.state == .inactive || searchManager.state == .active {
                                
                                // MARK: Feature/Colors
                                
                                LazyVStack(alignment: .leading, spacing: BrandPadding.Tiny.pixelWidth) {
                                    if !searchManager.searchActive {
                                        FeaturedProductCollectionsView(client: self.client, appState: appState, onTap: self.onSelectProduct).analytics(analytics)
                                    } else {
                                        FadingLabel(text: "Colors", style: .sectionHeader, offset: 70)
                                            .padding(.bottom, isDeviceIpad() ? BrandPadding.Smedium.pixelWidth : 0)
                                        if let colorFilter = searchManager.searchFilters.value.first(where: { $0.name == "Color"}), let colors = colorFilter.items {
                                            LazyButtonStack(axis: .horizontal) {
                                                ForEach(colors.indices, id: \.self) { index in
                                                    CategoryButton(text: colors[index].name, hasDropdown: false, btnAction: {
                                                        self.tappedSuggestion(for: searchManager.searchFilters.value.first(where: { $0.name == "Color"}), tappedIndex: index)
                                                    })
                                                }
                                            }
                                        }
                                    }

                                    // MARK: - Brands
                                    
                                    FadingLabel(text: "Brands", style: .sectionHeader, offset: 110)
                                    .padding(.vertical, isDeviceIpad() ? BrandPadding.Smedium.pixelWidth : 0)
                                    
                                    ScrollView(.horizontal) {
                                        LazyHStack(spacing: !searchManager.searchActive ? (isDeviceIpad() ? 24 : 16) : 8) {
                                            if !searchManager.searchActive {
                                                ForEach(client.brandsRepo.value) { brand in
                                                    PreviewCircle(type: .brand(url: brand.logo), size: CGSize(width: isDeviceIpad() ? 100 : 82, height: isDeviceIpad() ? 100 : 82))
                                                        .clipShape(Circle())
                                                        .id("BrandLink\(brand.id)")
                                                        .frame(height: isDeviceIpad() ? 100 : 82)
                                                        .onTapGesture {
                                                            savedBrand.brand = brand
                                                            withAnimation {
                                                            appState.hasSavedBrand.wrappedValue = true
                                                            }
                                                            self.analytics?.didSelectBrandInLibrary(brand: brand)
                                                        }
                                                }
                                                .transition(AnyTransition.opacity.animation(.default))
                                            } else if let brandsFilter = searchManager.searchFilters.value.first(where: { $0.name == "Brand"}), let brands = brandsFilter.items {
                                                ForEach(brands.indices, id: \.self) { index in
                                                    CategoryButton(text: brands[index].name, hasDropdown: false, btnAction: {
                                                        self.tappedSuggestion(for: searchManager.searchFilters.value.first(where: { $0.name == "Brand"}), tappedIndex: index)
                                                    }).id("BrandPill\(index)")
                                                    .frame(height: 44)
                                                }
                                            }
                                        }.padding(BrandPadding.Medium.pixelWidth)
                                    }
                                    
                                    // MARK: - Categories
                                    
                                    FadingLabel(text: "Categories", style: .sectionHeader, offset: 110)
                                    .padding(.bottom, isDeviceIpad() ? BrandPadding.Smedium.pixelWidth : 0)
                                    
                                    LazyButtonStack(axis: .horizontal, spacing: !searchManager.searchActive ? (isDeviceIpad() ? 24 : 16) : 8) {
                                        if !searchManager.searchActive {
                                            ForEach(self.client.categoryController.value) { category in
                                                CategoryLink(
                                                    tappedFromSearch: searchManager.searchActive,
                                                    category: category,
                                                    onSelectProduct: onSelectProduct)
                                                    .id("Category\(category.id)")
                                                    .onTapGesture {
                                                        if let filter = searchManager.searchFilters.value.first(where: { $0.name == "Category"}), let tappedIndex = filter.items?.firstIndex(where: { $0.name == category.name}) {
                                                            self.tappedSuggestion(for: filter, tappedIndex: tappedIndex)
                                                        }
                                                        if !searchManager.searchActive {
                                                            self.analytics?.didSelectCategoryInLibrary(category: category)
                                                        }
                                                    }
                                            }
                                            
                                            .transition(AnyTransition.opacity.animation(.default))
                                        } else if let categoryFilter = searchManager.searchFilters.value.first(where: { $0.name == "Category"}), let categories = categoryFilter.items {
                                            ForEach(categories.indices, id: \.self) { index in
                                                CategoryButton(text: categories[index].name, hasDropdown: false, btnAction: {
                                                    self.tappedSuggestion(for: searchManager.searchFilters.value.first(where: { $0.name == "Category"}), tappedIndex: index)
                                                })
                                                .id("CategoryPill\(index)")
                                            }
                                        }
                                    }
                                    
                                    // MARK: - Inspo
                                    
                                    if !searchManager.searchActive {
                                        FadingLabel(text: "Inspiration", style: .sectionHeader, offset: 110)
                                            .padding(.bottom, isDeviceIpad() ? BrandPadding.Smedium.pixelWidth : 0)
                                        
                                        ProductCardGridView(
                                            productsRepo: self.client.productsRepo,
                                            showingSignup: $showSignUp,
                                            appState: appState,
                                            client: client, location: .featuredView,
                                            customCardHeight: isDeviceIpad() ? (proxy.size.width / 2) : proxy.size.width,
                                                imageWidth: 500,
                                            numberOfGridItems: isDeviceIpad() ? 2 : 1,
                                            onTap: { parentOrProductId, variationIndex, productId in
                                            if let product = self.client.productsRepo.value.first(where: { $0.id == productId }) {
                                                self.onSelectProduct(self.client.productsRepo, product.id, 0)
                                                self.appState.orbCollectionString.wrappedValue = "Inspiration"
                                            }
                                        }).analytics(self.analytics)
                                        .padding(BrandPadding.Small.pixelWidth)
                                    }
                                }
                            }
                    }.padding(.vertical, BrandPadding.Medium.pixelWidth)
                })
                .navigationBarItems(trailing: EmptyView())
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarHidden(true)
                .background(BrandColors.backgroundView.color)
                    
                } else {
                    
                    // MARK: - Brand Page
                    
                    BrandPageView(savedBrand: savedBrand, appState: appState, client: client, containerWidth: proxy.size.width, onSelectProduct: onSelectProduct)
                        .analytics(analytics)
                        .background(BrandColors.backgroundView.color)
                }
            }
        }

        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showSignUp) {
            FavoritesView(appState: appState,
                          favoriteProductIDs: appState.favoriteProductIDs,
                          client: client,
                          location: .productsDrawer) { _, _, _ in
            }.analytics(analyticInstance)
        }
        .onAppear {
            self.analytics?.didStartProductsView()
        }
        .onDisappear(perform: {
            self.analytics?.didEndProductsView()
        })
    }

    // MARK: - Helper methods
    
    // select category filter from suggestion buttons
    func tappedSuggestion(for category: SearchFilterModel?, tappedIndex: Int) {
        guard let category = category else { return }
        if let filterIndex = searchManager.searchFilters.value.firstIndex(where: { $0.name == category.name}) {
            tappedFilter = searchManager.searchFilters.value[filterIndex]
            tappedFilterIndex = filterIndex
            searchManager.searchFilters.value[tappedFilterIndex].items?[tappedIndex].isSelected = true
            searchManager.refresh()
            
            if searchManager.searchActive, let tappedItem = searchManager.searchFilters.value[tappedFilterIndex].items?[tappedIndex] {
                self.analytics?.searchSuggestionTapped(from: category.name, tappedSelection: tappedItem.name)
            }
        }
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = .zero
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

// MARK: - Preview

struct ProductsView_Previews: PreviewProvider {
    static var previews: some View {
        ProductsView(client: APIClient(accessToken: "asdf"), appState: .constant(.initialState), selectedBrandId: 0, onSelectProduct: {_,_,_ in })
    }
}
