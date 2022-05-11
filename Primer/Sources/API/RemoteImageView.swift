import SwiftUI
import Combine
import MapleBacon

public struct RemoteImageView<Content: View>: View {
    
    private enum LoadingState {
        case notLoaded
        case loading
        case failed(Error)
        case loaded(Image?)
    }
    
    public var url: URL?
    
    public var width: CGFloat?
    
    public var content: (Image) -> Content
    
    
    
    public init(url: URL?,width: CGFloat? = nil, content: @escaping (Image) -> Content) {
        self.url = url
        self.content = content
        self.width = width == 0 ? nil : width
    }
    
    @State private var loadingState = LoadingState.notLoaded
    
    @State private var cancellables: Set<AnyCancellable> = []
            
    public var body: some View {
        Group {
            switch loadingState {
            case .notLoaded:
                ActivityIndicatorView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            case .loading:
                ActivityIndicatorView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            case .failed(let error):
                Text("Failed: \(error.localizedDescription)")
            case .loaded(let image):
                if let image = image {
                    self.content(image)//.transition(.opacity)
                } else {
                    image
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
        .id(url)
    }
    
    private func loadIfNeeded() {
        guard case .notLoaded = loadingState else {
            return
        }
        
        guard let url = url else {
            self.loadingState = .loaded(nil)
            return
        }
        
        loadingState = .loading
        
        guard !url.isFileURL else {
            DispatchQueue.global().async {
                let image = UIImage(contentsOfFile: url.path)
                DispatchQueue.main.async {
                    if let image = image {
                        self.loadingState = .loaded(Image(uiImage: image))
                    } else {
                        self.loadingState = .loaded(nil)
                    }
                }
            }
            return
        }
                
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        if self.width != nil {
            components.queryItems = [URLQueryItem(name: "w", value: "\(self.width! * 2)")]
        }
        
        let absoluteURL = components.url!
        
        let cancellable = MapleBacon.shared
            .image(with: absoluteURL)
            .map { image -> Image? in
                image.map { Image(uiImage: $0) }
            }
            .receive(on: DispatchQueue.main)
            .sink { image in
                self.loadingState = .loaded(image)
            }
        
        self.cancellables.insert(cancellable)
    }
    
}

fileprivate struct ImageDecodingError: Error {}

