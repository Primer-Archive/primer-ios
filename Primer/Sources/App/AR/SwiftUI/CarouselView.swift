//
//  CarouselView.swift
//  Primer
//
//  Created by James Hall on 8/3/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

struct CarouselView: View {

    var product: ProductModel
    var isExpanded: Bool
    
    @State var page = 0
    
    let axes: Axis.Set = [.horizontal]
    
    public init(product:ProductModel, isExpanded: Bool){
        self.product = product
        self.isExpanded = isExpanded
        
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.white
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.2)
    }
    
    var body: some View {
        GeometryReader { g in
            CarouselImageView(imageURLs: self.product.featuredImages, width: g.frame(in: .global).width, height: g.frame(in: .global).height)
        }
    }
}

struct CarouselImageView: View {
    
    var imageURLs: [URL?]
    var width: CGFloat
    var height: CGFloat
    
    var body: some View {
        ScrollView {
            TabView {
                ForEach(imageURLs.indices, id: \.self) { urlIndex in
                    ZStack {
                        BrandColors.navy.color
                            
                        if let url = imageURLs[urlIndex] {
                            RemoteImageView(url: url, width: 520) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                                    .id(url.absoluteString)
                            }
                        }
                    }
                }.frame(width: width, height: height)
            }
            .frame(width: width, height: height)
            .tabViewStyle(PageTabViewStyle())
        }
    }
}

struct CarouselImageView_Previews: PreviewProvider {
    
    static var urls: [URL?] = {
        return [URL(string: "https://primer-supply-staging.imgix.net/products/24/4705c72d3f3c25fccb1d86f8f3b5fb3a.jpg"),
                URL(string: "https://primer-supply-staging.imgix.net/products/24/de19f5d3bf7993e5d77712924f221525.jpg"),
                URL(string: "https://primer-supply-staging.imgix.net/products/27/a31977205e714f9c250d0b0907132964.jpg"),
                URL(string: "https://primer-supply-staging.imgix.net/products/27/cfd398e13c98d5b0337adf5de7a07922.jpg")]
    }()
    
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            CarouselImageView(imageURLs: urls, width: UIScreen.main.bounds.width, height: 400)
        }
        .background(BrandColors.sand.color)
    }
}
