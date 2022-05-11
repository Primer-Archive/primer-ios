import SwiftUI
import PrimerEngine

struct BrandHeaderView: View {
    
    var brand: BrandModel
    
    let brandLogoImageSize: CGFloat = 100.0

    var body: some View {
        ZStack {
            
            SwiftUI.Color(hue: 0.64, saturation: 0.45, brightness: 0.15, opacity: 1.00)
            
            RemoteImageView(url: brand.splash) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
            .clipped()
        }
        .overlay(overlayView, alignment: .top)
        
    }
    
    private var overlayView: some View {
        BrandLogo().padding(.top, 100)
    }

    private func BrandLogo() -> some View {
        RemoteImageView(url: brand.logo, width: brandLogoImageSize) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
                .frame(width: self.brandLogoImageSize, height: self.brandLogoImageSize)
        }
    }

}

//struct BrandHeaderView_Previews: PreviewProvider {
//    static var previews: some View {
//        BrandHeaderView(brand: .kateZaremba)
//            .frame(width: 375.0)
//            .previewLayout(.sizeThatFits)
//    }
//}
