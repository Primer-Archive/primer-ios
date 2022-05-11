//
//  NUXPage.swift
//  Primer
//
//  Created by Sarah Hurtgen on 3/3/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import UIKit

struct NUXData {
    var title: String
    var subtitle: String?
    var buttonTitle: String
    var secondaryButtonTitle: String?
    var videoURL: URL?
}

enum NUXPage: String {
    case authorizeCamera
    case swatchTutorial
    case captureTutorial
    case readyToStart
    
    var data: NUXData {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        switch self {
        case .authorizeCamera:
            let video = AppState.canUseLidar() ?
                (isIpad ? Video.remoteNUXAuthorizeCameraIpadLidar : Video.remoteNUXAuthorizeCameraIphoneLidar) :
                (isIpad ? Video.remoteNUXAuthorizeCameraIpadNonLidar : Video.remoteNUXAuthorizeCameraIphoneNonLidar)
            return NUXData(
                title: "Re-imagine your walls with augmented reality.",
                subtitle: "Authorize your camera to try paint, tile, and wallpaper instantly.",
                buttonTitle: "Authorize Camera",
                videoURL: URL(string: video.rawValue))
        case .swatchTutorial:
            let video = AppState.canUseLidar() ?
                (isIpad ? Video.remoteNUXPlaceSwatchIpadLidar : Video.remoteNUXPlaceSwatchIphoneLidar) :
                (isIpad ? Video.remoteNUXPlaceSwatchIpadNonLidar : Video.remoteNUXPlaceSwatchIphoneNonLidar)
            return NUXData(
                title: "Place a virtual swatch & resize to transform your space.",
                subtitle: "Browse 1000s of products from real brands to find a look you love.",
                buttonTitle: "Got it",
                videoURL: URL(string: video.rawValue))
        case .captureTutorial:
            let video = isIpad ? Video.remoteNUXMediaShareIpad : Video.remoteNUXMediaShareIphone
            return NUXData(
                title: "Record, share & save your favorite looks in a snap.",
                subtitle: "You can always find tutorial videos in the Account tab.",
                buttonTitle: "Got it",
                videoURL: URL(string: video.rawValue))
        case .readyToStart:
            let video = isIpad ? Video.remoteNUXReadyIpad : Video.remoteNUXReadyIphone
            return NUXData(
                title: "Ready to transform your space?",
                buttonTitle: "Try Featured Products",
                secondaryButtonTitle: "Browse All Products",
                videoURL: URL(string: video.rawValue))
        }
    }
}
