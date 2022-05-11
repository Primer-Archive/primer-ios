//
//  SavedBrandManager.swift
//  Primer
//
//  Created by Sarah Hurtgen on 2/11/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

/**
 Handles storing and updating tapped brands and collections. Is set when user taps through brandviews and their featured collections.
 */
public class SavedBrandManager: ObservableObject {
    @Published public var brand: BrandModel? {
        didSet {
            if oldValue?.id != brand?.id, let setBrand = brand {
                savedCollection = nil
                tappedIndex = nil
                savedCollectionRepo = nil
                self.collectionsRepo.setBrandId(brandID: setBrand.id)
            } else if brand == nil {
                savedCollection = nil
                tappedIndex = nil
                savedCollectionRepo = nil
                collectionsRepo = ProductCollectionsRepository()
            }
        }
    }
    @Published public var collectionsRepo: ProductCollectionsRepository
    @Published public var savedCollectionRepo: ProductCollectionRepository?
    @Published public var savedCollection: ProductCollectionModel?
    @Published public var tappedIndex: Int? = nil {
        didSet {
            if collectionsRepo.value.count > tappedIndex ?? 0, let tapped = tappedIndex {
                let collection = collectionsRepo.value[tapped]
                self.savedCollection = collection
                self.savedCollectionRepo = ProductCollectionRepository()
                self.savedCollectionRepo?.setCollectionId(collectionId: collection.id)
            }
        }
    }
    
    public init(brand: BrandModel?) {
        self.collectionsRepo = ProductCollectionsRepository()
        self.brand = brand
        if let brand = brand {
            self.collectionsRepo.setBrandId(brandID: brand.id)
        }
    }

    public func refreshBrandId() {
        if let brand = brand {
            collectionsRepo.setBrandId(brandID: brand.id)
        }
    }

    public func refreshCollection() {
        if let collection = savedCollection {
            savedCollectionRepo?.setCollectionId(collectionId: collection.id)
        }
    }

    public func appendCollections() {
        collectionsRepo.append()
    }
}
