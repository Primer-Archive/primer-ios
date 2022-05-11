//
//  BrandPageHeaderView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/12/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

struct BrandPageHeaderView: View {

    var brand: BrandModel
    var containerWidth: CGFloat
    private var preferredHeight: CGFloat {
        return isDeviceIpad() ? 200 : 100
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                RemoteImageView(url: brand.splash, width: containerWidth) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .frame(maxWidth: containerWidth, minHeight: preferredHeight, idealHeight: preferredHeight)
                .overlay(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
                .clipped()
                    
                VStack(spacing: 30) {
                    PreviewCircle(type: .brand(url: brand.logo), size: CGSize(width: 80, height: 80))

                    LabelView(text: brand.bio, style: .smallLight)
                }
                .padding(.top, 50)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: containerWidth)
        }
    }
}

