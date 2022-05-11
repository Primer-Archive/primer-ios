import SwiftUI
import PrimerEngine

struct BrandBioView: View {
    
    @State private var showingInstagram = false

    @Environment(\.analytics) var analytics
    
    var brand: BrandModel
    
    var body: some View {
        VStack {
            Text(brand.bio)
                .font(
                    .system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14, weight: .regular, design: .rounded)
                )
                .lineLimit(24)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 16)
                .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 16)
                .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 16)
                .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 16)
                .frame(maxWidth: .infinity, alignment: .center)
        

            Button(action: {
                self.showingInstagram = true
                self.analytics?.didViewBrandLink(brand: self.brand)
            }) {
                Text(brand.featuredLinkTitle)
                    .font(
                        .system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14, weight: .medium, design: .rounded)
                    )
                    .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 12)
                    .padding(.top, 0)
                    .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 12)
                    .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12)
                    .foregroundColor(BrandColors.blueToggleAqua.color)
                    .multilineTextAlignment(.center)
            }.sheet(isPresented: self.$showingInstagram) {
                WebView(request: URLRequest(url: URL(string: self.brand.featuredLinkUrl)!))
            }
        }
    }

}

//struct BrandBioView_Previews: PreviewProvider {
//    static var previews: some View {
//        BrandBioView(brand: .kateZaremba)
//    }
//}
