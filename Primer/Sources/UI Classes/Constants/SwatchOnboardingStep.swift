//
//  SwatchOnboardingStep.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/25/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import Foundation

// MARK: - Protocol

protocol SwatchOnboardingStep {
    var instructionText: String { get }
    var videoURL: URL? { get }
    var location: Int { get }
    var isLast: Bool { get }
    var primaryButtonText: String { get }
    var secondaryButtonText: String { get }
}

// MARK: - Tips
/**
 A helper enum to group together the "tips" around how to alter a placed swatch to be displayed in user onboarding tutorials
 */
public enum AdjustSwatchStep: SwatchOnboardingStep, Equatable, CaseIterable {
    case resize
    case share
    case favorite
    
    var instructionText: String {
        switch self {
        case .resize:
            return "Pinch to resize swatch"
        case .share:
            return "Tap and hold to share"
        case .favorite:
            return "Tap heart to save products"
        }
    }
    
    var videoURL: URL? {
        switch self {
        case .resize:
            return URL(string: Video.remoteAdjustSwatch.rawValue)
        case .share:
            return URL(string: Video.remoteShareProduct.rawValue)
        case .favorite:
            return URL(string: Video.remoteIphoneFavoriting.rawValue)
        }
    }
    
    var location: Int {
        switch self {
        case .resize:
            return 0
        case .share:
            return 1
        case .favorite:
            return 2
        }
    }
    
    var isLast: Bool {
        switch self {
        case .favorite:
            return true
        default: return false
        }
    }
    
    var primaryButtonText: String {
        return "Place Swatch"
    }
    
    var secondaryButtonText: String {
        return "Show me how to place swatch"
    }
}

// MARK: - Steps
/**
 A helper enum to group together the associated details of each step on "how to place a swatch" to be displayed in onboarding tutorials
 */
public enum PlaceSwatchStep: SwatchOnboardingStep, Equatable, CaseIterable {
    case walkToWall
    case tiltPhone
    case tapToPlace
    
    var instructionText: String {
        switch self {
        case .walkToWall:
            return "Walk towards your wall"
        case .tiltPhone:
            return "Hold top of device to wall"
        case .tapToPlace:
            return "Tap the button below"
        }
    }
    
    var videoURL: URL? {
        switch self {
        case .walkToWall:
            return URL(string: Video.remoteStepWalkToWall.rawValue)
        case .tiltPhone:
            return URL(string: Video.remoteStepTiltPhone.rawValue)
        case .tapToPlace:
            return URL(string: Video.remoteStepPlaceSwatch.rawValue)
        }
    }
        
    var smallIcon: SystemIconStyle {
        switch self {
        case .walkToWall:
            return .walkingMan
        case .tiltPhone:
            return .phoneArrow
        case .tapToPlace:
            return .handTap
        }
    }
    
    var largeIcon: SystemIconStyle {
        switch self {
        case .walkToWall:
            return .walkingManLarge
        case .tiltPhone:
            return .phoneArrowLarge
        case .tapToPlace:
            return .handTapLarge
        }
    }
    
    var location: Int {
        switch self {
        case .walkToWall:
            return 0
        case .tiltPhone:
            return 1
        case .tapToPlace:
            return 2
        }
    }
    
    var isLast: Bool {
        switch self {
        case .tapToPlace:
            return true
        default:
            return false
        }
    }
    
    var primaryButtonText: String {
        if self.isLast {
            return "Place Swatch"
        } else {
            return "Show next step"
        }
    }
    
    var secondaryButtonText: String {
        if self.isLast {
            return "Go back to first step"
        } else {
            return "Skip tutorial, I'm an expert"
        }
    }
}
