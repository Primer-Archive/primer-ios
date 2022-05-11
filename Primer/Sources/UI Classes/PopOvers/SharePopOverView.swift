//
//  SharePopOverView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 12/3/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Custom share view to overlay users captured video or photo.
 
 `mediaType` sets which string is displayed after "Save" on the label.
 */
struct SharePopOverView: View {
    
    var facebookAction: (SocialMediaDestination) -> Void
    var instagramAction: (SocialMediaDestination) -> Void
    var saveAction: () -> Void
    var shareAction: () -> Void
    var mediaType: String

    // MARK: - Body
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack {
                Spacer()
                    .frame(minHeight: 0, idealHeight: 0, maxHeight: isDeviceIpad() ? 32 : 0)
                
                // top row of buttons
                HStack {
                    VStack {
                        ImageCircleButton(image: Image("FacebookLogo"), color: .solitudeGrey, btnAction: {
                            self.facebookAction(.facebookStory)
                        })
                        LabelView(text: "Facebook", style: .shareModal)
                    }
                    Spacer()
                    VStack {
                        ImageCircleButton(systemIcon: SmallSystemIcon(style: .largeSave), color: .solitudeGrey, btnAction: saveAction)
                        LabelView(text: "Save \(mediaType)", style: .shareModal)
                    }
                    Spacer()
                    VStack {
                        ImageCircleButton(systemIcon: SmallSystemIcon(style: .largeShare), color: .solitudeGrey, btnAction: shareAction)
                        LabelView(text: "Share", style: .shareModal)
                    }
                }.frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 428 : .infinity)
                
                Spacer()
                    .frame(minHeight: 0, maxHeight: isDeviceIpad() ? 32 : 0)
                
                Button("Share to Instagram Story") {
                    self.instagramAction(.instagramStory)
                }
                .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue, font: LabelStyle.buttonMedium.font, height: 52.0))
                .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 428 : .infinity)
                
                // instagram logo overlay on capsule button
                .overlay(
                    ZStack {
                        Circle().foregroundColor(BrandColors.white.color)
                            .frame(width: 35, height: 35, alignment: .center)
                        Circle().foregroundColor(BrandColors.white.color)
                            .frame(width: 32, height: 32, alignment: .center)
                            .overlay(LinearGradient(gradient:
                                Gradient(colors: [
                                    Color(red: 254 / 255, green: 174 / 255, blue: 19 / 255),
                                    Color(red: 221 / 255, green: 80 / 255, blue: 67 / 255),
                                    Color(red: 169 / 255, green: 46 / 255, blue: 139 / 255)]),
                                startPoint: .bottomLeading, endPoint: .topTrailing))
                            .clipShape(Circle())
                        Image("InstagramLogo")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }.padding(.leading, BrandPadding.Small.pixelWidth),
                    alignment: .leading)
                .padding(.vertical, BrandPadding.Medium.pixelWidth)
                
                Spacer()
                    .frame(minHeight: 0, idealHeight: 0, maxHeight: isDeviceIpad() ? 32 : 0)
            }
            
            Spacer()
        }.padding(.vertical, BrandPadding.Medium.pixelWidth)
        .padding(.horizontal, BrandPadding.Large.pixelWidth)
        .background(BrandColors.white.color)
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
}

struct SharePopOverView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            VStack {
                PreviewHelperView(axis: .vertical) {
                    SharePopOverView(facebookAction: {_ in }, instagramAction: {_ in }, saveAction: {}, shareAction: {}, mediaType: "Video")
                }
            }
        }.frame(maxHeight: .infinity)
        .background(BrandColors.sand.color)
    }
}
