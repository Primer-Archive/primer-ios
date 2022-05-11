import SwiftUI

struct BottomCardAnchorKey: PreferenceKey {
    
    static var defaultValue: Anchor<CGRect>? {
        nil
    }
    
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}


struct BottomCardView<Content: View>: View {
    
    var bottomHeight: CGFloat
    var onExpand: () -> Void
    @Binding var isExpanded: Bool
    @Binding var hide: Bool
    
    var content: (CGFloat) -> Content
    
    private struct DragState {
        var translation: CGSize
        var verticalVelocity: CGFloat
        var lastTimestamp: Date
    }
    
    @State private var dragState: DragState? = nil
    
    var body: some View {
        GeometryReader { proxy in
            self.content(self.expandedAmount(with: proxy))
                .modifier(CardModifier(height: self.cardHeight(with: proxy)))
                .anchorPreference(key: BottomCardAnchorKey.self, value: Anchor<CGRect>.Source.bounds, transform: { $0 })
                .frame(maxHeight: .infinity, alignment: .bottom)
                .onTapGesture(perform: self.toggle)
                .gesture(self.gesture(with: proxy))
                .padding(.bottom,50)
                .opacity(self.hide ? 0 : 1)
        }
    }
    
    private func expandedAmount(with proxy: GeometryProxy) -> CGFloat {
        let proxyHeight = proxy.size.height < 50 ? proxy.size.height : proxy.size.height - 50
        return (cardHeight(with: proxy) - bottomHeight) / (proxyHeight - bottomHeight)
    }
    
    private func gesture(with proxy: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 4.0, coordinateSpace: .global)
            .onChanged { value in
                self.dragDidChange(with: value, proxy: proxy)
            }
            .onEnded { value in
                self.dragDidEnd(with: value, proxy: proxy)
            }
    }
    
    private func dragDidChange(with value: DragGesture.Value, proxy: GeometryProxy) {
        var velocity: CGFloat = 0.0
        if let previous = self.dragState {
            let timeElapsed = value.time.timeIntervalSince1970 - previous.lastTimestamp.timeIntervalSince1970
            velocity = (value.translation.height - previous.translation.height) / CGFloat(timeElapsed)
        }
        self.dragState = DragState(
            translation: value.translation,
            verticalVelocity: velocity,
            lastTimestamp: value.time)
    }
    
    private func dragDidEnd(with value: DragGesture.Value, proxy: GeometryProxy) {
        
        let verticalVelocity = dragState?.verticalVelocity ?? 0.0
        let proxyHeight = proxy.size.height < 50 ? proxy.size.height : proxy.size.height - 50
        
        if isExpanded {
            if value.translation.height > 20.0 && verticalVelocity >= 0 {
                close(initialVelocity: Double(verticalVelocity / proxyHeight * 2.0))
            } else {
                open(initialVelocity: Double(-verticalVelocity / proxyHeight * 2.0))
            }
        } else {
            if value.translation.height < -20.0 && verticalVelocity <= 0 {
                open(initialVelocity: Double(-verticalVelocity / proxyHeight * 2.0))
            } else {
                close(initialVelocity: Double(verticalVelocity / proxyHeight * 2.0))
            }
        }
    }
    
    private func cardHeight(with proxy: GeometryProxy) -> CGFloat {
        var height: CGFloat
        let proxyHeight = proxy.size.height < 50 ? proxy.size.height : proxy.size.height - 50
        
        if isExpanded {
            height = proxyHeight
        } else {
            height = bottomHeight
        }
        
        if let drag = dragState {
            height -= drag.translation.height
        }
        
        if height < bottomHeight {
            height = bottomHeight - rubberBandDistance(offset: bottomHeight - height)
        }
        
        if height > proxyHeight {
            height = proxyHeight + rubberBandDistance(offset: height - proxyHeight)
        }
        
        return height
    }
    
    private func toggle() {
        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.0)) {
            isExpanded.toggle()
            if(isExpanded){
                self.onExpand()
            }
            dragState = nil
        }
    }
    
    private func open(initialVelocity: Double = 0.0) {
        withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 160.0, damping: 20, initialVelocity: initialVelocity)) {
            isExpanded = true
            self.onExpand()
            dragState = nil
        }
    }
    
    private func close(initialVelocity: Double = 0.0) {
        withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 160.0, damping: 20, initialVelocity: initialVelocity)) {
            isExpanded = false
            dragState = nil
        }
    }
}

private struct CardModifier: AnimatableModifier {
    
    var height: CGFloat
    
    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: height, alignment: .top)
            .mask(RoundedRectangle(cornerRadius: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 24, style: .continuous).edgesIgnoringSafeArea([.bottom, .horizontal]))
            .shadow(color: SwiftUI.Color.black.opacity(0.2), radius: 8.0, x: 0.0, y: 0.0)
    }
}

private func rubberBandDistance(offset: CGFloat, dimension: CGFloat = 64.0) -> CGFloat {
    let constant: CGFloat = 0.55
    let result = (constant * abs(offset) * dimension) / (dimension + constant * abs(offset))
    return offset < 0.0 ? -result : result
}

//struct BottomCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        
//        struct PreviewView: View {
//            
//            @State var isExpanded = false
//            
//            var body: some View {
//                BottomCardView(bottomHeight: 48.0, isExpanded: $isExpanded) {
//                    Text("Hello I am a card!")
//                        .font(.title)
//                        .padding()
//                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//                }
//            }
//        }
//        
//        return PreviewView()
//    }
//}
