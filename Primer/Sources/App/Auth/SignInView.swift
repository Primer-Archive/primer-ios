//
//  SignInView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 9/18/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import Combine
import PrimerEngine

struct SignInView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.analytics) var analytics
    
    @State private var showSafari = false
    @State private var cancellable: AnyCancellable? = nil
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var error: Error? = nil
    @State private var showingAlert: Bool = false
    
    @State private var email = ""
    @State private var password = ""
    @State var alertHeader: String = ""
    @State var alertText: String = ""
    
    var appState: Binding<AppState>
    var client: APIClient
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            BackgroundView()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                CustomHeaderView(leadingIcon: .arrowLeft, text: "Sign In", leadingBtnAction: {
                    self.analytics?.didTapToExitSignIn()
                    presentationMode.wrappedValue.dismiss()
                })
                
                Spacer()
                VStack(spacing: BrandPadding.Smedium.pixelWidth) {
                    TextField("email address", text: $email)
                        .modifier(TextFieldModifier(keyboardType: .emailAddress, textContentType: .username))
                    
                    SecureField("password", text: $password)
                        .modifier(TextFieldModifier(keyboardType: .default, textContentType: .password))
                    
                    Button("Sign In") {
                        self.analytics?.signInTapped(.email)
                        login()
                    }
                    
                    .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue, font: LabelStyle.buttonSemibold.font, height: 52.0, cornerRadius: 10))
                    .padding(.top, BrandPadding.Smedium.pixelWidth)

                    ButtonWithText(btnText: "Forgot password", labelStyle: .buttonSemibold) {
                        self.analytics?.didTapForgotPW()
                        self.showSafari = true
                    }
                }.padding(.leading, BrandPadding.Smedium.pixelWidth)
                .padding(.trailing, BrandPadding.Smedium.pixelWidth)
                
                .frame(maxWidth:380)
                
                // MARK: - Alert
                
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Error Signing In"),
                        message: Text(self.alertText),
                        dismissButton: .default(Text("OK")){
                            print("ok")
                        }
                    )
                }
                .disabled(cancellable != nil)
                .overlay(ActivityIndicatorView().opacity(cancellable != nil ? 1.0 : 0.0))
                Spacer()
            }
        }
        .navigationBarHidden(true)
        
        // MARK: - Forgot PW Nav
        .fullScreenCover(isPresented: $showSafari, content: {
            let url = URL(string: "\(ENV.appURL)password/forgot-password")!
            FullScreenSafariView(url: url)
        })
    }
    
    // MARK: - Login
    
    private func login() {
        cancellable = self.client
            .login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.cancellable = nil
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.error = error

                        if let data = self.client.lastError {
                            self.alertHeader = "Error logging in"
                            self.alertText = self.convertErrorText(data)
                        }
                        self.showingAlert.toggle()

                    }
                },
                receiveValue: { user in
                    AuthController.shared.didLogIn(user: user)
                    self.analytics?.signInMixpanelUser(user)
                    self.analytics?.signInComplete(.email)
                    self.appState.wrappedValue.currentUser = user
                    presentationMode.wrappedValue.dismiss()
                    self.saveLoggedOut(user: user)
                })
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

// MARK: - Preview

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(appState: .constant(.initialState), client: APIClient(accessToken: ""))
    }
}
