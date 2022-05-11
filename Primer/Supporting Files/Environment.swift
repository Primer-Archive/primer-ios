//
//  Environment.swift
//  PrimerTwo
//
//  Created by James Hall on 3/17/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import Foundation

public enum ENV {
    // MARK: - Keys
    enum Keys {
        enum Plist {
            static let appURL = "APP_BASE_URL_ENDPOINT"
            static let apiURL = "API_BASE_URL_ENDPOINT"
            static let mixpanelToken = "MIXPANEL_TOKEN"
            static let sentryDSN = "SENTRY_DSN"
        }
    }
    
    // MARK: - Plist
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()
    
    // MARK: - Plist values
    static let apiURL: String = {
        guard let apiURL = ENV.infoDictionary[Keys.Plist.apiURL] as? String else {
            fatalError("API URL not set in plist for this environment")
        }
        return apiURL
    }()
    
    static let appURL: String = {
        guard let apiURL = ENV.infoDictionary[Keys.Plist.appURL] as? String else {
            fatalError("APP URL not set in plist for this environment")
        }
        return apiURL
    }()
    
    static let mixpanelToken: String = {
        guard let mixpanelToken = ENV.infoDictionary[Keys.Plist.mixpanelToken] as? String else {
            fatalError("Mixpanel token not set in plist for this environment")
        }
        return mixpanelToken
    }()

    static let sentryDSN: String = {
        guard let sentryDSN = ENV.infoDictionary[Keys.Plist.sentryDSN] as? String else {
            fatalError("Sentry DSN not set in plist for this environment")
        }
        return "https://" + sentryDSN
    }()
}
