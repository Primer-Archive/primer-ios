import SwiftUI
import Combine
import PrimerEngine

private let key = "access-token"
private let siwaKey = "siwa-token"

final class AuthController: ObservableObject {
    
    private enum Status {
        case loggedOut
        case loggedIn(APIClient)
    }
    
    static let shared = AuthController()
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @Published private var status: Status
    
    private init() {
        if let token = UserDefaults.accessToken {
            status = .loggedIn(APIClient(accessToken: token))
        } else {
            status = .loggedOut
        }
    }
    
    var isLoggedIn: Bool {
        apiClient != nil
    }
    
    var currentUser: UserModel?
    
    var siwaToken: String? {
        return UserDefaults.siwaKey
    }
    
    var apiClient: APIClient? {
        switch status {
            case .loggedOut: return nil
            case .loggedIn(let client): return client
        }
    }
    
    
    func didLogIn(user: UserModel) {
        if let accessToken = user.session_token {
            guard accessToken != apiClient?.accessToken else { return }
            status = .loggedIn(APIClient(accessToken: accessToken))
            UserDefaults.accessToken = accessToken
            if let siwa = user.siwa_token {
                UserDefaults.siwaKey = siwa
            }
        }
    }
    
    
    func logOut() {
        status = .loggedOut
        UserDefaults.accessToken = nil
        UserDefaults.siwaKey = nil
    }
    
}
