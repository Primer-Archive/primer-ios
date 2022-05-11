import Combine
import Foundation

public final class RequestController<T>: ObservableObject {
    
    private let makeRequest: AnyPublisher<T, Error>
    
    private var currentRequest: AnyPublisher<T, Error>? = nil
    
    public var isRefreshing: Bool {
        currentRequest != nil
    }
    
    @Published
    public var value: T
    
    private var cancellable: AnyCancellable? = nil
    
    init(makeRequest: AnyPublisher<T, Error>, initialValue: T) {
        self.makeRequest = makeRequest
        self.value = initialValue
    }
    
    @discardableResult
    public func refresh() -> AnyPublisher<T, Error> {
        
        if let currentRequest = currentRequest {
            // don't slam the server
            return currentRequest
        }
        
        let request = makeRequest
            .share()
            .eraseToAnyPublisher()
        
        currentRequest = request
        
        cancellable = request
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.currentRequest = nil
            },
            receiveValue: { [weak self] value in
                self?.value = value
            })
        
//        print("Performed request: \(self)")
        
        return request.eraseToAnyPublisher()
    }
    
    
}
