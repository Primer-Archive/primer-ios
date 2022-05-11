//
//  EnvironmentalValues.swift
//  Primer
//
//  Created by James Hall on 8/16/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

struct AnalyticsEnvironmentKey: EnvironmentKey {
    static var defaultValue: Analytics? {
        nil
    }
}

struct ImageCacheKey: EnvironmentKey {
    static let defaultValue: ImageCache = TemporaryImageCache()
}

struct WindowKey: EnvironmentKey {
    struct Value {
        weak var value: UIWindow?
    }
    
    static let defaultValue: Value = .init(value: nil)
}


struct NavigationCoordinatorKey: EnvironmentKey {
    static let defaultValue = NavigationCoordinator()
}

struct FilterPickerStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue = FilterPickerStyle.defaultStyle
}

extension EnvironmentValues {
    
    var analytics: Analytics? {
        get { self[AnalyticsEnvironmentKey.self] }
        set { self[AnalyticsEnvironmentKey.self] = newValue }
    }
    
    var imageCache: ImageCache {
        get { self[ImageCacheKey.self] }
        set { self[ImageCacheKey.self] = newValue }
    }
    
    var window: UIWindow? {
        get { return self[WindowKey.self].value }
        set { self[WindowKey.self] = .init(value: newValue) }
    }
    
    var navigationCoordinator: NavigationCoordinator {
        get { self[NavigationCoordinatorKey.self] }
        set { self[NavigationCoordinatorKey.self] = newValue }
    }
    
    var filterPickerStyle: FilterPickerStyle {
        get { self[FilterPickerStyleEnvironmentKey.self] }
        set { self[FilterPickerStyleEnvironmentKey.self] = newValue }
    }

}
