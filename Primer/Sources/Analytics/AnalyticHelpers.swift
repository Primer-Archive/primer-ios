//
//  AnalyticHelpers.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/12/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import Foundation


/** Enum helper for tracking account management */
public enum AccountType: String {
    case email = "Email"
    case siwa = "Apple"
}

/** Enum helper for tracking where a user taps to favorite/unfavorite, where permissions are granted, sign ups completed, etc */
public enum ViewLocation: String {
    case searchResult = "Search Result View"
    case gridView = "Grid View"
    case featuredView = "Featured View"
    case miniDetailView = "Mini Detail View"
    case brandView = "Brand View"
    case expandedDetailView = "Expanded Detail View"
    case searchResultPopup = "Search Result Popup"
    case productsDrawer = "Products Drawer Popup"
    case favoritesDrawer = "Favorites Drawer"
    case brandViewPopup = "Brand View Popup"
    case aboutTab = "About Tab"
    case nux = "NUX"
    case appClipNux = "App Clip NUX"
    case photoPermissionTooltip = "Photo Permission Tooltip"
    case arViewPermissionTooltip = "AR Camera Permission Tooltip"
}

/** Enum helper for tracking which type of media a user captures */
public enum CapturedPreviewType: String {
    case appStill = "app still"
    case appVideo = "app video"
    case nativeStill = "native still"
    case nativeVideo = "native video"
}

/** Enum helper for tracking which Photos permission a user selects */
public enum PhotoPermissionType: String {
    case notDetermined = "Not Determined"
    case restricted = "Restricted"
    case denied = "Denied"
    case authorized = "Authorized"
    case limited = "Limited"
    case unknown = "Unknown"
}

/** Enum helper for tracking which Camera permission a user selects*/
public enum CameraPermissionType: String {
    case notDetermined = "Not Determined"
    case restricted = "Restricted"
    case denied = "Denied"
    case authorized = "Authorized"
    case unknown = "Unknown"
}

/** Enum helper for tracking which Photos permission a user selects */
public enum CompletedSwatchStepType: String {
    case auto = "Auto"
    case manual = "Manual"
}
