//
//  NUXView.swift
//  PrimerAppClip
//
//  Created by James Hall on 8/16/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI


struct NUXView: View {
    var appState: Binding<AppState>
    
    var onCameraAuth: () -> Void
    
    var heightModifier: CGFloat{
        return UIScreen.main.bounds.width < 375 ? 0.5 : 1.0
    }
    
    @ObservedObject private var authController = CameraAuthorizationController.shared
    
    var body: some View {
        VStack(alignment: .center){
            
            VideoPlayerView(fileURL: Bundle.main.url(forResource: "c1", withExtension: "mov")!)
                .frame(width: 320, height: 240)
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(BrandPadding.Small.pixelWidth)
            
            
            Text("Let's try on products in your space")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                //                            .padding(BrandPadding.Small.pixelWidth)
                .padding(.top,BrandPadding.Small.pixelWidth)
                .padding(.horizontal,BrandPadding.Small.pixelWidth)
                .lineLimit(2)
                .foregroundColor(BrandColors.grey.color)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Primer allows you to view products in your space. To get started we have to allow camera access")
                .multilineTextAlignment(.center)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .padding(BrandPadding.Small.pixelWidth)
                .lineLimit(nil)
                .foregroundColor(BrandColors.navy.color)
            
            Button(action: {
                authController.requestAccess(completion: { success in
                    if success {
                        self.onCameraAuth()
                    }else{
                        print("fail")
                    }
                    
                })
            }) {
                Text("Allow camera and start")
            }
            .buttonStyle(PrimaryCapsuleButtonStyle())
            .padding()
        }
        .background(BrandColors.white.color)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 12)
        .padding(.horizontal, 16)
        .frame(maxWidth:340, maxHeight: 440)
        //                    .frame(width: 340, height: 440, alignment: .center)
    }
}
