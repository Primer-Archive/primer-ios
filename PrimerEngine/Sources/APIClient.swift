import Foundation
import Combine
import ARKit
import SwiftUI

enum HTTPMethod {
    case get
    case post
    case put
    
    var verb: String {
        switch self {
            case .get: return "GET"
            case .post: return "POST"
            case .put: return "PUT"
        }
    }
}


// MARK: - API Client

public final class APIClient {
    
    public let accessToken: String?
    
    public let compressTextures:Bool
    
    public var lastError: [String: Any]?

    private (set) public var categoryController: RequestController<[CategoryModel]>!
    private (set) public var searchManager: SearchManager!
    private (set) public var brandSearchManager: BrandSearchManager!
    
    private (set) public var featuredCollectionRepo: Repository<[ProductCollectionModel]>
    private (set) public var brandsRepo: Repository<[BrandModel]>
    private (set) public var productsRepo: Repository<[ProductModel]>
    private (set) public var searchRepo: Repository<[ProductModel]>
    private (set) public var favoritesRepo: Repository<[ProductModel]>
    
    public init(accessToken: String? = nil) {
        self.accessToken = accessToken
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            self.compressTextures = false
        }else{
            self.compressTextures = true
        }
        
        
        featuredCollectionRepo = FeaturedProductCollectionsRepository()
        brandsRepo = BrandRepository()
        productsRepo = FeaturedProductsRepository()
        searchRepo = SearchResultsRepository()
        favoritesRepo = FavoritesRepository()
        
        categoryController = RequestController(makeRequest: categories(), initialValue: [])
        
        searchManager = SearchManager(client: self)
        brandSearchManager = BrandSearchManager(client: self)
        featuredCollectionRepo.refresh()
        brandsRepo.refresh()
        productsRepo.refresh()
        favoritesRepo.refresh()
        
        categoryController.refresh()
        
    }
    
    func performRequest<Model: Decodable>(path: String, method: HTTPMethod = .get, body: Data? = nil, modelType: Model.Type) -> AnyPublisher<Model, Error> {
        return performRawRequest(path: path, method: method, body: body, accessToken: self.accessToken, modelType: modelType,compressTextures: self.compressTextures)
    }
    
    func performRequest(path: String, method: HTTPMethod, body: Data?, accessToken: String? = nil, compressTextures: Bool) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        
        let url = URL(string: "\(ENV.apiURL)api/v2/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method.verb
        request.httpBody = body
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.setValue(String(compressTextures), forHTTPHeaderField: "CompressTextures")
        
        if let accessToken = accessToken {
            request.setValue(accessToken, forHTTPHeaderField: "Primer-Authorization")
        }
        print("calling: \(url)")
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func performRawRequest<Model: Decodable>(path: String, method: HTTPMethod = .get, body: Data? = nil, accessToken: String? = nil, modelType: Model.Type,compressTextures:Bool) -> AnyPublisher<Model, Error> {
        return performRequest(path: path, method: method, body: body, accessToken: accessToken,compressTextures: compressTextures)
            .tryMap { data, response -> Model in
                let decoder = JSONDecoder()
                let result: Model
                do {
                    print("result for: \(path)")
                    result = try decoder.decode(Model.self, from: data)
                } catch(let error) {
                    // Print some debugging info
                    print("An error occured! \(path)")
                    self.lastError = self.convertToDictionary(data: data)
                    if let string = String(data: data, encoding: .utf8) {
                        print(string)
                    }
                    if let url = response.url {
                        print(url)
                    }
                    throw error
                }
                return result
        }
        .eraseToAnyPublisher()
    }
    
    func convertToDictionary(data: Data) -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
}

// MARK: - Accounts

extension APIClient {
    
    public func login(email: String, password: String) -> AnyPublisher<UserModel, Error> {
        struct Request: Encodable {
            var email: String
            var password: String
        }
        
        let req = Request(email: email, password: password)
        let body = try! JSONEncoder().encode(req)
        
        return performRawRequest(path: "sessions", method: .post, body: body, accessToken: nil, modelType: UserModel.self, compressTextures: false)
    }
    
    public func registerSIWA(email: String, fullName: String, siwaId: String) -> AnyPublisher<UserModel,Error> {
        struct UserReq: Encodable {
            var email: String
            var fullName: String
            var siwa_token: String
        }
        struct Request: Encodable {
            var user: UserReq
        }
        
        let user = UserReq(email: email, fullName: fullName,siwa_token: siwaId)
        let req = Request(user: user)
        let body = try! JSONEncoder().encode(req)
        
        return performRawRequest(path: "register/siwa", method: .post, body: body, accessToken: nil, modelType: UserModel.self, compressTextures: false)
    }
    
    public func register(name: String, email: String, password: String, persona: String, subscribe: Bool) -> AnyPublisher<UserModel,Error> {
        struct UserReq: Encodable {
            var name: String
            var email: String
            var password: String
            var persona: String
            var newsletter_subscription: Bool
        }
        struct Request: Encodable {
            var user: UserReq
        }
        
        let user = UserReq(name: name, email: email, password: password, persona: persona, newsletter_subscription: subscribe)
        let req = Request(user: user)
        let body = try! JSONEncoder().encode(req)
        
        return performRawRequest(path: "register", method: .post, body: body, accessToken: nil, modelType: UserModel.self, compressTextures: false)
    }
    
    public func signInSIWA(siwaId: String) -> AnyPublisher<UserModel,Error> {
        struct Request: Encodable {
            var siwa_token: String
        }
        
        let req = Request(siwa_token: siwaId)
        let body = try! JSONEncoder().encode(req)
        
        return performRawRequest(path: "sessions/create_with_siwa", method: .post, body: body, accessToken: nil, modelType: UserModel.self, compressTextures: false)
    }
    
    public func updateIntentAndNewsletter(userid: String, intent: String, subscribe: Bool) -> AnyPublisher<UserModel, Error> {
        struct Request: Encodable {
            var persona: String
            var newsletter_subscription: Bool
        }
        
        let request = Request(persona: intent, newsletter_subscription: subscribe)
        let body = try! JSONEncoder().encode(request)
        
        return performRawRequest(path: "users/\(userid)", method: .put, body: body, accessToken: nil, modelType: UserModel.self, compressTextures: false)
    }
    
    public func forgotPassword(email: String) -> AnyPublisher<SimpleModel, Error> {
        struct Request: Encodable {
            var email: String
        }
        
        let req = Request(email: email)
        let body = try! JSONEncoder().encode(req)
        
        return performRawRequest(path: "users/forgot_password", method: .post, body: body, accessToken: nil, modelType: SimpleModel.self, compressTextures: false)
    }
    
    public func getCurrentUser() -> AnyPublisher<UserModel, Error> {

        return performRawRequest(path: "users/current", method: .post, body: nil, accessToken: self.accessToken, modelType: UserModel.self, compressTextures: false)
    }
    
}

// MARK: - Requests

extension APIClient {
    
    public func brands() -> AnyPublisher<[BrandModel], Error> {
        performRequest(path: "brands.json", modelType: [BrandModel].self)
    }
    
    public func categories() -> AnyPublisher<[CategoryModel], Error> {
        performRequest(path: "product_categories.json", modelType: [CategoryModel].self)
    }
    
    public func products(forBrandID brandID: Int) -> AnyPublisher<[ProductModel], Error> {
        performRequest(path: "brands/\(brandID)/products.json", modelType: [ProductModel].self)
    }
    
    public func productCollections(forBrandID brandID: Int) -> AnyPublisher<[ProductCollectionModel], Error> {
        performRequest(path: "brands/\(brandID)/product_collections.json", modelType: [ProductCollectionModel].self)
    }
    
    public func productCollections(forProductSlug productSlug: String) -> AnyPublisher<[ProductCollectionModel], Error> {
        performRequest(path: "product_collections.json?productSlug=\(productSlug)", modelType: [ProductCollectionModel].self)
    }
    
}

extension APIClient {
    
    public func featuredProducts() -> AnyPublisher<[ProductModel], Error> {
        performRequest(path: "featured_products.json", modelType: [ProductCollectionItemModel].self)
            .map { itemModels in
                itemModels.map { $0.product }
        }
        .eraseToAnyPublisher()
    }
    
    public func product(id: Int) -> AnyPublisher<ProductModel, Error> {
        performRequest(path: "products/\(id).json", modelType: ProductModel.self)
    }
    
}

extension APIClient {
    
    public func featuredProductCollections() -> AnyPublisher<[ProductCollectionModel], Error> {
        performRequest(path: "featured_product_collections.json", modelType: [FeaturedProductCollectionModel].self)
            .map { itemModels in
                itemModels.map { $0.productCollection }
        }
        .eraseToAnyPublisher()
    }
    
    public func products(forProductCollectionID productCollectionID: Int) -> AnyPublisher<[ProductModel], Error> {
        performRequest(path: "product_collections/\(productCollectionID)/product_collection_items.json", modelType: [ProductCollectionItemModel].self)
            .map { itemModels in
                itemModels.map { $0.product }
        }
        .eraseToAnyPublisher()
    }
    
    public func products(forCategory categoryId: Int) -> AnyPublisher<CategoryModel, Error> {
        performRequest(path: "product_categories/\(categoryId).json", modelType: CategoryModel.self)
        //            .map { products in
        //                products.map { $0 }
        //            }
        //            .eraseToAnyPublisher()
    }
    
}

extension APIClient {
    public func filters() -> AnyPublisher<[SearchFilterModel], Error> {
        performRequest(path: "search/filters.json", modelType: [SearchFilterModel].self)
    }
}

extension APIClient {
    public func addFavoriteProduct(_ productId: Int) -> AnyPublisher<ProductModel, Error> {
        return performRequest(path: "users/add_favorite/\(productId)",method: .post, modelType: ProductModel.self)
    }
    
    public func removeFavoriteProduct(_ productId: Int) -> AnyPublisher<SimpleModel, Error> {
        return performRequest(path: "users/remove_favorite/\(productId)",method: .post, modelType: SimpleModel.self)
    }
}

extension APIClient {
    
    public func fetchCurrentSurvey() -> AnyPublisher<SurveyModel, Error> {
        return performRequest(path: "surveys", modelType: SurveyModel.self)
    }
    
    public func sendSurveyResponses(_ responses: SurveyResponses) -> AnyPublisher<SimpleModel, Error> {
        let body = try! JSONEncoder().encode(responses)

        return performRawRequest(path: "surveys", method: .post, body: body, accessToken: nil, modelType: SimpleModel.self, compressTextures: false)
    }
    
}

extension APIClient {
    public func appClipData(_ identifier: String) -> AnyPublisher<AppClipModel, Error> {
        return performRequest(path: "appclip/\(identifier).json", modelType: AppClipModel.self)
//        return performRawRequest(path: "appclip/\(identifier).json", method: .get, body: nil, accessToken: nil, modelType: AppClipModel.self, compressTextures: false)
    }
}

// MARK: - Models

public struct AppClipModel:Decodable {
    public var selectedProductId: Int?
    public var brand: BrandModel
    public var productCollections: [ProductCollectionModel]
}
public struct SimpleModel: Decodable {
    public var status: String
}

public struct UserModel: Decodable, Identifiable {
    public var id: Int
    public var name: String
    public var email: String
    public var siwa_token: String?
    public var session_token: String? //on create we'll return the session token.
    public var favorite_product_ids: [Int]?
    
    public init(){
        self.id = 0
        self.name = ""
        self.email = ""
        self.siwa_token = ""
        self.session_token = ""
    }
}

public struct FilterItem: Decodable, Hashable {
    public var id: Int
    public var name: String
    public var slug: String?
    public var isSelected: Bool
    
    public var searchTerm: String{
        return slug ?? name
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case slug = "slug"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int.self, forKey: .id) ?? -1
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? ""
        slug = try values.decodeIfPresent(String.self, forKey: .slug)
        isSelected = false
    }
}

public struct SearchFilterModel: Decodable, Hashable {
    public var name: String
    public var plural: String
    public var select_type: selectType
    
    public enum selectType: String, Codable {
        case multi
        case single
    }
    
    public var items: [FilterItem]?
    
    public var searchItemsQuery:String? {
        var itemArray:[String] = []
        items?.forEach{ item in
            if item.isSelected {
                itemArray.append(item.searchTerm.lowercased())
            }
        }
        if itemArray.count == 0 {
            return nil
        }
        
        return "\(itemArray.joined(separator: ","))"
    }
}

public struct BrandModel: Decodable, Identifiable {
    public var id: Int
    public var name: String
    public var slug: String
    public var bio: String
    public var logo: URL?
    public var splash: URL?
    public var shareUrl: String?
    public var featuredText: String
    public var featuredLinkTitle: String
    public var featuredLinkUrl: String
    public var featuredImageOne: URL?
    public var featuredImageTwo: URL?
    public var featuredImageThree: URL?
}

public struct CategoryModel: Decodable, Identifiable {
    public var id: Int
    public var name: String
    public var images: [URL]
    public var products: [ProductModel]

    //this function "flattens" all of the products in the category
    //that is, if there are variations, it removes them from the variant and makes them visible.
    //this is good for wanting to show ALL our products in a category.
    public func flattenedProducts() -> [ProductModel]{
        var flattened:[ProductModel] = []
        products.forEach{product in
            if product.productType == .product {
                flattened.append(product)
            }else{
                if let variations = product.variations {
                    variations.forEach{ variation in
                        flattened.append(variation)
                    }
                }
            }
            
        }
        return flattened
    }
    
}

public struct ProductModel: Decodable, Identifiable, Equatable {
    
    public enum ProductType: String, Codable{
        case product
        case productWithVariations
    }
    
    public var id: Int
    public var brandId: Int
    public var featuredProductImage: Int
    public var brandName: String
    public var brandSlug: String
    public var slug: String
    public var name: String
    public var productType: ProductType
    public var description: String
    public var purchaseLink: URL?
    public var featuredImageOne: URL?
    public var featuredImageTwo: URL?
    public var featuredImageThree: URL?
    public var material: MaterialModel
    public var variations: [ProductModel]?
    public var parentId: Int?
    public var productCategory: Int
    
    public var variationIndex:Int?
    public var variationName: String
    
    //if this id exists, we need to display the variation (with this id)'s
    //information, and use the this index as the selection index on tap.
    public var searchVariationId:Int?
    
    public var featuredImages: [URL] {
        [featuredImageOne, featuredImageTwo, featuredImageThree].compactMap { $0 }
    }
    
    public init(id: Int, material: MaterialModel, name: String){
        self.id = id
        brandId = -1
        featuredProductImage = 1
        brandName = "See more amazing products"
        brandSlug  = ""
        slug = ""
        self.name = name
        description = ""
        variationName = ""
        self.purchaseLink = nil
        featuredImageOne = nil
        featuredImageTwo = nil
        featuredImageThree = nil
        self.productType = .product
        self.material = material
        self.productCategory = -1
    }
}

public struct MaterialModel: Decodable, Identifiable, Hashable {
    public var id: Int
    public var usesBlending: Bool
    public var maxSize: TextureSize?
    public var tilingAnchor: Property.TilingAnchor
    public var diffuse: Property
    public var ambientOcclusion: Property
    public var normal: Property
    public var metalness: Property
    public var roughness: Property
    public var displacement: Property
    
    public init(){
        self.id = -1
        self.usesBlending = false
        self.maxSize = nil
        self.tilingAnchor = .center
        self.diffuse = .init()
        self.normal = .init()
        self.ambientOcclusion = .init()
        self.metalness = .init()
        self.roughness = .init()
        self.displacement = .init()
    }
    
    
    
}

extension MaterialModel {
    
    public struct Property: Decodable, Hashable {
        public var content: Content
        public var textureSize: TextureSize
        public var intensity: Double
        //        public var tilingAnchor: String
        public enum TilingAnchor: String, Codable{
            case center
            case topLeft
        }
        
        public init(){
            self.content = .color(Color.init(red: 0.5, green: 0.5, blue: 0.5))
            self.textureSize = .meters(width: 1, height: 1)
            self.intensity = 1
        }
        public init(from decoder: Decoder) throws {
            
            enum Key: String, CodingKey {
                case contentType
                case red
                case green
                case blue
                case alpha
                case textureUrl
                case textureSize
                case constant
                case intensity
            }
            
            enum ContentType: String, Codable {
                case inactive
                case texture
                case color
                case constant
            }
            
            let container = try decoder.container(keyedBy: Key.self)
            
            let contentType = try container.decode(ContentType.self, forKey: .contentType)
            
            
            let texture = try container.decodeIfPresent(URL.self, forKey: .textureUrl)
            
            let constant = try container.decode(Double.self, forKey: .constant)
            
            self.textureSize = try container.decode(TextureSize.self, forKey: .textureSize)
            self.intensity = try container.decode(Double.self, forKey: .intensity)
            
            switch contentType {
                case .inactive:
                    content = .inactive
                case .texture:
                    guard let texture = texture else {
                        content = .inactive
                        return
                    }
                    content = .texture(texture)
                case .color:
                    let red = try container.decode(Double.self, forKey: .red)
                    let green = try container.decode(Double.self, forKey: .green)
                    let blue = try container.decode(Double.self, forKey: .blue)
                    let alpha = try container.decode(Double.self, forKey: .alpha)
                    content = .color(Color(red: red, green: green, blue: blue, opacity: alpha))
                case .constant:
                    content = .constant(constant)
            }
            
        }
    }
    
}

extension MaterialModel.Property {
    
    public enum Content: Hashable {
        case inactive
        case texture(URL)
        case color(Color)
        case constant(Double)
    }
    
}

public struct ProductCollectionModel: Decodable, Identifiable {
    public var id: Int
    public var name: String
    public var description: String
    public var products: [ProductModel]?
}

public struct ProductCollectionItemModel: Decodable, Identifiable {
    public var id: Int
    public var product: ProductModel
}

public struct FeaturedProductModel: Decodable, Identifiable {
    public var id: Int
    public var product: ProductModel
}

public struct FeaturedProductCollectionModel: Decodable, Identifiable {
    public var id: Int
    public var productCollection: ProductCollectionModel
}

public struct SessionModel: Decodable, Hashable {
    public var token: String
}

// MARK: - Survey Model

public struct SurveyModel: Codable, Equatable {
    public var id: Int
    public var text: String
    public var questions: [SurveyQuestionModel]
    public var userId: String?
    
    public init() {
        self.id = -1
        self.text = ""
        self.questions = []
        self.userId = nil
    }
}

// MARK: - Answer Model

public struct SurveyAnswerModel: Codable, Equatable {
    public var text: String

    init() {
        self.text = ""
    }
    
    init(text: String) {
        self.text = text
    }
}

// MARK: - Question Model

public struct SurveyQuestionModel: Codable, Equatable {
    public var id: Int
    public var question: String
    public var options: [SurveyAnswerModel]
    public var type: SelectType

    public enum SelectType: String, Codable {
        case multi
        case single
        case text
    }
    
    init() {
        self.id = -1
        self.question = ""
        self.type = .single
        self.options = []
    }
    
    init(id: Int, question: String, options: [SurveyAnswerModel], type: SelectType) {
        self.id = id
        self.question = question
        self.type = type
        self.options = options
    }
}

// MARK: - Survey Response Models

public struct SurveyResponse: Encodable, Equatable {
    public var questionId: Int
    public var response: String
    
    enum CodingKeys: String, CodingKey {
        case questionId = "q_id"
        case response = "response"
    }
    
    public init() {
        self.questionId = -1
        self.response = ""
    }
    
    public init(questionId: Int = -1, response: String = "") {
        self.questionId = questionId
        self.response = response
    }
}

public struct SurveyResponses: Encodable, Equatable {
    public var surveyId: Int
    public var responses: [SurveyResponse]
    public var userId: String?
    var device: String
    var appVersion: String
    var systemVersion: String
    
    enum CodingKeys: String, CodingKey {
        case surveyId = "s_id"
        case responses = "responses"
        case userId = "user_id"
        case device = "device"
        case appVersion = "app_version"
        case systemVersion = "system_version"
    }
    
    public init() {
        self.surveyId = -1
        self.responses = []
        self.userId = nil
        self.device = UIDevice().type.rawValue
        self.appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "App Version Error"
        self.systemVersion = UIDevice.current.systemVersion
    }
}
