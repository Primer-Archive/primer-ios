import SwiftUI
import Combine

public struct RemoteContentView<Response, Content: View>: View {
    
    private enum LoadingState {
        case notLoaded
        case loading
        case failed(Error)
        case loaded(Response)
        
        var isLoading: Bool {
            if case .notLoaded = self {
                return true
            } else if case .loading = self {
                return true
            } else {
                return false
            }
        }
        
        var isLoaded: Bool {
            if case .loaded = self {
                return true
            }
            return false
        }
        
        var isFailed: Bool {
            if case .failed = self {
                return true
            }
            return false
        }
        
        var error: Error? {
            if case .failed(let error) = self {
                return error
            }
            return nil
        }
        
        var response: Response? {
            if case .loaded(let response) = self {
                return response
            }
            return nil
        }
        
    }
    
    @State private var loadingState = LoadingState.notLoaded
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    public var publisher: AnyPublisher<Response, Error>
    
    public var animation: Animation?
    
    public var content: (Response) -> Content
    
    public init(publisher: AnyPublisher<Response, Error>, animation: Animation? = .default, content: @escaping (Response) -> Content) {
        self.publisher = publisher
        self.animation = animation
        self.content = content
    }
    
    public var body: some View {
        Group {
            
            if loadingState.isLoading {
                ActivityIndicatorView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            
            if loadingState.isFailed {
                Image(systemName: "exclamationmark.circle.fill")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .transition(.opacity)
            }
            
            if loadingState.isLoaded {
                Group {
                    content(loadingState.response!)
                }
                .transition(.opacity)
            }
            
        }
        .onAppear(perform: loadIfNeeded)
    }
    
    private func loadIfNeeded() {
        guard case .notLoaded = loadingState else {
            return
        }
        
        loadingState = .loading
        
        let cancellable = publisher
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.loadingState = .failed(error)
                    }
                },
                receiveValue: { response in
                    withAnimation(self.animation) {
                        self.loadingState = .loaded(response)
                    }
                })
        
        self.cancellables.insert(cancellable)
    }
    
}
