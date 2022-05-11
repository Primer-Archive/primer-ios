//
//  MainViewHelpers.swift
//  PrimerTwo
//
//  Created by James Hall on 6/3/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI


struct MainViewOverlays:View{
    
    @Binding var appState: AppState

    var body: some View {
        
        var videoName:String?
        var iconName:String = "heart"
        var imageName:String?
        var titleText:String = ""
        var descriptionText:String = ""
        var firstButtonText:String = ""
        var firstButtonAction: () -> Void = {}
        var secondButtonText:String?
        var secondButtonAction: (() -> Void)?

        if(appState.helpModalType == .cameraAccessDenied){
            iconName = "camera.viewfinder"
            titleText =  "Camera Access Denied"
            descriptionText = "Enable camera access so you can design your space in AR"
            firstButtonText = "Enable Camera Access"
            firstButtonAction = {
                analyticInstance.didTapGoToCameraSettings(from: .arViewPermissionTooltip)
                if let url = NSURL(string: UIApplication.openSettingsURLString) as URL? {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            
            
        }else if(appState.helpModalType == .noNetworkDetected){
            iconName = "wifi.exclamationmark"
            titleText = "No Internet Detected"
            descriptionText = "Oh no! Looks like you don't have internet access"
            firstButtonText = "Check network settings"
            firstButtonAction = {
                if let url = NSURL(string: UIApplication.openSettingsURLString) as URL? {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            
        }else if(appState.helpModalType == .swatchPlacementConfirmation){
            videoName = "c2"
            titleText = "Did you get the swatch on your wall?"
            descriptionText = "Primer works best when you place the swatch directly on a wall"
            firstButtonText = "It's on my wall"
            firstButtonAction = {
                UserDefaults.hasShownPlacementHelper = true
                self.appState.showSuccessSwatchPlacement = false
                analyticInstance.successfullyPlacedSwatch(product: self.appState.selectedProduct)
            }
            secondButtonText = "Let's try again"
            secondButtonAction = {
                self.appState.engineState.resetTime = Date().timeIntervalSinceReferenceDate
                self.appState.showSuccessSwatchPlacement = false
                analyticInstance.retriedSwatchPlacement(product: self.appState.selectedProduct)
            }
        }else if (appState.helpModalType == .browseMoreProductsCTA){
            iconName = "magnifyingglass"
            titleText = "See all the goods on Primer"
            descriptionText = "Primer has a lot more to offer! View all of our paints, wallpaper and tile by tapping the Browse more button above."
            firstButtonText = "Browse products now"
            firstButtonAction = {
                analyticInstance.didOpenProductsSheetFromPrompt(product: self.appState.selectedProduct)
                UserDefaults.hasSeenBrowseProductsHelper = true
                self.appState.visibleSheet = .browser
            }
            secondButtonText = "Ok"
            secondButtonAction = {
                analyticInstance.acknowledgedBrowseProductPrompt(product: self.appState.selectedProduct)
                UserDefaults.hasSeenBrowseProductsHelper = true
                self.appState.shownProductsCount = 0
            }

        } else if (appState.helpModalType == .wallBlendingHelp){
            imageName = "wallBlendingHelp"
            titleText = "Blending Enabled"
            descriptionText = "Nice find! That magic button enables our virtual swatches to blend into your wall with lighting and shadows."
            firstButtonText = "Got it"
            firstButtonAction = {
                UserDefaults.hasSeenWallBlendingHelp = true
                appState.showWallBlendingPlacement = false
            }
        }
        return PopOverContentView(
            iconName: iconName,
            imageName: imageName,
            videoName: videoName,
            titleText: titleText,
            descriptionText: descriptionText,
            firstButtonText: firstButtonText,
            firstButtonAction: firstButtonAction,
            secondButtonText: secondButtonText,
            secondButtonAction: secondButtonAction,
            isVisible:appState.showModal)
        
    }
}

