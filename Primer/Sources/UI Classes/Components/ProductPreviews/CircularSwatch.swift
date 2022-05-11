//
//  CircularSwatch.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/26/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

// MARK: - Orb Type

enum OrbType {
    case swatch(product: ProductModel)
    case color(_ color: SwiftUI.Color, text: String? = nil)
    case brand(url: URL?)
}

// MARK: - Circular Swatch
// TODO: - Rename, "swatch" feels misleading
struct PreviewCircle: View {
    
    @ObservedObject private var materialCache = MaterialCache.shared
    @State var isSelected: Bool = false
    var type: OrbType
    var size: CGSize = CGSize(width: 65, height: 65)
    var hasShadow: Bool = false
    var gradient: [SwiftUI.Color] {
        return [Color.white.opacity(0.2), Color.white.opacity(0.1), Color.clear]
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            switch type {
            
            // MARK: - Swatch
            
            case .swatch(let product):
                ZStack {
                    Circle()
                        .strokeBorder(BrandColors.white.color, lineWidth: 5)
                    switch product.material.diffuse.content {
                    case .color(let materialColor):
                        Circle()
                            .foregroundColor(materialColor.swiftUIColor)
                    case .constant(let constant):
                        Circle()
                            .foregroundColor(SwiftUI.Color(white: constant))
                    case .inactive:
                        Circle()
                            .foregroundColor(SwiftUI.Color.gray)
                    case .texture(let url):
                        switch materialCache.state(for: product.material, priority: 0) {
                        case .loading:
                            Circle()
                                .foregroundColor(SwiftUI.Color.gray)
                        case .loaded:
                            RemoteImageView(url: url, width: 200) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                                    .overlay(LinearGradient(gradient: Gradient(colors: gradient), startPoint: .top, endPoint: .bottom))
                            }
                        }
                    }
                }
                
            // MARK: - Color
            
            case .color(let color, let text):
                Circle()
                    .strokeBorder(isSelected ? BrandColors.blue.color : BrandColors.white.color, lineWidth: 3)
                    .background(color)
                    .onTapGesture {
                        isSelected.toggle()
                    }
                LabelView(text: text ?? "", style: .smallCategoryLight)
                
            // MARK: - Brand
            
            case .brand(let url):
                RemoteImageView(url: url, width: size.width) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .background(Color.white)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.25), radius: hasShadow ? 5 : 0, x: 0.0, y: 0.0)
    }
}

// MARK: - Preview

struct CircularSwatch_Previews: PreviewProvider {
    
    static var previews: some View {
        
        PreviewHelperView(axis: .vertical, content: {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(BrandColors.allCases, id: \.self) { item in
                        PreviewCircle(type: .color(item.color, text: (item.rawValue.count < 8 ? item.rawValue : nil)))
                    }
                }
            }.padding(32)
        })
    }
}
