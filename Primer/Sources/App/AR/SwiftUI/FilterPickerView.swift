import SwiftUI
import UIKit
import PrimerEngine

public struct FilterPickerStyle {
    public var diameter: CGFloat
    public var smallDiameter: CGFloat
    public var sidePadding: CGFloat
    public var interval: CGFloat
    
    public var visibilityTransitionStyle: VisibilityTransitionStyle
    
    public static let defaultStyle = FilterPickerStyle(
            diameter: 64.0,
            smallDiameter: 48.0,
            sidePadding: 24.0,
            interval: 80.0,
            visibilityTransitionStyle: .defaultStyle)
}

extension FilterPickerStyle {
    
    public struct VisibilityTransitionStyle {
        public var range: CGFloat
        public var minimumScale: CGFloat
        public var horizontalTranslation: CGFloat
        
        public static let defaultStyle = VisibilityTransitionStyle(
            range: 120.0,
            minimumScale: 0.001,
            horizontalTranslation: 48.0)
    }
}


extension View {
    
    public func filterPickerStyle(_ style: FilterPickerStyle) -> some View {
        environment(\.filterPickerStyle, style)
    }
}


public struct FilterPickerView<Element: Identifiable, Content: View>: View {
    
    public var data: [Element]
    public var currentIndex: Binding<Double>
    public var content: (Float, Element) -> Content
    
    @Environment(\.filterPickerStyle) private var style
    
    @Environment(\.analytics) var analytics
    
    var appState: AppState
    var hasRecorded: Binding<Bool>
    var recordingState: AppState.RecordingState
    var onBeganRecording: () -> Void
    var onEndedRecording: () -> Void
    var onTakeScreenshot: () -> Void
    var onIndexChange: (Double)-> Void
        
    init(
        appState: AppState,
        data: [Element],
        currentIndex: Binding<Double>,
        hasRecorded: Binding<Bool>,
        recordingState: AppState.RecordingState,
        onBeganRecording: @escaping () -> Void,
        onEndedRecording: @escaping () -> Void,
        onTakeScreenshot: @escaping () -> Void,
        onIndexChange: @escaping (Double)-> Void,
        content: @escaping (Float, Element) -> Content)
    {
        self.appState = appState
        self.data = data
        self.currentIndex = currentIndex
        self.hasRecorded = hasRecorded
        self.recordingState = recordingState
        self.onBeganRecording = onBeganRecording
        self.onEndedRecording = onEndedRecording
        self.onTakeScreenshot = onTakeScreenshot
        self.onIndexChange = onIndexChange
        self.content = content
    }
        
    public var body: some View {
        WrapperView(
            appState: appState,
            style: style,
            currentIndex: currentIndex,
            data: data,
            hasRecorded: hasRecorded,
            recordingState: recordingState,
            onBeganRecording: onBeganRecording,
            onEndedRecording: onEndedRecording,
            onTakeScreenshot: onTakeScreenshot,
            onIndexChange: onIndexChange,
            content: content)
            .frame(maxWidth: .infinity)
            .frame(height: style.diameter + 48.0)
            .analytics(analytics)
    }
}

fileprivate struct WrapperView<Element: Identifiable, Content: View>: UIViewControllerRepresentable {
    
    var appState: AppState
    var style: FilterPickerStyle
    var currentIndex: Binding<Double>
    var data: [Element]
    var hasRecorded: Binding<Bool>
    var recordingState: AppState.RecordingState
    var onBeganRecording: () -> Void
    var onEndedRecording: () -> Void
    var onTakeScreenshot: () -> Void
    var onIndexChange: (Double)-> Void
    var content: (Float, Element) -> Content
    
    @Environment(\.analytics) var analytics
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<WrapperView>) -> FilterPickerViewController<Element, Content> {
        FilterPickerViewController(
            style: style,
            data: data,
            appState: appState,
            hasRecorded: hasRecorded,
            recordingState: recordingState,
            onBeganRecording: onBeganRecording,
            onEndedRecording: onEndedRecording,
            onTakeScreenshot: onTakeScreenshot,
            onIndexChange: onIndexChange,
            content: content,
            analytics: analytics)
    }
    
    func updateUIViewController(_ uiViewController: FilterPickerViewController<Element, Content>, context: UIViewControllerRepresentableContext<WrapperView>) {
        context.coordinator.onIndexChange = { newIndex in
            if newIndex != self.currentIndex.wrappedValue {
//                if(newIndex == 0.0 || newIndex == Double(self.data.count - 1)){
                    self.onIndexChange(newIndex)
//                }
                self.currentIndex.wrappedValue = newIndex
            }
        }
        uiViewController.delegate = context.coordinator
        uiViewController.update(
            style: style,
            currentIndex: currentIndex.wrappedValue,
            data: data,
            appState: appState,
            hasRecorded: hasRecorded,
            recordingState: recordingState,
            onBeganRecording: onBeganRecording,
            onEndedRecording: onEndedRecording,
            onTakeScreenshot: onTakeScreenshot,
            content: content)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    final class Coordinator: FilterPickerViewControllerDelegate {
        
        var onIndexChange: (Double) -> Void = { _ in }
        
        func filterPickerDidChangeCurrentIndex(to newIndex: Double) {
            onIndexChange(newIndex)
        }
    }
}



fileprivate protocol FilterPickerViewControllerDelegate: class {
    func filterPickerDidChangeCurrentIndex(to newIndex: Double)
}


fileprivate final class FilterPickerViewController<Element: Identifiable, Content: View>: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    weak var delegate: FilterPickerViewControllerDelegate? = nil
    
    private var appState: AppState
    private var style: FilterPickerStyle
    private var data: [Element]
    private var hasRecorded: Binding<Bool>
    private var recordingState: AppState.RecordingState
    private var onBeganRecording: () -> Void
    private var onEndedRecording: () -> Void
    private var onTakeScreenshot: () -> Void
    private var onIndexChange: (Double)-> Void
    private var content: (Float, Element) -> Content
    private var analytics : Analytics?
    
    private let hostingController: UIHostingController<FilterPickerContentView<Element, Content>>
    
    private let feedbackGenerator = UISelectionFeedbackGenerator()
    
    private let longPressRecognizer = UILongPressGestureRecognizer()
    
    private let tapRecognizer = UITapGestureRecognizer()
            
    private let scrollView = UIScrollView()
    
    private var lastLayoutSize: CGSize = .zero
    
    private var lastIndex: Double = 1.0
    
    private var analyticsTimer : Timer? = nil
    
    private var didRotate: Bool = false    
    
        
    
    init(style: FilterPickerStyle,
         data: [Element],
         appState: AppState,
         hasRecorded: Binding<Bool>,
         recordingState: AppState.RecordingState,
         onBeganRecording: @escaping () -> Void,
         onEndedRecording: @escaping () -> Void,
         onTakeScreenshot: @escaping () -> Void,
         onIndexChange: @escaping (Double)-> Void,
         content: @escaping (Float, Element) -> Content,
         analytics: Analytics?)
    {
        self.appState = appState
        self.style = style
        self.data = data
        self.hasRecorded = hasRecorded
        self.recordingState = recordingState
        self.onBeganRecording = onBeganRecording
        self.onEndedRecording = onEndedRecording
        self.onTakeScreenshot = onTakeScreenshot
        self.onIndexChange = onIndexChange
        self.analytics = analytics
        self.content = content
        hostingController = UIHostingController(rootView: FilterPickerContentView(
            appState: appState,
            data: data,
            content: content,
            currentIndex: 1.0,
            onSelect: { _ in },
            hasRecorded: hasRecorded,
            recordingState: .notRecording,
            onBeganRecording: {},
            onEndedRecording: {}))
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.alwaysBounceHorizontal = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        // Move the gesture recognizer to self so that it captures touches from all subviews
        view.addGestureRecognizer(scrollView.panGestureRecognizer)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    
        hostingController.view.backgroundColor = .clear
        
        
        tapRecognizer.addTarget(self, action: #selector(tapPress))
        tapRecognizer.delegate = self
        tapRecognizer.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapRecognizer)
        
        longPressRecognizer.addTarget(self, action: #selector(longPress))
        longPressRecognizer.delegate = self
        longPressRecognizer.minimumPressDuration = 0.2
        view.addGestureRecognizer(longPressRecognizer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hostingController.view.frame = view.bounds
        
        if lastLayoutSize != view.bounds.size {
            lastLayoutSize = view.bounds.size
            self.didRotate = true
            scrollView.frame = view.bounds
            scrollView.contentInset = UIEdgeInsets(
                top: 0.0,
                left: floor(view.bounds.width / 2.0),
                bottom: 0.0,
                right: floor(view.bounds.width / 2.0))
        }
        
        let contentSize = CGSize(
            width: CGFloat(data.count-1) * style.interval,
            height: 0.0)
        if contentSize != scrollView.contentSize {
            scrollView.contentSize = contentSize
        }
        
        if didRotate {
            didRotate = false
        }
        updateContentView()
    }
    
    private var currentIndex: Double {
        Double((scrollView.contentOffset.x + scrollView.contentInset.left) / style.interval)
    }
    
    private func scroll(to index: Int, animated: Bool) {
        scroll(to: Double(index), animated: animated)
    }
    
    private func scroll(to index: Double, animated: Bool) {
        let newOffset = style.interval * CGFloat(index) - scrollView.contentInset.left
        scrollView.setContentOffset(CGPoint(x: newOffset, y: 0.0), animated: animated)
    }
    
    private func updateCurrentIndex() {
        if didRotate {
            return
        }
        guard lastIndex != currentIndex else {
            scroll(to:lastIndex, animated: false)
            return
            
        }
        var tempSavedIndex:Double = 0
        tempSavedIndex = lastIndex
        if Int(round(currentIndex)) != Int(round(lastIndex)) {
            if(round(currentIndex) != 0 && round(currentIndex) != Double(self.data.count)){
                self.onIndexChange(round(currentIndex))
            }
            feedbackGenerator.selectionChanged()
        }
        
        lastIndex = currentIndex
        if analyticsTimer != nil {
            analyticsTimer?.invalidate()
        }
        analyticsTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false){ timer in
            let currentIndex = Int(self.currentIndex)
            if(currentIndex < self.data.count && tempSavedIndex >= 1.0){
                let product = IndexedElement(index:currentIndex, element: self.data[currentIndex] ).element
                self.analytics?.didSwitchSwatchMaterial(product:product as! ProductModel)
            }
            timer.invalidate()
        }
        delegate?.filterPickerDidChangeCurrentIndex(to: currentIndex)
    }
    
    private func updateContentView() {
        hostingController.rootView = FilterPickerContentView(
            appState: appState,
            data: data,
            content: content,
            currentIndex: currentIndex,
            onSelect: { [weak self] index in
                self?.scroll(to: index, animated: true)
            },
            hasRecorded: hasRecorded,
            recordingState: recordingState,
            onBeganRecording: onBeganRecording,
            onEndedRecording: onEndedRecording)
    }
    
    func update(style: FilterPickerStyle,
                currentIndex: Double,
                data: [Element],
                appState: AppState,
                hasRecorded: Binding<Bool>,
                recordingState: AppState.RecordingState,
                onBeganRecording: @escaping () -> Void,
                onEndedRecording: @escaping () -> Void,
                onTakeScreenshot: @escaping () -> Void,
                content: @escaping (Float, Element) -> Content) {
        if currentIndex != self.currentIndex {
            scroll(to: currentIndex, animated: false)
        }
        self.style = style
        self.data = data
        self.appState = appState
        self.recordingState = recordingState
        self.onBeganRecording = onBeganRecording
        self.onEndedRecording = onEndedRecording
        self.onTakeScreenshot = onTakeScreenshot
        self.content = content
        view.setNeedsLayout()
    }
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        scroll(to: self.lastIndex, animated: false)
        
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.setNeedsLayout()
        updateCurrentIndex()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let endIndex = round((targetContentOffset.pointee.x + scrollView.contentInset.left) / style.interval)
        targetContentOffset.pointee.x = (endIndex * style.interval) - scrollView.contentInset.left
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }
    
    @objc private func longPress(_ recognizer: UILongPressGestureRecognizer) {
        #if !APPCLIP
        if appState.engineState.swatch == nil {
            return
        }
        switch recognizer.state {
        case .began:
            onBeganRecording()
        case .ended, .cancelled:
            onEndedRecording()
        default:
            break
        }
        #endif
    }
    
    @objc private func tapPress(_ recognizer: UITapGestureRecognizer) {
        #if !APPCLIP
        if appState.engineState.swatch == nil {
            return
        }
        onTakeScreenshot()
        #endif
    }

    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapRecognizer && otherGestureRecognizer == scrollView.panGestureRecognizer {
            return true
        }
        return true
    }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == longPressRecognizer ||
            gestureRecognizer == tapRecognizer
            {
            let rect = CGRect(
                x: view.bounds.midX - style.diameter/2.0,
                y: view.bounds.midY - style.diameter/2.0,
                width: style.diameter,
                height: style.diameter)
            if rect.contains(gestureRecognizer.location(in: view)) {
                return true
            } else {
                return false
            }
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == longPressRecognizer && otherGestureRecognizer == scrollView.panGestureRecognizer {
            return true
        }
        return false
    }
}


fileprivate struct FilterPickerContentView<Element: Identifiable, Content: View>: View {
    
    var appState: AppState
    var data: [Element]
    var content: (Float, Element) -> Content
    var currentIndex: Double
    var onSelect: (Int) -> Void
    var hasRecorded: Binding<Bool>
    var recordingState: AppState.RecordingState
    var onBeganRecording: () -> Void
    var onEndedRecording: () -> Void
        
    @Environment(\.filterPickerStyle) private var style
    
    public var body: some View {
        GeometryReader { proxy in
            ForEach(self.visibleElements(layoutWidth: proxy.size.width)) { indexedElement in
                self.content(for: indexedElement, proxy: proxy)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(whiteCircleOverlay)
    }
    
    private func visibleElements(layoutWidth: CGFloat) -> [IndexedElement<Element>] {
        
        let maxDistanceFromCenter = layoutWidth/2.0 - style.sidePadding + style.visibilityTransitionStyle.range

        let indexDelta = Double(maxDistanceFromCenter / style.interval)

        let minIndex = Int(floor(currentIndex - indexDelta))
        let maxIndex = Int(ceil(currentIndex + indexDelta))

        let range = (minIndex..<maxIndex).clamped(to: data.indices)
        
        return range.map { index in
            IndexedElement(index: index, element: data[index])
        }
    }
    
    private func content(for indexedElement: IndexedElement<Element>, proxy: GeometryProxy) -> some View {
        
        let baseXOffset = (CGFloat(indexedElement.index) - CGFloat(currentIndex)) * style.interval
        let maxXOffset = proxy.size.width/2.0 - style.smallDiameter/2.0 - style.sidePadding
        
        var visibleAmount: CGFloat = 1.0
        
        var actualXOffset = baseXOffset
        if actualXOffset > maxXOffset {
            visibleAmount = 1.0 - ((actualXOffset - maxXOffset) / style.visibilityTransitionStyle.range)
            actualXOffset = maxXOffset + ((1.0 - visibleAmount) * style.visibilityTransitionStyle.horizontalTranslation)
        } else if actualXOffset < -maxXOffset {
            visibleAmount = 1.0 - ((-actualXOffset - maxXOffset) / style.visibilityTransitionStyle.range)
            actualXOffset = -maxXOffset - ((1.0 - visibleAmount) * style.visibilityTransitionStyle.horizontalTranslation)
        }
        
        let centeredAmount = 1.0 - abs(actualXOffset / maxXOffset)
        let diameter = style.smallDiameter + ((style.diameter - style.smallDiameter) * centeredAmount)
        
        visibleAmount = max(min(visibleAmount, 1.0), 0.001)
        
        let scale = visibleAmount
        
        let percentile:Double = 1.0 - Double(indexedElement.index + 1) / Double(self.data.count)
        
        var priority:Float
        
        if(percentile > 0.66){
            priority = URLSessionTask.highPriority
        }else if(percentile > 0.33){
            priority = URLSessionTask.defaultPriority
        }else{
            priority = URLSessionTask.lowPriority
        }
        
        return content(priority, indexedElement.element)
            .frame(width: diameter, height: diameter, alignment: .center)
            .clipShape(Circle())
            .shadow(radius: 4.0)
            .contentShape(Circle())
            .overlay(RoundedRectangle(cornerRadius: diameter / 2).strokeBorder(lineWidth: 1).foregroundColor(Color.white.opacity(0.3)))
            .scaleEffect(scale)
            .if(needsNotificationBadge(element: indexedElement)) { content in
                content.overlay(
                    ZStack {
                        Circle()
                            .foregroundColor(.blue)
                    }
                    .offset(x: 20, y: -20)
                    .frame(width: 15, height: 15)
                    .scaleEffect(scale)
                )
            }
            .position(x: proxy.size.width/2.0, y: proxy.size.height/2.0)
            .offset(x: actualXOffset, y: 0.0)
            .if(!hasRecorded.wrappedValue) { content in
                content.opacity(centeredAmount > 0.95 ? 1.0 : 0.3)
            }
            .if(hasRecorded.wrappedValue) { content in
                content.opacity(Double(visibleAmount))
            }
            .zIndex(1000 - abs(Double(indexedElement.index) - Double(currentIndex)))
            .onTapGesture {
                self.onSelect(indexedElement.index)
            }.onAppear {
                guard let product = indexedElement.element as? ProductModel else { return }
                let location = appState.productCollection.value.firstIndex(of: product) ?? -1
                if location > 0 && appState.productCollection.value.count - location <= 5 {
                    appState.productCollection.append()
                }
            }
    }
    
    private func needsNotificationBadge(element: IndexedElement<Element>) -> Bool {
        // only set true if there's more than one variation available
        if (element.element as! ProductModel).productType == .productWithVariations, (element.element as! ProductModel).variations?.count ?? -1 > 1 {
            return true
        } else {
            return false
        }
    }
    
    private var whiteCircleOverlay: some View {
        ZStack {
            Circle()
                .stroke(SwiftUI.Color.white.opacity(recordingState.isRecording ? 0.3 : 1.0),
                    lineWidth: recordingState.isRecording ? 16 : 4.0)
                .padding(-8.0)
            
            Circle()
                .trim(from: 0.0, to: recordingState.amountComplete)
                .stroke(
                    SwiftUI.Color(
                        red: 0/255,
                        green: 143/255,
                        blue: 244/255),
                    style: StrokeStyle(
                        lineWidth: recordingState.isRecording ? 12.0 : 0.0,
                        lineCap: .round,
                        lineJoin: .round))
                .rotationEffect(Angle(degrees:-90))
                .padding(-10)
                .opacity(recordingState.isRecording ? 1.0 : 0.0)
            
            #if !APPCLIP
            ZStack {
                VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
                    .frame(width: 44, height: 44, alignment: .center)
                    .clipShape(Circle())
                            
                Image(systemName: SFSymbol.cameraFill.rawValue)
                    .font(Font.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(SwiftUI.Color.white)
                    .frame(width: 44, height: 44, alignment: .center)
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(lineWidth: 1).foregroundColor(Color.white.opacity(0.4)))
            }
            .transition(.opacity)
            .opacity(self.appState.engineState.swatch == nil ? 0 : 1)
            #endif
        }
        .frame(width: style.diameter, height: style.diameter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .animation(.default)
    }
}


fileprivate struct IndexedElement<Element: Identifiable>: Identifiable {
    
    var id: Element.ID {
        element.id
    }
    
    var index: Int
    var element: Element
}

extension View {
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            return AnyView(content(self))
        } else {
            return AnyView(self)
        }
    }
}


//
//struct FilterPickerView_Previews: PreviewProvider {
//    static var previews: some View {
//        struct WrapperView: View {
//
//            struct Filter: Identifiable {
//
//                var id = UUID()
//
//                var color: Color
//
//                init(color: Color) {
//                    self.color = color
//                }
//
//            }
//
//            @State private var selection: Double = 0
//
//            var filters = [
//                Filter(color: .orange),
//                Filter(color: .red),
//                Filter(color: .green),
//                Filter(color: .pink),
//                Filter(color: .yellow),
//                Filter(color: .blue),
//                Filter(color: .gray),
//                Filter(color: .orange),
//                Filter(color: .red),
//                Filter(color: .green),
//                Filter(color: .pink),
//                Filter(color: .yellow),
//                Filter(color: .blue),
//                Filter(color: .gray),
//                Filter(color: .orange),
//                Filter(color: .red),
//                Filter(color: .green),
//                Filter(color: .pink),
//                Filter(color: .yellow),
//                Filter(color: .blue),
//                Filter(color: .gray),
//                Filter(color: .orange),
//                Filter(color: .red),
//                Filter(color: .green),
//                Filter(color: .pink),
//                Filter(color: .yellow),
//                Filter(color: .blue),
//                Filter(color: .gray)
//            ]
//
//            var body: some View {
//                FilterPickerView(data: filters, currentIndex: $selection) { filter in
//                    filter.color
//                }
//            }
//        }
//        return WrapperView()
//    }
//}
