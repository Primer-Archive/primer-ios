//
//  SocialMediaDestination.swift
//  Primer
//
//  Created by Sarah Hurtgen on 12/4/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import UIKit

/**
 A helper enum for use when posting social media to various destinations.
 */
public enum SocialMediaDestination: String {
    case instagramStory = "Instagram"
    case facebookStory = "Facebook"
    
    var schemeURL: String {
        switch self {
        case .instagramStory:
            return "instagram-stories://share"
        case .facebookStory:
            return "facebook-stories://share"
        }
    }
    
    var appStoreURL: String {
        switch self {
        case .instagramStory:
            return "https://itunes.apple.com/in/app/instagram/id389801252?mt=8"
        case .facebookStory:
            return "https://itunes.apple.com/in/app/facebook/id284882215?mt=8"
        }
    }
    
    func videoItems(for data: Data) -> [[String: Any]] {
        switch self {
        case .instagramStory:
            return [
                ["com.instagram.sharedSticker.backgroundVideo" : data],
                ["com.instagram.sharedSticker.contentURL" : "https://www.primer.com"]
            ]
        case .facebookStory:
            return [
                ["com.facebook.sharedSticker.backgroundVideo" : data],
                ["com.facebook.sharedSticker.appID" : "1196401487227500"]
            ]
        }
    }
    
    func imageItems(for image: Data) -> [[String: Any]] {
        switch self {
        case .instagramStory:
            return [
                ["com.instagram.sharedSticker.backgroundImage" : image],
                ["com.instagram.sharedSticker.contentURL" : "https://www.primer.com"]
            ]
        case .facebookStory:
            return [
                ["com.facebook.sharedSticker.backgroundImage" : image],
                ["com.facebook.sharedSticker.appID" : "1196401487227500"]
            ]
        }
    }
}
