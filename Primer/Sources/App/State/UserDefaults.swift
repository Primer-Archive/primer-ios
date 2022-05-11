//
//  UserDefaults.swift
//  PrimerTwo
//
//  Created by James Hall on 3/27/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//
import Foundation
import SwiftUI

extension UserDefaults {

    private struct Keys {
        static let groupAppName = "group.primerapp"
        static let favoriteProductIDs = "favoriteProductIDs"
        static let hasSeenIntro = "hasSeenIntro"
        static let hasSeenLidarHelp = "hasSeenLidarHelp"
        static let hasShownPlacementHelper = "hasShownPlacementHelper"
        static let hasSeenBrowseProductsHelper = "hasSeenBrowseProductsHelper"
        static let lastVersionPromptedForReview = "lastVersionPromptedForReview"
        static let hasSeenWallBlendingHelp = "hasSeenWallBlendingHelp"
        static let siwaKey = "siwaKey"
        static let accessToken = "accessToken"
        static let loggedOutFavorite = "loggedOutFavorite"
        static let lastSurveyViewed = "lastSurveyViewed"
        static let hasCompletedSwatchTutorial = "hasCompletedSwatchTutorial"
    }
    
    static var hasCompletedSwatchTutorial: Bool {
        get {
            return UserDefaults.standard.bool(forKey:Keys.hasCompletedSwatchTutorial)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.hasCompletedSwatchTutorial)
        }
    }

    static var hasSeenWallBlendingHelp: Bool {
        get {
            return UserDefaults.standard.bool(forKey:Keys.hasSeenWallBlendingHelp)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.hasSeenWallBlendingHelp)
        }
    }
    
    static var lastSurveyViewed: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.lastSurveyViewed)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.lastSurveyViewed)
        }
    }
    
    static var favoriteProductIDs: [Int] {
        get {
            var faveArray: [Int] = []
            if let temp = UserDefaults.standard.object(forKey:Keys.favoriteProductIDs) as? [Int] {
                faveArray = temp
            }
            return faveArray
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.favoriteProductIDs)
        }
    }
    
    static var loggedOutFavorite: Int? {
        get {
            var faveId: Int? = nil
            if let temp = UserDefaults.standard.object(forKey: Keys.loggedOutFavorite) as? Int {
                faveId = temp
            }
            return faveId
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.loggedOutFavorite)
        }
    }
    
    static var hasSeenIntro: Bool {
        get {
            return UserDefaults.standard.bool(forKey:Keys.hasSeenIntro)
        }
        set {
            return UserDefaults.standard.set(newValue, forKey:Keys.hasSeenIntro)
        }
    }
    
    static var hasSeenLidarHelp: Bool {
        get {
            return UserDefaults.standard.bool(forKey:Keys.hasSeenLidarHelp)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.hasSeenLidarHelp)
        }
    }
    
    static var hasShownPlacementHelper: Bool {
        get {
            return UserDefaults.standard.bool(forKey:Keys.hasShownPlacementHelper)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.hasShownPlacementHelper)
        }
    }
    
    static var hasSeenBrowseProductsHelper: Bool {
        get {
            return UserDefaults.standard.bool(forKey:Keys.hasSeenBrowseProductsHelper)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.hasSeenBrowseProductsHelper)
        }
    }
    
    static var lastVersionPromptedForReview: String? {
        get {
            return UserDefaults.standard.string(forKey:Keys.lastVersionPromptedForReview)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.lastVersionPromptedForReview)
        }
    }
    
    static var accessToken: String? {
        get {
            return UserDefaults(suiteName: Keys.groupAppName)?.string(forKey:Keys.accessToken)
        }
        set {
            UserDefaults(suiteName: Keys.groupAppName)?.set(newValue, forKey: Keys.accessToken)
        }
    }
    
    static var siwaKey: String? {
        get {
            return UserDefaults(suiteName: Keys.groupAppName)?.string(forKey:Keys.siwaKey)
        }
        set {
            UserDefaults(suiteName: Keys.groupAppName)?.set(newValue, forKey: Keys.siwaKey)
        }
    }
    
}

