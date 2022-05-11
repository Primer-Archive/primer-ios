//
//  ButtonSignInWithApple.swift
//  Primer
//
//  Created by James Hall on 8/16/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import AuthenticationServices
import PrimerEngine
import Combine



struct ButtonSignInWithApple: UIViewRepresentable {
    @Environment(\EnvironmentValues.colorScheme) private var colorScheme
    @Environment(\.analytics) var analytics
    @Binding var isLoading: Bool
    var appState: Binding<AppState>
    var buttonType: ASAuthorizationAppleIDButton.ButtonType
    var client: APIClient
    var location: ViewLocation
    var onError: (Error) -> Void
    var completeSignupAction: (UserModel) -> Void
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State private var error: Error? = nil
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: self.buttonType, authorizationButtonStyle: self.colorScheme == .light ? .black : .white)
        
        
        button.addTarget(context.coordinator, action:  #selector(Coordinator.didTapButton), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        
    }
    
    public func login(credential: ASAuthorizationAppleIDCredential) {
        if let name = credential.fullName, let firstLetter = name.givenName, let lastName = name.familyName, let email = credential.email {
            self.isLoading = true
            self.analytics?.signUpTapped(.siwa, location: location)
            let fullName = "\(firstLetter) \(lastName)"
            let email = email
            self.client.registerSIWA(email: email , fullName: fullName, siwaId: credential.user)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        self.isLoading = false
                        switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                self.error = error
                                self.onError(error)
                        }
                    },
                    receiveValue: { user in
                        self.analytics?.signInMixpanelUser(user)
                        self.analytics?.createAccountComplete(.siwa, location: location)
                        AuthController.shared.didLogIn(user: user)
                        self.completeSignupAction(user)
                        self.saveLoggedOut(user: user)
                    })
                .store(in: &cancellables)
        } else {
            self.analytics?.signInTapped(.siwa)
            self.isLoading = true
            self.client.signInSIWA(siwaId: credential.user)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        self.isLoading = false
                        switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                self.error = error
                                self.onError(error)
                        }
                    },
                    receiveValue: { user in
                        self.analytics?.signInMixpanelUser(user)
                        self.analytics?.signInComplete(.siwa)
                        AuthController.shared.didLogIn(user: user)//, analytics: analytics, appState: appState)
                        self.saveLoggedOut(user: user)
                    })
                .store(in: &cancellables)
        }
    }
    
    public func saveLoggedOut(user: UserModel){
        
        guard let userClient = AuthController.shared.apiClient else {
            print("NO CLIENT")
            return
        }
        
        var favoriteIds = user.favorite_product_ids ?? []
        
        //1. let's sync up any previously saved favorites that might not exist on the server.
        appState.wrappedValue.favoriteProductIDs.forEach{ id in
            
            //we will check if the user already has the favorite in their list, if not, we will add it
            if !favoriteIds.contains(id) {
                userClient.addFavoriteProduct(id)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                                case .finished:
                                    break
                                case .failure(let error):
                                    print(error.localizedDescription)
                            }
                        },
                        receiveValue: { _ in
                            //we added it, so let's append it ot the favorite_products_ids
                            favoriteIds.append(id)
                        }
                    )
                    .store(in: &cancellables)
            }
        }
        
        
        appState.wrappedValue.favoriteProductIDs = favoriteIds
        
        //2. Let's now synch any items that may not have been set up logged in
        if let loggedOutFavorite = UserDefaults.loggedOutFavorite, !favoriteIds.contains(loggedOutFavorite) {
            
            userClient.addFavoriteProduct(loggedOutFavorite)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                print(error.localizedDescription)
                        }
                    },
                    receiveValue: { product in
                        analytics?.favoriteComplete(product)
                        UserDefaults.loggedOutFavorite = nil
                        appState.wrappedValue.favoriteProductIDs.append(loggedOutFavorite)
                    }
                ).store(in: &self.cancellables)
            
        }
        
    }
    
}

class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let parent: ButtonSignInWithApple?
    
    init(_ parent: ButtonSignInWithApple) {
        self.parent = parent
        super.init()
        
    }
    
    @objc func didTapButton() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.presentationContextProvider = self
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let vc = UIApplication.shared.windows.last?.rootViewController
        return (vc?.view.window!)!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credentials = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("credentials not found....")
            return
        }
        parent?.login(credential: credentials)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    }
}
