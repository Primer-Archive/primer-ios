//
//  CameraToolTipView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 12/4/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import ARKit
import PrimerEngine

struct CameraToolTipView: View {
    
    @Binding var appState: AppState
    @Binding var isVisible: Bool

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(SwiftUI.Color.white,
                        lineWidth: 3.0)
                    .frame(width: 50, height: 50)
            
                Circle()
                    .trim(from: 0.0, to: 0.25)
                    .stroke(
                        BrandColors.blue.color,
                        style: StrokeStyle(
                            lineWidth: 3.0,
                            lineCap: .butt,
                            lineJoin: .round))
                    .rotationEffect(Angle(degrees:-90))
                    .frame(width: 50, height: 50)

                LinearGradient(gradient:
                    Gradient(colors: [
                        Color(red: 240 / 255, green: 128 / 255, blue: 97 / 255),
                        Color(red: 87 / 255, green: 111 / 255, blue: 194 / 255)]),
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                Image(systemName: SFSymbol.cameraFill.rawValue)
                    .font(Font.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(SwiftUI.Color.white)
                    .frame(width: 28, height: 28, alignment: .center)
                    .background(SwiftUI.Color.white.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(lineWidth: 1).foregroundColor(Color.white.opacity(0.4)))
                    .clipShape(Circle())
            }.shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 0)
            
            Spacer()
            
            VStack {
                LabelView(text: "Tap to take a photo", style: .lightModeMedium)
                LabelView(text: "Tap & hold to take a video", style: .lightModeMedium)
            }
            
            Spacer()
            
            SmallSystemIcon(style: .xFillBlue, isButton: true) {
                withAnimation {
                    isVisible = false
                    appState.hasClearedCameraTip = true
                }
            }
        }
        .padding(12) // to match ProductDetailsView
        .background(BrandColors.sand.color)
    }
}

struct CameraToolTipView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            CameraToolTipView(appState: .constant(.initialState), isVisible: .constant(true))
        }
    }
}
