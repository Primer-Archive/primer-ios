//
//  About.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/28/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import Foundation

// MARK: - Section
/**
 This is enum is used for the About Page, and is iterated over to populate the displayed cells. The order of the `AboutSection` cases, as well as their `items` array, should mirror the desired order for them to appear in app. When the user is logged out, the `account` section will automatically be ommitted.
 */
enum AboutSection: String, CaseIterable {
    case account = "My Account"
    case brandResources = "Brand Resources"
    case howToUsePrimer = "How to use Primer"
    case appSupport = "App Support"
    case followOnSocial = "Follow"
    
    var items: [AboutItem] {
        switch self {
        case .account:
            return [.signOut]
        case .brandResources:
            return [.contactUsBrand, .brandServices, .faq]
        case .howToUsePrimer:
            return [.howToPlaceSwatch, .howToAdjustSwatch, .howToSaveFav, .howToShare]
        case .appSupport:
            return [.appFeedback, .privacyPolicy]
        case .followOnSocial:
            return [.instagram, .twitter, .blog, .primerHome]
        }
    }
}

// MARK: - Item

public enum AboutItem: String, Equatable {
    // Account
    case signOut = "Sign Out"
    
    // Brand resources
    case contactUsBrand = "Get In Touch"
    case brandServices = "Brand Services"
    case faq = "FAQ"
    
    // How to's
    case howToPlaceSwatch = "Place a swatch"
    case howToAdjustSwatch = "Adjust swatch"
    case howToSaveFav = "Save favorites"
    case howToShare = "Share previews"
    
    // App Support
    case appFeedback = "Contact Us"
    case privacyPolicy = "Privacy Policy"
    
    // Follow
    case instagram = "Instagram"
    case twitter = "Twitter"
    case blog = "Blog"
    case primerHome = "Primer.com"
    
    
    var url: URL? {
        switch self {
        case .contactUsBrand:
            return URL(string: "https://primersupply.typeform.com/to/jSyiGK")
        case .brandServices:
            return URL(string: "https://www.primer.com/brand-services/")
        case .faq:
            return URL(string: "https://www.primer.com/faq/")
        case .howToPlaceSwatch:
            return URL(string: "https://youtu.be/ErdC8kOUQN0")
        case .howToAdjustSwatch:
            return URL(string: "https://youtu.be/Tt7NEoizNn0")
        case .howToSaveFav:
            return URL(string: "https://youtu.be/4lH2s85RdRk")
        case .howToShare:
            return URL(string: "https://youtu.be/Zd24IWPTSaQ")
        case .privacyPolicy:
            return URL(string: "https://www.primer.com/privacy-policy/")
        case .instagram:
            return URL(string: "https://www.instagram.com/primersupply/")
        case .twitter:
            return URL(string: "https://www.twitter.com/primersupply")
        case .blog:
            return URL(string: "https://blog.primer.com")
        case .primerHome:
            return URL(string: "https://www.primer.com")
        default:
            return nil
        }
    }
    
    // Setting this up to keep metrics in sync even if labels (set using the rawValue) change with UI updates
    var analyticsString: String {
        switch self {
        case .signOut: return "Sign Out"
        case .contactUsBrand: return "Contact Us - Brand"
        case .brandServices: return "Brand Services"
        case .faq: return "FAQ"
        case .howToPlaceSwatch: return "Place Swatch Tutorial"
        case .howToAdjustSwatch: return "Adjust Swatch Tutorial"
        case .howToSaveFav: return "Save Favorite Tutorial"
        case .howToShare: return "Share Tutorial"
        case .appFeedback: return "Contact Us - User"
        case .privacyPolicy: return "Privacy Policy"
        case .instagram: return "Instagram"
        case .twitter: return "Twitter"
        case .blog: return "Blog"
        case .primerHome: return "Primer Website"
        }
    }
}
