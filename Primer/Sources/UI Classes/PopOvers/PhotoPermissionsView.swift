//
//  PhotoPermissionsView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 12/15/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 A "buffer" modal to be used when a user tries to capture media, before presenting the system prompt for Photo permissions - or if a user has previously denied permissions.
 */

struct PhotoPermissionsView: View {
    
    var permissionState: PhotoPermissionsState
    var closeBtnAction: () -> Void
    var ctaBtnAction: () -> Void
    
    // MARK:  - Body
    
    var body: some View {
        VStack(spacing: 0) {
            
            // header section
            ZStack {
                Image(permissionState.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                
                if permissionState == .initial {
                    Rectangle()
                        .foregroundColor(BrandColors.black.color.opacity(0.6))

                    VStack(spacing: BrandPadding.Medium.pixelWidth) {
                        cameraIcon
                        
                        LabelView(text: "Tap the button to capture a photo,\ntap and hold to capture a video.", style: .transparentButton)
                    }
                }
                
                VStack {
                    HStack {
                        SmallSystemIcon(style: .x12, isButton: true) {
                            closeBtnAction()
                        }
                        Spacer()
                    }.padding(BrandPadding.Smedium.pixelWidth)
                    
                    Spacer()
                }.frame(maxWidth: isDeviceIpad() ? 420 : .infinity)
            }
            .frame(maxWidth: isDeviceIpad() ? 420 : .infinity, maxHeight: isDeviceIpad() ? 252 : 176)
            .background(BrandColors.darkBlueToggleBlack.color)
            
            // CTA section
            VStack {
                LabelView(text: "In order to save your captures,\nPrimer needs access to Photos.", style: .bodyMedium)
                
                Button(permissionState.btnLabel) {
                    ctaBtnAction()
                }
                .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue, font: LabelStyle.buttonSemibold.font, height: 52.0, cornerRadius: 12))
                .padding(BrandPadding.Smedium.pixelWidth)
            }
            .frame(height: 176)
            .background(BrandColors.backgroundView.color)
        }.frame(maxWidth: isDeviceIpad() ? .infinity : 344)
        .cornerRadius(BrandPadding.Medium.pixelWidth)
        .padding(.vertical, BrandPadding.Smedium.pixelWidth)
    }
    
    // MARK: - Camera Icon
    
    var cameraIcon: some View {
        ZStack {
            Circle()
                .stroke(SwiftUI.Color.white,
                    lineWidth: 4.0)
                .frame(width: 68, height: 68)
        
            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(
                    BrandColors.blue.color,
                    style: StrokeStyle(
                        lineWidth: 4.0,
                        lineCap: .butt,
                        lineJoin: .round))
                .rotationEffect(Angle(degrees:-90))
                .frame(width: 68, height: 68)

            
            Image("PermissionsOrb")
                .frame(width: 54, height: 54)
                .clipShape(Circle())
            
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .frame(width: 38, height: 38, alignment: .center)
                .clipShape(Circle())
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(lineWidth: 1).foregroundColor(Color.white.opacity(0.4)))
            
            Circle()
                .stroke(SwiftUI.Color.white.opacity(0.4),
                    lineWidth: 2)
                .frame(width: 54, height: 54)
            
            Image(systemName: SFSymbol.cameraFill.rawValue)
                .font(Font.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(SwiftUI.Color.white)
                .frame(width: 38, height: 38, alignment: .center)
                .clipShape(Circle())
        }.shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 0)
        
    }
}

// MARK: - Preview

struct PhotoPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            PhotoPermissionsView(permissionState: .initial, closeBtnAction: {}, ctaBtnAction: {})
                .cornerRadius(30)
                .background(Color.white)
        }
    }
}
