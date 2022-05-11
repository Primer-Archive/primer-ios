import SwiftUI

struct BottomGradientView: View {
    var body: some View {
        let gradient = Gradient(colors: [SwiftUI.Color.black.opacity(0.5), .clear])
        return LinearGradient(gradient: gradient, startPoint: .bottom, endPoint: .top)
            .frame(maxHeight: 160.0)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .edgesIgnoringSafeArea(.all)
    }
}
