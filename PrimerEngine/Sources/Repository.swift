import Foundation
import Combine
import ARKit

// MARK: - Request State

public enum RequestState {
    case none
    case refresh
    case append
    case complete
}

// MARK: - Repository

public class Repository<Model:Decodable>: ObservableObject {
    
    internal var currentRequest: AnyPublisher<Model, Error>? = nil
    
    var path: String
    var method: HTTPMethod
    var body: Data?
    var accessToken: String? = nil
    
    @Published public var isLoading: Bool = false
    @Published public var requestState: RequestState = .none
    
    @Published public var canLoadMore: Bool = false
    
    @Published internal (set) public var value: Model
    
    internal var cancellable: AnyCancellable? = nil
    
    internal var page = 1
    private let compressTextures:Bool
    
    public var maxCompressTextures:Bool = false
    
    private var perPage = 10
    @Published public var loadedLastPage = false
    
    init(path: String, method: HTTPMethod, initialValue: Model) {
        self.path = path
        self.method = method
        self.value = initialValue
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            self.compressTextures = false
        }else{
            self.compressTextures = true
        }
        
        
        if !UIDevice.isGPUPowered() {
            self.maxCompressTextures = true
        }
        
    }
    
    internal func makeRequest<T:Decodable>(modelType:T.Type) -> AnyPublisher<T, Error> {
        
        isLoading = true
        let queryString =  path.contains("?") ? "&" : "?"
        let url = URL(string: "\(ENV.apiURL)api/v2/\(path)\(queryString)page=\(page)&perPage=\(perPage)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.verb
        urlRequest.httpBody = body
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        if maxCompressTextures {
            print("MAXCOMPRESS")
            urlRequest.setValue(String(maxCompressTextures), forHTTPHeaderField: "MaxCompressTextures")
        }else{
            urlRequest.setValue(String(compressTextures), forHTTPHeaderField: "CompressTextures")
        }
        
        if let accessToken = UserDefaults.accessToken {
            urlRequest.setValue(accessToken, forHTTPHeaderField: "Primer-Authorization")
        }
        
        let request = URLSession.shared.dataTaskPublisher(for: urlRequest)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
        
        return request
            .tryMap { data, response -> T in
                let decoder = JSONDecoder()
                let result: T
                if let httpResponse = response as? HTTPURLResponse, let xPagination = httpResponse.allHeaderFields["X-Pagination"] as? String, let data = Data(xPagination.utf8) as Data? {
                    do {
                        // make sure this JSON is in the format we expect
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            // try to read out a string array
                            if let isLastPage = json["last_page"] as? Bool {
                                DispatchQueue.main.async {
                                    self.loadedLastPage = isLastPage
                                }
                                
                            }
                        }
                    } catch let error as NSError {
                        print("Failed to load: \(error.localizedDescription)")
                    }
                }else{
                    print("PAGINGATION HEADER FAIL: \(url)")
                }
                do {
                    result = try decoder.decode(T.self, from: data)
                } catch(let error) {
                    // Print some debugging info
                    print("An error occured! \(self.path)")
                    print(error)
                    if let string = String(data: data, encoding: .utf8) {
                        print(string)
                    }
                    if let url = response.url {
                        print(url)
                    }
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    
                    throw error
                }
                return result
            }
            .eraseToAnyPublisher()
    }
    
    @discardableResult
    public func refresh() -> AnyPublisher<Model, Error> {
        
        if let currentRequest = currentRequest {
            // don't slam the server
            print("c a n c e l l e d: \(self.path)")
            return currentRequest
        }
        
        self.requestState = .refresh
        let request = self.makeRequest(modelType: Model.self)
            .share()
            .eraseToAnyPublisher()
        
        currentRequest = request
        
        cancellable = request
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in
                self.currentRequest = nil
            },
            receiveValue: { value in
                self.value = value
                self.isLoading = false
                self.requestState = .complete
            })
        
        return request.eraseToAnyPublisher()
        
    }
    
    public func append(index: Int? = nil) {
        if self.loadedLastPage || self.isLoading {
            return
        }
        self.page = index ?? (self.page + 1)
        if currentRequest != nil {
            // don't slam the server
            return
        }
        
        self.requestState = .append
        let request = self.makeRequest(modelType: Model.self)
            .share()
            .eraseToAnyPublisher()
        
        currentRequest = request
        
        cancellable = request
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in
                self.currentRequest = nil
            },
            receiveValue: { value in
                if var oldValue = self.value as? [Any], let newValue = value as? [Any] {
                    oldValue += newValue
                    self.value = oldValue as! Model
                }
                self.isLoading = false
                self.requestState = .complete
            })
        
//        return request.eraseToAnyPublisher()
    }
}

// MARK: - Product Collections

public final class ProductCollectionsRepository: Repository<[ProductCollectionModel]>{
    @Published public var productionCollectionDictionary: [ProductCollectionRepository] = []
    
    var _brandId:Int = 0
    
    var brandId:Int {
        set{
            _brandId = newValue
            self.path = "brands/\(newValue)/product_collections.json?showProduct=false"
            self.refresh()
        }
        get{
            return _brandId
        }
    }
    
    public init(){
        super.init(path: "", method: .get, initialValue: [])
    }
    
    public init(brandID: Int){
        super.init(path: "brands/\(brandID)/product_collections.json?showProduct=false",method: .get, initialValue: [])
    }
    
    public func setBrandId(brandID: Int){
        self.brandId = brandID
    }
}

// MARK: - Product Collection

public final class ProductCollectionRepository: Repository<[ProductModel]>{
    
    var _collectionId:Int = 0
    
    var collectionId:Int {
        set{
            _collectionId = newValue
            self.path =  "product_collections/\(_collectionId)/product_collection_items.json"
            self.refresh()
        }
        get{
            return _collectionId
        }
    }
    
    public init(){
        super.init(path: "", method: .get, initialValue: [])
    }
    
    override func makeRequest<T>(modelType: T.Type) -> AnyPublisher<T, Error> where T : Decodable {
        return super.makeRequest(modelType: [ProductCollectionItemModel].self)
            .map { itemModels in
                itemModels.map { $0.product } as! T
            }
            .eraseToAnyPublisher()
    }
    
    public func setCollectionId(collectionId: Int){
        self.collectionId = collectionId
    }
    
    ///This allows us to set an initial value of products, but then have the ID for appending after.
    public func setProductsAndID(products:[ProductModel], collectionId:Int){
        self.value = products
        _collectionId = collectionId
        self.path =  "product_collections/\(_collectionId)/product_collection_items.json"
    }
    
}

// MARK: - Brands

public final class BrandRepository: Repository<[BrandModel]>{
    
    public init(){
        super.init(path: "brands.json", method: .get, initialValue: [])
    }
}

// MARK: - Categories

public final class CategoryProductRepository: Repository<[ProductModel]>{
    var _categoryId:Int = 0
    
    var categoryId:Int {
        set{
            _categoryId = newValue
            self.path =  "product_categories/\(_categoryId)/products.json"
            self.refresh()
        }
        get{
            return _categoryId
        }
    }
    
    public init(){
        super.init(path: "", method: .get, initialValue: [])
    }
    
    public init(forCategory category: CategoryModel){
        super.init(path: "product_categories/\(category.id)/products.json", method: .get, initialValue: [])
    }
    
    public func setCategoryId(categoryId: Int){
        self.categoryId = categoryId
    }
}

// MARK: - Favorites

public final class FavoritesRepository: Repository<[ProductModel]>{
    
    public init(){
        super.init(path: "users/current/favorites.json", method: .get, initialValue: [])
    }
    
    public override func refresh() -> AnyPublisher<[ProductModel], Error> {
        self.page = 1
        return super.refresh()
    }
}

// MARK: - Search Results

public final class BrandSearchResultsRepository: SearchResultsRepository {
    public override init() {
        super.init()
        self.path = "search/brand.json"
    }
    
    public override func search(_ queryItems: [URLQueryItem]) {
        var urlComps = URLComponents(string: "search/brand.json")!
        urlComps.queryItems = queryItems
        
        if let url = urlComps.url {
            self.page = 1
            searchString = url.absoluteString
        }
        
    }
}

public class SearchResultsRepository: Repository<[ProductModel]> {

    var _searchString: String = ""
    var searchString: String {
        set {
            _searchString = newValue
            self.path = searchString
            print("SEARCHING: \(self.path)")
            self.refresh()
        }
        get {
            return _searchString
        }
    }
    
    @Published var isRefreshing: Bool = false
    @Published var isAppending: Bool = false
    
    public init(){
        super.init(path: "search.json", method: .get, initialValue: [])
    }
    
    public func search(_ queryItems: [URLQueryItem]) {
        var urlComps = URLComponents(string: "search.json")!
        urlComps.queryItems = queryItems
        
        if let url = urlComps.url {
            self.page = 1
            searchString = url.absoluteString
        }
        
    }
    
    public override func append(index: Int? = nil) {
        self.isAppending = true
        return super.append(index: index)
    }
    
    @discardableResult
    public override func refresh() -> AnyPublisher<[ProductModel], Error> {
        
        //we will reset the current request as we have updated what we are looking for.
        self.isRefreshing = true
        if currentRequest != nil {
            cancellable?.cancel()
            currentRequest = nil
        }
        
        return super.refresh()
        
    }
}


public final class EmptyProductRepository: Repository<[ProductModel]>{
    
    public init(){
        
        super.init(path: "", method: .get, initialValue: [])
        
        self.value = [
            ProductModel(id: 1, material: MaterialModel(), name: ""),
            ProductModel(id: 2, material: MaterialModel(), name: ""),
            ProductModel(id: 3, material: MaterialModel(), name: ""),
            ProductModel(id: 4, material: MaterialModel(), name: "")
            
        ]
    }
}


// MARK: - Deep Links

public final class DeeplinkSlugRepository: Repository<[ProductModel]>{
    
    public init(productSlug:String){
        super.init(path: "deeplink/product-slug.json?slug=\(productSlug)", method: .get, initialValue: [])
    }
}

public final class DeeplinkAppClipRepository: Repository<[ProductModel]>{
    public init(appClipSlug:String){
        super.init(path: "deeplink/appclip.json?app_clip_slug=\(appClipSlug)", method: .get, initialValue: [])
    }
}

// MARK: - Featured Products

public final class FeaturedProductsRepository: Repository<[ProductModel]>{
    public init(){
        super.init(path: "featured_products.json", method: .get, initialValue: [])
    }
    override func makeRequest<T>(modelType: T.Type) -> AnyPublisher<T, Error> where T : Decodable {
        return super.makeRequest(modelType: [ProductCollectionItemModel].self)
            .map { itemModels in
                itemModels.map { $0.product } as! T
            }
            .eraseToAnyPublisher()
    }
    
}

// MARK: - Featured Product Collections

public final class FeaturedProductCollectionsRepository: Repository<[ProductCollectionModel]>{
    public init(){
        super.init(path: "featured_product_collections.json", method: .get, initialValue: [])
    }
    override func makeRequest<T>(modelType: T.Type) -> AnyPublisher<T, Error> where T : Decodable {
        return super.makeRequest(modelType: [FeaturedProductCollectionModel].self)
            .map { itemModels in
                itemModels.map { $0.productCollection } as! T
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Preview

// For use in PreviewProvider, pass in the test models on init to set value
public final class PreviewTesterRepository: Repository<[ProductModel]> {
    
    public init(models: [ProductModel]) {
        super.init(path: "", method: .get, initialValue: models)
    }
}
