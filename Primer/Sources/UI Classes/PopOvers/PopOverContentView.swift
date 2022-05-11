//
//  PopOverContentView.swift
//  PrimerTwo
//
//  Created by James Hall on 6/2/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

struct PopOverInternalContentView: View {
    
    var iconName:String = ""
    var videoName:String?
    var imageName:String?
    var titleText:String = ""
    var descriptionText:String = ""
    var firstButtonText:String = ""
    var firstButtonAction: () -> Void
    var secondButtonText:String?
    var secondButtonAction: (() -> Void)?
    var isVisible:Bool
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        VStack {
            
            if isVisible{
                
                if videoName != nil{
                    VideoPlayerView(fileURL: Bundle.main.url(forResource: videoName, withExtension: "mov")!)
                        .frame(width: 260, height: 200, alignment: .center)
                        .aspectRatio(contentMode: .fit)
                } else
                if imageName != nil {
                    SwiftUI.Image(imageName!)
                        .padding(22)
                }else{
                    SwiftUI.Image(systemName: iconName).font(Font.system(size: 60, weight: .thin, design: .rounded))
                        .foregroundColor(colorScheme == .light ? BrandColors.grey.color : BrandColors.white.color)
                        .padding(22)
                }
                
                Text(titleText)
                    .font(Font.system(size: 16, weight: .semibold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(colorScheme == .light ? BrandColors.grey.color : BrandColors.white.color)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                Text(descriptionText)
                    .font(Font.system(size: 15, weight: .regular, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(colorScheme == .light ? BrandColors.grey.color : BrandColors.white.color)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                
                Button(action: {
                    self.firstButtonAction()
                }) {
                    Text(firstButtonText)
                        .font(Font.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(self.colorScheme == .light ? BrandColors.blue.color : BrandColors.aqua.color)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)
                }
                
                if secondButtonText != nil && secondButtonAction != nil {
                    Button(action: {
                        self.secondButtonAction!()
                    }) {
                        Text(secondButtonText!)
                            .font(Font.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(self.colorScheme == .light ? BrandColors.blue.color : BrandColors.aqua.color)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 24)
                    }
                    .padding(.top,12)
                }
            }
        }
        .clipped()
        .background(BackgroundView())
        .cornerRadius(24)
        .padding(16)
        .shadow(color: SwiftUI.Color.black.opacity(0.4), radius: 16, x: 0, y: 0)
    }
    
}

struct PopOverContentView: View {
    var iconName:String = ""
    var imageName:String?
    var videoName:String?
    var titleText:String = ""
    var descriptionText:String = ""
    var firstButtonText:String = ""
    var firstButtonAction: () -> Void
    var secondButtonText:String?
    var secondButtonAction: (() -> Void)?
    var isVisible:Bool = false
    
    @State var showModal:Bool = false
    
    var body: some View {
        if(showModal != isVisible){
            DispatchQueue.main.async {
                if(self.isVisible){
                    withAnimation(.easeInOut(duration: 0.33)) {
                        self.showModal.toggle()
                    }
                }else{
                    self.showModal.toggle()
                }

            }
        }
        return VStack {
            SwiftUI.Color.black.opacity(showModal ? 0.5 : 0)
                .edgesIgnoringSafeArea(.vertical)
                .allowsHitTesting(false)
                .overlay(
                    PopOverInternalContentView(
                        iconName: iconName,
                        videoName: videoName,
                        imageName: imageName,
                        titleText: titleText,
                        descriptionText: descriptionText,
                        firstButtonText: firstButtonText,
                        firstButtonAction: firstButtonAction,
                        secondButtonText: secondButtonText,
                        secondButtonAction: secondButtonAction,
                        isVisible: true
                    )
                    .offset(y: showModal ? -40 : 100),
                    alignment: .bottom
                ).opacity(showModal ? 1 : 0)
        }
        .frame(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height, alignment: .bottom)
        
    }
}

struct PopOverContentView_Previews: PreviewProvider {
    
    @State var isVisible:Bool = true
    static var previews: some View {
        PopOverContentView(
        imageName: "camera.viewfinder",
        titleText: "Did you get the swatch on your wall?",
        descriptionText: "Primer works best when you place the swatch directly on the wall",
        firstButtonText: "It's on my wall!",
        firstButtonAction: {

        },
        secondButtonText: "Let's try again",
        secondButtonAction: {

        },
        isVisible: true)
        
    }
}
