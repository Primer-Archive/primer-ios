import SwiftUI

struct TopControlsView<Content: View>: View {
    
    var content: Content
    
    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
            content
        }
        .frame(maxWidth: .infinity)
    .buttonStyle(TopButtonStyle())
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
//        .background(dimmingGradient, alignment: .top)
    }
    
    private var dimmingGradient: some View {
        let gradient = Gradient(colors: [SwiftUI.Color.black.opacity(0.32), .clear])
        return LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
            .frame(maxHeight: 160.0)
            .edgesIgnoringSafeArea(.all)
    }
}

fileprivate struct TopButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title)
            .foregroundColor(.white)
            .opacity(configuration.isPressed ? 0.2 : 1.0)
//            .padding()
    }
}

struct TopControlsView_Previews: PreviewProvider {
    static var previews: some View {
        TopControlsView {
            Text("A")
        }
    }
}
