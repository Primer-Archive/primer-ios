//
//  SearchManager.swift
//  Primer
//
//  Created by James Hall on 11/11/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import Foundation
import Combine
import ARKit


public enum SearchViewState {
    case inactive
    case active
    case results
}
public class BrandSearchManager: SearchManager {
    override public init(client: APIClient) {
        super.init(client: client)
        searchRepo = BrandSearchResultsRepository()
    }
    
    public override func clearAll() {
        searchRepo = BrandSearchResultsRepository()
        text = ""
        for (filterIndex, _) in searchFilters.value.enumerated() {
            if let items = searchFilters.value[filterIndex].items {
                for (index, _) in items.enumerated() {
                    searchFilters.value[filterIndex].items?[index].isSelected = false
                }
            }
        }
        self.refresh()
    }
}
public class SearchManager: ObservableObject {
        
    private (set) public var searchFilters: RequestController<[SearchFilterModel]>!
    
    @Published public var searchRepo: SearchResultsRepository
    @Published public var state: SearchViewState = .inactive
    @Published public var searchActive: Bool = false
    @Published public var hasTappedResult: Bool = false
    @Published public var text = "" {
        didSet {
            // this is applied separately because we don't want the milliseconds delay
            if text.count > 0, text.count < 3 {
                withAnimation {
                    if state == .inactive {
                        state = .active
                    }
                }
            }
        }
    }
    
    var cancellables: Set<AnyCancellable> = []
    
    
    public init(client: APIClient){
        searchFilters = RequestController(makeRequest: client.filters(), initialValue: [])
        searchRepo = SearchResultsRepository()
        
        $text
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .map({ (string) -> String? in
                if string.count < 3 {
                    return nil
                }
                return string
            })
            .compactMap{ $0 }
            .sink { _ in
                
            } receiveValue: { [self] (searchField) in
                self.refresh()
            }.store(in: &cancellables)
        
        searchFilters.refresh()
    }
    
    public func refresh() {
        hasTappedResult = false
        var queryItems: [URLQueryItem] = []
        if self.text.count >= 3 {
            queryItems.append(URLQueryItem(name: "q", value: self.text))
        }
    
        searchFilters.value.forEach { filter in
            if let items = filter.searchItemsQuery {
                queryItems.append(URLQueryItem(name: filter.plural.lowercased(), value: items))
            }
        }
        
        withAnimation {
            self.searchActive = queryItems.count > 0
            
            if searchActive {
                if state != .results {
                    state = .results
                }
            } else {
                if state != .inactive {
                    // when user clears filter with text < 3 still present
                    if text.count > 0 {
                        queryItems.append(URLQueryItem(name: "q", value: self.text))
                        searchActive = true
                        if state != .results {
                            state = .results
                        }
                    // full clear
                    } else {
                        state = .inactive
                    }
                }
            }
        }

        if queryItems.count == 0 {
            return
        }
        
        self.searchRepo.search(queryItems)
    }
    
    public func clearTextPreserveFilters() {
        searchRepo = SearchResultsRepository()
        text = ""
        self.refresh()
    }
    
    public func clearFilters(for category: SearchFilterModel?) {
        if let filterIndex = searchFilters.value.firstIndex(where: { $0.name == category?.name}), let items = searchFilters.value[filterIndex].items {
            for (index, _) in items.enumerated() {
                searchFilters.value[filterIndex].items?[index].isSelected = false
            }
            self.refresh()
        }
    }
    
    public func clearAll() {
        searchRepo = SearchResultsRepository()
        text = ""
        for (filterIndex, _) in searchFilters.value.enumerated() {
            if let items = searchFilters.value[filterIndex].items {
                for (index, _) in items.enumerated() {
                    searchFilters.value[filterIndex].items?[index].isSelected = false
                }
            }
        }
        self.refresh()
    }
}
