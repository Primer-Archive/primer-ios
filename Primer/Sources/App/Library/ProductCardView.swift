
import SwiftUI
import PrimerEngine

/**
 Displays rectangle product cards with centered product description and brand text underneath.
 */
struct ProductCardView: View {
    
    var product: ProductModel
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center, spacing: 2.0) {
            ProductSwatchView(product: product, customURL: product.featuredImages.first)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: SwiftUI.Color.black.opacity(0.2), radius: 6.0, x: 0.0, y: 2.0)
        
//            LabelView(text: product.name, style: .featuredCardTitle)
//            .padding(.top, 4)
//
//            LabelView(text: product.brandName, style: .featuredCardSubtitle)
        }
    }
}

//struct ProductView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProductView(product: ProductCollection.tileSample.products[0])
//    }
//}
