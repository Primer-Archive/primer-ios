import SwiftUI

fileprivate final class ViewControllerReference {
    weak var viewController: EngineViewController? = nil
}

public struct EngineContext {
    
    fileprivate let reference: ViewControllerReference
    
    private var viewController: EngineViewController? {
        reference.viewController
    }
    
    public func takeSnapshot() -> UIImage? {
        return reference.viewController?.getSnapshot()
    }
    
    public var isRecording: Bool {
        viewController?.isRecordingVideo == true || viewController?.isFinishingRecordingVideo == true
    }
    
    public func startRecording(selectedProduct: ProductModel?, variationIndex: Int) {
        assert(!isRecording)
        viewController?.startRecordingVideo(selectedProduct: selectedProduct, variationIndex: variationIndex)
    }
    
    public func stopRecording(completion: @escaping (URL?) -> Void) {
        viewController?.stopRecordingVideo(completion: completion)
    }
    
    public func placeSwatch() {
        viewController?.placeSwatch()
    }
    
}

public struct EngineView<OverlayContent: View>: View {
    
    @State private var viewControllerReference = ViewControllerReference()
        
    public var overlayContent: (EngineContext) -> OverlayContent
    public var material: MaterialModel?
    public var onEvent: (EngineEvent, Swatch) -> Void
    @Binding public var state: EngineState
    
    @ObservedObject private var materialCache = MaterialCache.shared
    
    public init(material: MaterialModel?, state: Binding<EngineState>, onEvent: @escaping (EngineEvent,Swatch) -> Void = { _,_ in }, overlayContent: @escaping (EngineContext) -> OverlayContent) {
        self.overlayContent = overlayContent
        self.material = material
        self.onEvent = onEvent
        self._state = state
    }
    
    private var cachedMaterial: CachedMaterial? {
        guard let material = material else { return nil }
        switch materialCache.state(for: material,priority: URLSessionTask.highPriority) {
        case .loading:
            return nil
        case .loaded(let cached):
            return cached
        }
    }
    
    public var body: some View {
        ZStack {
            WrapperView(
                viewControllerReference: viewControllerReference,
                material: cachedMaterial,
                onEvent: onEvent,
                state: $state)
                .edgesIgnoringSafeArea(.all)
            
            overlayContent(EngineContext(reference: viewControllerReference))
        }
    }
}

public enum EngineEvent {
    case placedSwatch
    case movedSwatch
    case resizedSwatch
}

fileprivate struct WrapperView: UIViewControllerRepresentable {
    
    var viewControllerReference: ViewControllerReference
    var material: CachedMaterial?
    var onEvent: (EngineEvent,Swatch) -> Void
    @Binding var state: EngineState
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<WrapperView>) -> EngineViewController {
        EngineViewController()
    }
    
    func updateUIViewController(_ uiViewController: EngineViewController, context: UIViewControllerRepresentableContext<WrapperView>) {
        uiViewController.material = material
        uiViewController.stateBinding = $state
        uiViewController.onEvent = onEvent
        viewControllerReference.viewController = uiViewController
    }
    
}
