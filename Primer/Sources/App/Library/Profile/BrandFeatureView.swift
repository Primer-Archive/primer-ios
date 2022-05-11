import SwiftUI
import PrimerEngine

struct BrandFeatureView: View {

    let brand: BrandModel

    @State private var showingInstagram = false

    private var threeUp: (URL?, URL?, URL?) {
        (brand.featuredImageOne, brand.featuredImageTwo, brand.featuredImageThree)
    }
    
    let featuredImageSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? UIScreen.main.bounds.width / 4 : UIScreen.main.bounds.width / 2.3
    
    // Adam: please fix this, you dummy.

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    RemoteImageView(url: brand.featuredImageOne, width: featuredImageSize) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(width: featuredImageSize, height: UIDevice.current.userInterfaceIdiom == .pad ? 440 : 240, alignment: .center)
                .background(Color.gray)
                .cornerRadius(16)
                .clipped()

                VStack(alignment: .center, spacing: 20) {
                    ZStack {
                        RemoteImageView(url: brand.featuredImageTwo, width: featuredImageSize) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: featuredImageSize, height: UIDevice.current.userInterfaceIdiom == .pad ? 210 : 110, alignment: .center)
                    .background(Color.gray)
                    .cornerRadius(16)
                    .clipped()
                    
                    ZStack {
                        RemoteImageView(url: brand.featuredImageThree, width: featuredImageSize) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: featuredImageSize, height: UIDevice.current.userInterfaceIdiom == .pad ? 210 : 110, alignment: .center)
                    .background(Color.gray)
                    .cornerRadius(16)
                    .clipped()
                }
            }.padding(20)
            
            Text(brand.featuredText)
                .multilineTextAlignment(.center)
                .foregroundColor(BrandColors.greyToggleWhite.color)
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14, weight: .regular, design: .rounded))
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 20)
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: 60, maxHeight: 100, alignment: .center)
                .padding(.bottom, 20)
        }
        .background(BrandColors.pinkToggleNavy.color)

    }

    private func dismissWebview() {
        self.showingInstagram = false
    }
    
}

//struct BrandFeatureView_Previews: PreviewProvider {
//    static var previews: some View {
//        BrandFeatureView(brand: .fireClay)
//    }
//}
