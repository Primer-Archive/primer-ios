//
//  Video.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/16/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import Foundation

/**
 A single source for all video assets used within app.
 */
enum Video: String {
    case animPeopleAtWall = "c1" // .mov
    case animPlacingSwatch = "c2" // .mov
    case animSitting = "c3" // .mov
    case animIphoneInstruction = "instructions" // .mp4
    case animLidarInstruction = "instructions-lidar" // .mp4
    case remoteIphoneFavoriting = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/3_favorite_iphone.mp4"
    case remoteIpadFavoriting = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/3_favorite_ipad.mp4"
    case remoteIphoneInstruction = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/1_place_iphone.mp4"
    case remoteIpadInstruction = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/1_place_ipad.mp4"
    case remoteStepWalkToWall = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/walk.mp4"
    case remoteStepTiltPhone = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/perpendicular.mp4"
    case remoteStepPlaceSwatch = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/place.mp4"
    case remoteAdjustSwatch = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/2_adjust_iphone.mp4"
    case remoteShareProduct = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/4_share_iphone.mp4"
    case remoteNUXAuthorizeCameraIpadLidar = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPad/1-iPad.m4v"
    case remoteNUXAuthorizeCameraIpadNonLidar = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPad/1-iPad-nonLIDAR.m4v"
    case remoteNUXAuthorizeCameraIphoneLidar = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPhone/1-iPhone.m4v"
    case remoteNUXAuthorizeCameraIphoneNonLidar = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPhone/1-iPhone-nonLIDAR.m4v"
    case remoteNUXPlaceSwatchIphoneLidar = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPhone/2-iPhone.m4v"
    case remoteNUXPlaceSwatchIphoneNonLidar = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPhone/2-iPhone-nonLIDAR.m4v"
    case remoteNUXPlaceSwatchIpadLidar = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPad/2-iPad.m4v"
    case remoteNUXPlaceSwatchIpadNonLidar = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPad/2-iPad-nonLIDAR.m4v"
    case remoteNUXMediaShareIpad = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPad/3-iPad.m4v"
    case remoteNUXMediaShareIphone = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPhone/3-iPhone.m4v"
    case remoteNUXReadyIpad = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPad/4-iPad.m4v"
    case remoteNUXReadyIphone = "https://d2kkmd5z5nwx0q.cloudfront.net/onboarding_videos/iPhone/4-iPhone.m4v"
}
