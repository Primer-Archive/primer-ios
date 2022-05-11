//
//  SearchView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 11/17/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

// MARK: - Search view

struct SearchView<Content: View>: View {
    @Environment(\.analytics) var analytics
    @ObservedObject var searchManager: SearchManager
    @State var tappedFilterIndex: Int = 0
    @State var tappedFilter: SearchFilterModel? = nil
    @State var presentFilterModal: Bool = false
    @State var currentOffset: CGFloat = 0
    @State var showSignUp: Bool = false
    var client: APIClient
    var appState: Binding<AppState>
    var selectedBrandName: String?
    var isBrandShareVisible: Bool = false
    var customSearchText: String? = nil
    var onSelectProduct: (Repository<[ProductModel]>, Int, Int) -> Void
    var headerAction: () -> Void
    let content: Content
    var cardId: ProductCardScrollId = .searchResult

    // MARK: - Init
    
    init(client: APIClient, appState: Binding<AppState>, selectedBrandName: String? = nil, onSelectProduct: @escaping ((Repository<[ProductModel]>, Int,Int) -> Void), headerAction: @escaping () -> Void = {}, @ViewBuilder content: () -> Content) {
        self.client = client
        self.selectedBrandName = selectedBrandName
        if let brandName = selectedBrandName {
            self.isBrandShareVisible = true
            self.customSearchText = "Search \(brandName)"
        }
        self.appState = appState
        self.onSelectProduct = onSelectProduct
        self.searchManager = client.searchManager
        self.headerAction = headerAction
        self.content = content()
        self.lockBrandSelection()
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollViewReader { scrollview in
            VStack(spacing: 0) {
                
                // MARK: - Search Bar
                
                VStack(spacing: 0) {
                    
                    HStack(spacing: 0) {
                        SearchBarView(text: $searchManager.text, isSearching: $searchManager.searchActive, customInactiveText: customSearchText, scrollToAction: {
//                            scrollview.scrollTo("ScrollTop", anchor: .top)
                            #if APPCLIP
                            if searchManager.state == .inactive {
                                withAnimation {
                                    searchManager.state = .active
                                }
                            }
                            #endif
                        }, exitSearchAction: {
                            fireSearchAbandonedEvent()
                            searchManager.clearAll()
                            #if APPCLIP
                            lockBrandSelection()
                            #endif
                            if !searchManager.hasTappedResult {
//                                scrollview.scrollTo("ScrollTop", anchor: .top)
                            }
                        }, clearSearchTextAction: {
                            fireSearchAbandonedEvent()
                            if searchManager.searchFilters.value.count > 0 {
                                searchManager.clearTextPreserveFilters()
                            }
                        }).analytics(analytics)
                        
                        if isBrandShareVisible, !searchManager.searchActive {
                            SmallSystemIcon(style: .clearShareSquare, isButton: true) {
                                self.headerAction()
                            }.padding(.trailing, BrandPadding.Tiny.pixelWidth)
                        }
                    }
                    // displays category filters while actively searching
                    LazyButtonStack(axis: .horizontal, vPadding: .None) {
                        ForEach(searchManager.searchFilters.value.indices, id: \.self) { index in
                            let filter = searchManager.searchFilters.value[index]
                            if filter.name == "Brand", let brandName = selectedBrandName {
                                CategoryButton(
                                    text: brandName, filter: filter, hasDropdown: true) {
                                    categoryAction(for: filter, tappedIndex: index)
                                }.onAppear {
                                    lockBrandSelection()
                                }
                                .allowsHitTesting(false)
                            } else {
                                CategoryButton(
                                    text: filter.name, filter: filter, hasDropdown: true) {
                                    categoryAction(for: filter, tappedIndex: index)
                                }
                            }
                        }
                    }.frame(height: searchManager.state != .inactive ? 30 : 0)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, searchManager.state != .inactive ? BrandPadding.Small.pixelWidth : 0)

                    Divider()
                        .frame(maxWidth: .infinity)
                        .background(BrandColors.softWhiteToggleGrey.color)
                }
                
                // MARK: - Content
                if searchManager.state == .inactive || searchManager.state == .active {
                    ScrollView(.vertical) {
                        content
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if searchManager.state == .results {
                    ScrollView(.vertical) {
                        Spacer().frame(height: 1)
                            .background(GeometryReader { proxy in
                                Color.clear
                                    .preference(key: OffsetPreferenceKey.self, value: proxy.frame(in: .named("frameLayer")).minY)
                                
                            })
                        searchResults
                            .onAppear {
                                if let tappedProduct = appState.savedProduct.wrappedValue, tappedProduct.locationId == cardId {
                                    scrollview.scrollTo("\(tappedProduct.scrollToId)", anchor:.center)
                                    appState.savedProduct.wrappedValue = nil
                                }
                            }
                    }
                    .coordinateSpace(name: "frameLayer")
                    .onPreferenceChange(OffsetPreferenceKey.self, perform: { value in
                        if searchManager.searchRepo.requestState == .complete {
                            UIApplication.shared.windows.forEach { $0.endEditing(false) }
                        }
                    })
                }
            }.background(BrandColors.backgroundView.color)
            
            // MARK: - Filter Popover
        
            .overlay(
                PopOverView(isVisible: _presentFilterModal, content: {
                    FilterPopoverView(filter: $tappedFilter, closeBtnAction: {
                        presentFilterModal = false
                    }, tappedFilterAction: { itemIndex in
                        tappedFilterItem(at: itemIndex)
                    }, resetFiltersAction: {
                        searchManager.clearFilters(for: tappedFilter)
                        analytics?.filtersReset(for: tappedFilter?.name ?? "")
                    })
                .cornerRadius(10)
                .modifier(SwipeModifier(currentPosition: $currentOffset, isVisible: $presentFilterModal, offsetHeight: UIScreen.main.bounds.height * 0.4))
            }), alignment: .bottom)
            .edgesIgnoringSafeArea(.bottom)
            .background(BrandColors.backgroundView.color)
        }
        .navigationBarItems(trailing: EmptyView())
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        .sheet(isPresented: $showSignUp) {
            FavoritesView(appState: appState,
                          favoriteProductIDs: appState.favoriteProductIDs,
                          client: client,
                          location: .searchResultPopup) { _, _, _ in
            }.analytics(analyticInstance)
        }
    }
    
    // MARK: - Search Results View
    
    var searchResults: some View {
        VStack {
            ProductCardGridView(productsRepo: searchManager.searchRepo, showingSignup: $showSignUp, appState: appState, client: client, location: .searchResult, numberOfGridItems: isDeviceIpad() ? 3 : 2, cardId: .searchResult, onTap: { parentOrProductId, variationIndex, productId in
                if let product = self.searchManager.searchRepo.value.first(where: { $0.id == productId }) {
                    self.onSelectProduct(self.searchManager.searchRepo, product.id, 0)
                    searchManager.hasTappedResult = true
                    analytics?.searchResultsTapped(product, searchString: searchManager.text, filters: searchManager.searchFilters.value)
                    
                    // constructs the label text for product details footer
                    var filterString = ""
                    if searchManager.text != "" {
                        filterString.append("\"\(searchManager.text)\"")
                    }
                    
                    searchManager.searchFilters.value.forEach { filter in
                        filter.items?.forEach { item in
                            if item.isSelected {
                                if filterString == "" {
                                    filterString.append("\(item.name)")
                                } else {
                                    filterString.append(", \(item.name)")
                                }
                            }
                        }
                    }
                    self.appState.orbCollectionString.wrappedValue = filterString
                }
            }, onComplete: {
                if searchManager.searchRepo.requestState == .complete {
                    analytics?.searchResults(for: searchManager.text, filters: searchManager.searchFilters.value, resultsFound: (searchManager.searchRepo.value.count > 0))
                }
            }, onFavorite: {
                // keeps abandon metric from firing if user has added a favorite
                searchManager.hasTappedResult = true
            }).analytics(self.analytics)
        }.frame(maxWidth: .infinity)
    }

    // MARK: - Helper methods
    
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
        self.searchManager.refresh()
        
        // if filter was added, track metric for new filter
        if let tappedItem = self.searchManager.searchFilters.value[tappedFilterIndex].items?[index], tappedItem.isSelected {
            analytics?.filterApplied(for: tappedFilter?.name ?? "", filter: tappedItem, currentSearch: searchManager.text)
        }
    }
    
    // returns all of the current filter selections
    func currentSelectedFilters() -> [FilterItem] {
        var filterItems: [FilterItem] = []
        for filter in searchManager.searchFilters.value {
            if let selectedItems = filter.items?.filter({$0.isSelected}) {
                filterItems.append(contentsOf: selectedItems)
            }
        }
        return filterItems
    }
    
    // set app clip brand as selected
    func lockBrandSelection() {
        #if APPCLIP
        if let index = searchManager.searchFilters.value.firstIndex(where: { $0.name == "Brand" }),
           let brandIndex = searchManager.searchFilters.value[index].items?.firstIndex(where: { $0.name == selectedBrandName }) {
            searchManager.searchFilters.value[index].items?[brandIndex].isSelected = true
        }
        #endif
    }
    
    // fire abandon search analytic event
    func fireSearchAbandonedEvent() {
        if !searchManager.hasTappedResult {
            analytics?.searchResultsAbandoned(query: searchManager.text, filters: searchManager.searchFilters.value, resultsFound: (searchManager.searchRepo.value.count > 0))
        }
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = .zero
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

//
//struct SearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        SearchView()
//    }
//}
