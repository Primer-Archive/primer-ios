import SwiftUI
import SceneKit
import PrimerEngine

struct ProductOrbView: View {
    
    var product: ProductModel
    var priority: Float
    
    @ObservedObject private var materialCache = MaterialCache.shared

    private var preview: AnyView {
        if(product.id > 0){
            
            if product.productType == .productWithVariations {
                print("product name: \(product.name), id:\(product.id)")
                return AnyView(
                    ZStack {
                        if self.product.variations?.count ?? -1 > 0, let variation = self.product.variations?[0] {
                            ProductOrbView(product: variation, priority: 1)
                        } else {
                            ProductOrbView(product: self.product, priority: 1)
                        }
                    }
                )
            }
            switch product.material.diffuse.content {
            case .color(let color):
                return AnyView(color.swiftUIColor)
            case .constant(let constant):
                return AnyView(SwiftUI.Color(white: constant))
            case .inactive:
                return AnyView(SwiftUI.Color.gray)
            case .texture(let url):
                switch materialCache.state(for: product.material, priority: priority) {
                case .loading:
                    return AnyView(Color.gray)
                case .loaded:
                    //                guard let localURL = loadedMaterial.cacheMap[url] else {
                    //                    return AnyView(Color.gray)
                    //                }
                    //remove the cache for the orb. We're going to get a smaller
                    //size of the texture here, so let's not cache this as THE texture.
                    let view = RemoteImageView(url: url, width: 200) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    }
                    return AnyView(view)
                    
                }
            }
        }else{
            return AnyView(
                VStack {
                    SwiftUI.Image(systemName: "rectangle.on.rectangle.angled").font(Font.system(size: 24, weight: .regular, design: .rounded))
                        .foregroundColor(BrandColors.blue.color).frame(width: 200, height: 200, alignment: .center)
                }.background(Color.white)
            )
        }
    }
    
    var body: some View {
        return preview.overlay(overlay)
            
    }
    
    var isLoaded: Bool {
        switch materialCache.state(for: product.material, priority:priority) {
        case .loading:
            return false
        case .loaded:
            return true
        }
    }
    
    var overlay: some View {
        ZStack {
            if !isLoaded {
                ActivityIndicatorView()
            }
        }
    }
    
}
