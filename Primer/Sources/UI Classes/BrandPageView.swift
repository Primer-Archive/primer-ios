//
//  BrandPageView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/8/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine
import Combine

// MARK: - Brand Page

struct BrandPageView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.analytics) var analytics
    @ObservedObject var searchManager: SearchManager
    @ObservedObject var savedBrand: SavedBrandManager
    @State var tappedFilterIndex: Int = 0
    @State var tappedFilter: SearchFilterModel? = nil
    @State var presentFilterModal: Bool = false
    @State var currentOffset: CGFloat = 0
    @State private var showShareSheet = false
    @State var isNavHidden: Bool
    @State var isFilterLocked = false
    @State var trackingViewIsVisible = true
    @State var showSignUp: Bool = false
    @State var collectionID: Int?
    @State var collectionTappedBack: Bool = false
    
    @State var headerOffset: CGFloat = 0.0
    @State var isHeaderPinned: Bool = false

    var appState: Binding<AppState>
    var client: APIClient
    var containerWidth: CGFloat
    var cardId: ProductCardScrollId = .brandSearchResult
    var onSelectProduct: (Repository<[ProductModel]>, Int, Int) -> Void
    
    
    // MARK: - Init
    
    init(savedBrand: SavedBrandManager, appState: Binding<AppState>, client: APIClient, containerWidth: CGFloat, onSelectProduct: @escaping (Repository<[ProductModel]>, Int, Int) -> Void) {
        self.savedBrand = savedBrand
        self.appState = appState
        self.client = client
        self.containerWidth = containerWidth
        self.onSelectProduct = onSelectProduct
        self.searchManager = client.brandSearchManager
        self.savedBrand = savedBrand
        if appState.selectedCollectionId.wrappedValue == nil {
            _isNavHidden = State(initialValue: true)
        } else {
            _isNavHidden = State(initialValue: false)
        }
    }
    
    // MARK: - Body

    var body: some View {
        ScrollViewReader { scrollview in
            VStack {
                if let brand = savedBrand.brand {
                    NavigationLink(
                        destination: BrandCollectionGridView(savedBrand: savedBrand, isNavHidden: $isNavHidden, tappedBack: $collectionTappedBack, appState: appState, client: client, cardId: .brandFeaturedCollection, onSelectProduct: onSelectProduct).analytics(analytics)
                            .onAppear {
                                isNavHidden = false
                            },
                        tag: savedBrand.savedCollection?.id ?? -1, selection: $collectionID
                    ) { EmptyView() }

                VStack(alignment: .leading, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {

                            // MARK: - Header Image Stack
                            
                            ZStack(alignment: .top) {
                                
                                BrandPageHeaderView(brand: brand, containerWidth: containerWidth)
                                           
                                GeometryReader { proxy in
                                    CustomHeaderView(leadingIcon: .x12, text: "", trailingIcon: .shareSquareNavy) {
                                        self.exitPage()
                                    } trailingBtnAction: {
                                        shareButtonTapped()
                                    }
                                    .onAppear {
                                        // grab top of view offset for use with sticky explore bar states
                                        #if !APPCLIP
                                        self.headerOffset = proxy.frame(in: .global).origin.y
                                        #else
                                        self.headerOffset = 50
                                        #endif
                                    }
                                    .sheet(isPresented: $showShareSheet) {
                                        ShareSheet(activityItems: [
                                        "https://primer.com/partners/" + brand.slug + "/"])
                                    }
                                }
                            }
                            
                            // MARK: - Featured Collection
                            
                            LabelView(text: "Featured Collections", style: .bodyMedium)
                                .padding(BrandPadding.Medium.pixelWidth)
                                .sheet(isPresented: $showSignUp) {
                                    FavoritesView(appState: appState,
                                                  favoriteProductIDs: appState.favoriteProductIDs,
                                                  client: client,
                                                  location: .brandViewPopup) { _, _, _ in
                                    }.analytics(analyticInstance)
                                }
                                    
                            BrandFeaturedCollections(savedBrand: savedBrand, isNavHidden: $isNavHidden, appState: appState, client: client, containerWidth: containerWidth, onSelectProduct: onSelectProduct).analytics(analytics)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                                
                            // MARK: - Explore Products
                            
                            // Sticky Filter Bar
                            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                                Section(header:
                                    ExploreBarView(isHeaderPinned: $isHeaderPinned, exitPage: exitPage, content: {
                                        HStack {
                                            Spacer()
                                            if let filter = searchManager.searchFilters.value.first(where: { $0.name == "Color" }) {
                                                CategoryButton(
                                                    text: "Filter by \(filter.name)", filter: filter, hasDropdown: true, buttonColor: .categoryNavy) {
                                                    if let index = searchManager.searchFilters.value.firstIndex(where: { $0.name == "Color" }) {
                                                        let filter = searchManager.searchFilters.value[index]
                                                        categoryAction(for: filter, tappedIndex: index)
                                                    }
                                                }
                                            }
                                        }.frame(minWidth: 150)
                                    })
                                ) {
                                    VStack {
                                        // tracks if the sticky header is pinned or not
                                        GeometryReader { proxy in
                                            Spacer().frame(width: 1, height: 1)
                                                .onChange(of: proxy.frame(in: .global)) { value in
                                                    
                                                    // explore bar height is 50, fire as soon as they overlap
                                                    if value.origin.y - 50 < self.headerOffset {
                                                        if isHeaderPinned { return }
                                                        withAnimation {
                                                            isHeaderPinned = true
                                                        }
                                                    } else {
                                                        if !isHeaderPinned { return }
                                                        withAnimation {
                                                            isHeaderPinned = false
                                                        }
                                                    }
                                                }
                                        }.frame(height: 1)

                                        brandResults
                                            .padding(.horizontal, BrandPadding.Tiny.pixelWidth)
                                            .onAppear {
                                                if let tappedProduct = appState.savedProduct.wrappedValue, tappedProduct.locationId == cardId {
                                                    scrollview.scrollTo("\(tappedProduct.scrollToId)", anchor: .center)
                                                    appState.savedProduct.wrappedValue = nil
                                                }
                                            }
                                    }
                                    
                                }.id("FilterSection")
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarItems(trailing: EmptyView())
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarHidden(isNavHidden)
                .navigationBarBackButtonHidden(isNavHidden)
                    
                // MARK: - Filter Popovers
                
                .overlay(
                    PopOverView(isVisible: _presentFilterModal, content: {
                        FilterPopoverView(filter: $tappedFilter, closeBtnAction: {
                            presentFilterModal = false
                        }, tappedFilterAction: { itemIndex in
                            tappedFilterItem(at: itemIndex)
                            scrollview.scrollTo("FilterSection", anchor: .top)
                        }, resetFiltersAction: {
                            searchManager.clearFilters(for: tappedFilter)
                            analytics?.filtersReset(for: tappedFilter?.name ?? "")
                            scrollview.scrollTo("FilterSection", anchor: .top)
                        })
                    .cornerRadius(10)
                    .modifier(SwipeModifier(currentPosition: $currentOffset, isVisible: $presentFilterModal, offsetHeight: UIScreen.main.bounds.height * 0.4))
                }), alignment: .bottom)
            }
            }
        }
        .background(BrandColors.backgroundView.color)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            self.collectionID = appState.selectedCollectionId.wrappedValue
            if collectionID == nil {
                isNavHidden = true
            }
                        
            // save prev state for reopen after product tap, or collection viewing
            if appState.savedProduct.wrappedValue == nil, !collectionTappedBack {
                searchManager.clearAll()
                setCurrentBrandAsFilter()
                self.searchManager.refresh()
            }
            if let brand = savedBrand.brand {
                self.analytics?.didStartBrandView(brand: brand)
                appState.selectedBrandId.wrappedValue = brand.id
            }
        }
        .onDisappear {
            if let brand = savedBrand.brand {
                self.analytics?.didEndBrandView(brand: brand)
            }
        }
        .onChange(of: appState.selectedCollectionId.wrappedValue, perform: { selectedCollection in
            self.collectionID = selectedCollection
        })
    }
    
    // MARK: - Search Results View
    
    var brandResults: some View {
        VStack {
            if searchManager.searchRepo.value.count == 0, searchManager.searchRepo.requestState == .none {
                ActivityIndicatorView()
                    .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 500)
                    .onAppear {
                        if appState.savedProduct.wrappedValue == nil, !collectionTappedBack {
                            searchManager.clearAll()
                            setCurrentBrandAsFilter()
                            self.searchManager.refresh()
                        }
                    }
            } else {
                ProductCardGridView(productsRepo: searchManager.searchRepo, showingSignup: $showSignUp, appState: appState, client: client, location: .searchResult, numberOfGridItems: isDeviceIpad() ? 3 : 2, shouldFlatten: true, cardId: cardId, onTap: { parentOrProductId, variationIndex, productId in
                    if let product = self.searchManager.searchRepo.value.first(where: { $0.id == parentOrProductId }) {
                        self.onSelectProduct(self.searchManager.searchRepo, product.id, variationIndex)
                        
                        // constructs the label text for product details footer
                        if let brand = savedBrand.brand {
                            var filterString = "\(brand.name)"
                            
                            searchManager.searchFilters.value.forEach { filter in
                                if filter.name != "Brand" {
                                    filter.items?.forEach { item in
                                        if item.isSelected {
                                            filterString.append(", \(item.name)")
                                        }
                                    }
                                }
                            }
                            self.appState.orbCollectionString.wrappedValue = filterString
                        }
                        
                        analytics?.searchResultsTapped(product, searchString: searchManager.text, filters: searchManager.searchFilters.value, location: .brandView)
                    }
                }, onComplete: {
                    if searchManager.searchRepo.requestState == .complete {
                        analytics?.searchResults(for: searchManager.text, filters: searchManager.searchFilters.value, resultsFound: (searchManager.searchRepo.value.count > 0), location: .brandView)
                    }
                }).analytics(self.analytics)
                .id("ProductCount\(searchManager.searchRepo.value.count)")
            }
            Spacer()
                .frame(minHeight: 50, maxHeight: UIScreen.main.bounds.height - 100)
        }.frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height - 100)
    }

    // MARK: - Helper methods
    
    func exitPage() {
        searchManager.clearAll()

        appState.savedProduct.wrappedValue = nil
        appState.selectedCollectionId.wrappedValue = nil
        
        withAnimation {
            appState.hasSavedBrand.wrappedValue = false
            savedBrand.brand = nil
        }
        
        #if APPCLIP
        appState.visibleSheet.wrappedValue = nil
        #endif
    }
    
    // initial brand setup
    func setCurrentBrandAsFilter() {
    
        guard let brand = savedBrand.brand else { return }
        // assign current brand
        if let brandFilterIndex = searchManager.searchFilters.value.firstIndex(where: { $0.name == "Brand" }),
           let currentBrandIndex = searchManager.searchFilters.value[brandFilterIndex].items?.firstIndex(where: { $0.id == brand.id}) {
            self.searchManager.searchFilters.value[brandFilterIndex].items?[currentBrandIndex].isSelected = true
        }
    }

    // share helper
    func shareButtonTapped() {
        guard let brand = savedBrand.brand else { return }
        self.analytics!.didTapShareBrand(brand: brand)
        self.showShareSheet.toggle()
    }
    
    // tapped filter category button
    func categoryAction(for filter: SearchFilterModel, tappedIndex: Int) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        tappedFilterIndex = tappedIndex
        tappedFilter = filter
        presentFilterModal = true
        analytics?.filterCategoryTapped(filter.name)
    }
        
    // toggle selections within filter popover
    func tappedFilterItem(at index: Int) {
        if tappedFilter?.select_type == .single, let previousIndex = self.searchManager.searchFilters.value[tappedFilterIndex].items?.firstIndex(where: { $0.isSelected}) {
            self.searchManager.searchFilters.value[tappedFilterIndex].items?[previousIndex].isSelected = false
        }
        self.searchManager.searchFilters.value[tappedFilterIndex].items?[index].isSelected.toggle()
        self.setCurrentBrandAsFilter()
        self.searchManager.refresh()
            
        // if filter was added, track metric for new filter
        if let tappedItem = self.searchManager.searchFilters.value[tappedFilterIndex].items?[index], tappedItem.isSelected {
            analytics?.filterApplied(for: tappedFilter?.name ?? "", filter: tappedItem, currentSearch: searchManager.text)
        }
    }

}

// MARK: - Preview

// i don't think there's currently a .json file with Brand template, can't preview yet
//struct BrandPageView_Previews: PreviewProvider {
//
//    static var previews: some View {
//        if let product = loadProduct() {
//            BrandPageView(product: product)
//            BrandPageHeaderView(product: product)
//        } else {
//            Text(text)
//        }
//    }
//}
private struct OffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = .zero
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}
