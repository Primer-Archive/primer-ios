//
//  NUXScreenView.swift
//  PrimerTwo
//
//  Created by Adam Debreczeni on 2/5/20.
//  Copyright © 2020 Timothy Donnelly. All rights reserved.
//

import SwiftUI
import PrimerEngine

struct NUXScreenContentView: NUXScreenView {
    @Environment(\.analytics) var analytics

    var page: NUXPage
    var onContinue: (AppState.VisibleSheet?) -> Void

    public init(page: NUXPage, onContinue: @escaping (AppState.VisibleSheet?) -> Void) {
        self.page = page
        self.onContinue = onContinue
    }
    
    var body: some View {
        if isDeviceIpad() {
            VStack {
                iPadVideo
                footerStack
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BrandColors.backgroundView.color)
        } else {
            standardVideo
                .padding(.bottom, isDeviceCompact() ? BrandPadding.Small.pixelWidth : BrandPadding.Medium.pixelWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    footerStack
                        .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.size.height * 0.42)
                        .background(BrandColors.backgroundView.color)
                        .cornerRadius(20),
                    alignment: .bottom)
        }
    }

    var iPadVideo: some View {
        VStack(spacing: 20) {
            Spacer()
            if isDeviceIpad() {
                VideoPlayerView(
                    fileURL: page.data.videoURL,
                    frameSize: CGSize(width: 390, height: 500)
                )
                .background(BrandColors.navy.color)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: BrandPadding.Medium.pixelWidth).stroke(lineWidth: 4).foregroundColor(BrandColors.white.color))
                .padding(.horizontal, BrandPadding.Large.pixelWidth)
            }
        }
    }
    
    var standardVideo: some View {
        VStack(spacing: 0) {
            if !isDeviceIpad() {
                VideoPlayerView(
                    fileURL: page.data.videoURL,
                    frameSize: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height * 0.6)
                )
                .background(BrandColors.navy.color)
                .edgesIgnoringSafeArea(.top)
            
                Spacer()
            }
        }
    }
    
    var footerStack: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(maxHeight: isDeviceIpad() ? 30 : 55)
            
            VStack(spacing: BrandPadding.Large.pixelWidth) {
                LabelView(text: page.data.title, style: .nuxTitle)
                    .frame(minHeight: 60)
                if let subtitle = page.data.subtitle {
                    LabelView(text: subtitle, style: .nuxDescription)
                        .frame(minHeight: 45)
                }
            }.padding(.horizontal, BrandPadding.Smedium.pixelWidth)
            .frame(maxWidth: 380)
            

            VStack(spacing: BrandPadding.Smedium.pixelWidth) {
                Button(page.data.buttonTitle) {
                    self.analytics?.didEndNuxView(viewName: "\(page.data.buttonTitle) - \(self.page.data.title)")
                    self.onContinue(nil)
                }
                .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue, font: LabelStyle.buttonSemibold.font, height: 55.0, cornerRadius: 30))
                .padding(.top, BrandPadding.Large.pixelWidth)
                if let secondButtonTitle = page.data.secondaryButtonTitle {
                    Button(secondButtonTitle) {
                        self.analytics?.didEndNuxView(viewName: "\(secondButtonTitle) - \(self.page.data.title)")
                        self.onContinue(.inspiration)
                    }
                    .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .grey, font: LabelStyle.buttonSemibold.font, height: 55.0, cornerRadius: 30))
                }
            }.padding(.horizontal, 45)
            .padding(.bottom, BrandPadding.Large.pixelWidth)
            .frame(maxWidth: 380)
            
            Spacer()
        }
    }
}

struct NUXScreenContentView_Previews: PreviewProvider {
    static var previews: some View {
        NUXScreenContentView(page: .authorizeCamera, onContinue: {_ in})
    }
}
