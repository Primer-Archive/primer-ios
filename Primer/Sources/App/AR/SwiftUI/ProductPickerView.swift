//import SwiftUI
//
//private let circleDiameter: CGFloat = 64.0
//private let recordingCircleDiameter: CGFloat = 64.0
//private let unselectedCircleScale: CGFloat = 0.8
//
//private let circleInterval: Angle = .radians(.pi / 12)
//private let transformRadiusToScreenWidthRatio: CGFloat = 1.0
//private let transformPerspective: CGFloat = 1.0 / 200.0
//
//struct ProductPickerView: View {
//    
//    var hiddenAmount: Double
//    var products: [Product]
//    @Binding var selectedIndex: Double
//    var recordingState: AppState.RecordingState
//    var onBeganRecording: () -> Void
//    var onEndedRecording: () -> Void
//
//    @State private var isRecording: Bool = false
//    
//    @State private var indexWhenDragBegan: Double?
//    
//    var body: some View {
//        return GeometryReader { proxy in
//            Group {
//                ForEach(self.products, id: \.self) { product in
//                    self.view(
//                        for: self.products.firstIndex(of: product)!,
//                        proxy: proxy,
//                        currentIndex: self.selectedIndex)
//                }
//            }
//            .overlay(self.whiteCircleOverlay)
//            .contentShape(Rectangle())
//            .gesture(self.gesture(screenWidth: proxy.size.width))
//        }
//
//        .frame(height: 88.0)
//        .frame(maxWidth: .infinity)
//    }
//    
//    private var whiteCircleOverlay: some View {
//        
//        ZStack {
//            Circle()
//                .stroke(SwiftUI.Color.white.opacity(recordingState.isRecording ? 0.3 : 1.0),
//                    lineWidth: recordingState.isRecording ? 16 : 4.0)
//                .padding(-8.0)
//            
//            Circle()
//                .trim(from: 0.0, to: recordingState.amountComplete)
//                .stroke(
//                    SwiftUI.Color(
//                        red: 0/255,
//                        green: 143/255,
//                        blue: 244/255),
//                    style: StrokeStyle(
//                        lineWidth: recordingState.isRecording ? 12.0 : 0.0,
//                        lineCap: .round,
//                        lineJoin: .round))
//                .rotationEffect(Angle(degrees:-90))
//                .padding(-10)
//                .opacity(isRecording ? 1.0 : 0.0)
//            
//        }
//
//            .frame(width: recordingCircleDiameter, height: recordingCircleDiameter)
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//        
//    }
//    
//    private func view(for index: Int, proxy: GeometryProxy, currentIndex: Double) -> some View {
//        let product = products[index]
//        
//        let baseContent: AnyView
//        
//        switch product.content {
//        case .paint(let paint):
//            baseContent = content(for: paint)
//        case .wallpaper(let wallpaper):
//            baseContent = content(for: wallpaper)
//        case .tile(let tile):
//            baseContent = content(for: tile)
//        }
//        
//        let transformRadius = transformRadiusToScreenWidthRatio * proxy.size.width
//                
//        return baseContent
//            .frame(width: computedSize(for: index), height: computedSize(for: index))
//            .background(SwiftUI.Color.white)
//            .clipShape(Circle())
//            .contentShape(Circle())
//            .compositingGroup()
//            .position(x: proxy.size.width/2.0, y: proxy.size.height/2.0)
//            .modifier(PerspectiveEffect(
//                angle: radianOffset(for: index, currentIndex: currentIndex),
//                radius: transformRadius))
//            .shadow(radius: 4.0)
//            .opacity(computedOpacity(for: index))
//            .zIndex(1000 - abs(Double(index) - currentIndex))
//            .onTapGesture {
//                withAnimation {
//                    self.selectedIndex = Double(index)
//                }
//            }
//    }
//    
//    private func radianOffset(for index: Int, currentIndex: Double) -> Angle {
//        let radianGap = circleInterval.radians
//        let radianOffset = (currentIndex - Double(index)) * radianGap
//        return Angle(radians: radianOffset)
//    }
//    
//    private func content(for paint: Paint) -> AnyView {
//        let view = paint.color.swiftUIColor
//        return AnyView(view)
//    }
//    
//    private func content(for wallpaper: Wallpaper) -> AnyView {
//        let image = Image(wallpaper.diffuse.name)
//            .resizable()
//            .aspectRatio(contentMode: .fill)
//        return AnyView(image)
//    }
//    
//    private func content(for tile: Tile) -> AnyView {
//        let image = SwiftUI.Image(tile.diffuse.name)
//            .resizable()
//            .aspectRatio(contentMode: .fill)
//        return AnyView(image)
//    }
//    
//    private func gesture(screenWidth: CGFloat) -> some Gesture {
//        ExclusiveGesture(
//            recordingGesture,
//            dragGesture(screenWidth: screenWidth))
//    }
//    
//    private var recordingGesture: some Gesture {
//        recordingLongPressGesture.sequenced(before: recordingDragGesture)
//    }
//    
//    private var recordingLongPressGesture: some Gesture {
//        LongPressGesture(minimumDuration: 0.1, maximumDistance: 5.0)
//            .onEnded { success in
//                if success {
//                    if !self.isRecording {
//                          self.onBeganRecording()
//                          self.isRecording = true
//                      }
//                }
//            }
//    }
//    
//    private var recordingDragGesture: some Gesture {
//        DragGesture(minimumDistance: 0, coordinateSpace: .global)
//            .onEnded { _ in
//                if self.isRecording {
//                    self.onEndedRecording()
//                    self.isRecording = false
//                    print("ENDED")
//                }
//            }
//    }
//    
//    private func dragGesture(screenWidth: CGFloat) -> some Gesture {
//        DragGesture(minimumDistance: 5.0, coordinateSpace: .global)
//            .onChanged { value in
//                let initialIndex = self.indexWhenDragBegan ?? self.selectedIndex
//                self.indexWhenDragBegan = initialIndex
//                self.selectedIndex = initialIndex - Double(value.translation.width / screenWidth) / circleInterval.radians
//            }
//            .onEnded { value in
//                self.indexWhenDragBegan = nil
//                self.snapToNearestProduct(value: value, screenWidth: screenWidth)
//            }
//    }
//    
//    private func focusedAmount(for index: Int) -> Double {
//        let indexDelta = abs(Double(index) - selectedIndex)
//        return (1.0 - (min(1.0, indexDelta)))
//    }
//    
//    private func computedScale(for index: Int) -> CGFloat {
//        let scale = unselectedCircleScale + (CGFloat(focusedAmount(for: index)) * (1.0 - unselectedCircleScale))
//        return scale * CGFloat(1.0 - hiddenAmount)
//    }
//    
//    private func computedOpacity(for index: Int) -> Double {
//        if recordingState.isRecording {
//            return focusedAmount(for: index) * (1.0 - hiddenAmount)
//        } else {
//            let offset = radianOffset(for: index, currentIndex: selectedIndex)
//            var fadeAmount = 0.0
//            if abs(offset.radians) > (.pi / 2.0 * 0.6) {
//                fadeAmount = abs(offset.radians - (.pi / 2.0 * 0.6)) / (.pi / 2.0 * 0.4)
//            }
//            if fadeAmount > 1.0 {
//                fadeAmount = 1.0
//            }
//            return (1.0 - fadeAmount) * (1.0 - hiddenAmount)
//        }
//    }
//    
//    private func computedSize(for index: Int) -> CGFloat {
//        if recordingState.isRecording {
//            return circleDiameter + ((recordingCircleDiameter - circleDiameter) * CGFloat(focusedAmount(for: index)))
//        } else {
//            return circleDiameter
//        }
//    }
//    
//    private func snapToNearestProduct(value: DragGesture.Value, screenWidth: CGFloat) {
//        var finalIndex = self.indexWhenDragBegan ?? self.selectedIndex
//        finalIndex -= Double(value.translation.width / screenWidth) / circleInterval.radians
//
//        var newIndex = Int(round(finalIndex))
//        if newIndex >= products.count {
//            newIndex = products.count - 1
//        }
//        if newIndex < 0 {
//            newIndex = 0
//        }
//        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.0)) {
//            selectedIndex = Double(newIndex)
//        }
//    }
//}
//
//private struct PerspectiveEffect: GeometryEffect {
//    
//    var angle: Angle
//    var radius: CGFloat
//    
//    var animatableData: AnimatablePair<Angle.AnimatableData, CGFloat> {
//        get { AnimatablePair(angle.animatableData, radius) }
//        set {
//            angle.animatableData = newValue.first
//            radius = newValue.second
//        }
//    }
//    
//    func effectValue(size: CGSize) -> ProjectionTransform {
//        // Work in x/y for convenience (will map to x/z)
//        var point = CGPoint(x: 0.0, y: radius)
//        point = point.applying(CGAffineTransform(rotationAngle: CGFloat(angle.radians)))
//        
//        var finalTransform = CATransform3DIdentity
//        finalTransform = CATransform3DTranslate(
//            finalTransform,
//            -size.width/2.0,
//            -size.height/2.0,
//            0)
//        finalTransform.m34 = transformPerspective
//        finalTransform = CATransform3DTranslate(finalTransform, point.x, 0.0, radius - point.y)
//        
//        let affineTransform = ProjectionTransform(CGAffineTransform(translationX: size.width/2.0, y: size.height / 2.0))
//        
//        return ProjectionTransform(finalTransform).concatenating(affineTransform)
//    }
//    
//}
//
//struct ProductPickerView_Previews: PreviewProvider {
//    static var previews: some View {
//        
//        struct PreviewView: View {
//            
//            @State var index: Double = 0.0
//            
//            var body: some View {
//                ProductPickerView(
//                    hiddenAmount: 0.0,
//                    products: ProductCollection.wallpaperSample.products,
//                    selectedIndex: $index,
//                    recordingState: .notRecording,
//                    onBeganRecording: {},
//                    onEndedRecording: {})
//            }
//            
//        }
//        
//        return PreviewView()
//    }
//}
