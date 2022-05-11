//
//  ProductCardScrollId.swift
//  Primer
//
//  Created by Sarah Hurtgen on 2/11/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import Foundation

/**
 A helper enum for setting view id's to scroll to product cards on re-open, based on where they appear in app
 */
enum ProductCardScrollId: String {
    case brandFeaturedCollection = "BrandFeaturedCollectionCardId"
    case brandSearchResult = "BrandSearchResultCardId"
    case searchResult = "ProductSearchCardId"
    case inspirationFeed = "InspirationFeedCardId"
    case favorites = "FavoriteGridCardId"
    case unspecified = "ProductGridCardId"
}
