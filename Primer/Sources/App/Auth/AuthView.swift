//import SwiftUI
//import Combine
//import PrimerEngine
//
//
//struct AuthView: View {
//    @Environment(\.analytics) var analytics
//    var appState: Binding<AppState>
//    var client:APIClient
//    var showRegisterView: Binding<Bool>
//
//    @State private var viewForgotPassword: Bool = false
//
//    @State private var email = ""
//    @State private var password = ""
//
//    @State private var cancellable: AnyCancellable? = nil
//    @State private var cancellables: Set<AnyCancellable> = []
//    @State private var error: Error? = nil
//
//    @State var alertHeader:String = ""
//    @State var alertText:String = ""
//
//    @State private var showingAlert: Bool = false
//    @State private var isLoading: Bool = false
//
//    var body: some View {
//        ZStack{
//
////            BackgroundView()
////                .edgesIgnoringSafeArea(.all)
//
//            if viewForgotPassword {
//                AnyView(self.forgotView())
//            } else {
//                AnyView(self.logInView())
//            }
////            Color.red
//        }
//        .alert(isPresented: $showingAlert) {
//            Alert(
//                title: Text(self.alertHeader),
//                message: Text(self.alertText),
//                dismissButton: .default(Text("OK")){
//                    print("ok")
//                }
//            )
//        }
//    }
//
//    private func forgotView() -> some View {
//        Form {
//            TextField("Email", text: $email)
//                .autocapitalization(.none)
//                .disableAutocorrection(true)
//
//            Button(action: resetPassword) {
//                Text("Reset my password")
//            }
//
//
//            Button(action: {
//                self.viewForgotPassword.toggle()
//            }){
//                Text("Return to Log In")
//            }
//        }
//        .disabled(cancellable != nil)
//        .overlay(ActivityIndicatorView().opacity(cancellable != nil ? 1.0 : 0.0))
//    }
//
//    private func logInView() -> some View {
//        Form {
//            TextField("Email", text: $email)
//                .autocapitalization(.none)
//                .disableAutocorrection(true)
//
//            SecureField("Password", text: $password)
//
//            Button(action: login) {
//                Text("Log in")
//            }
//
//            Text("or")
//
//            ButtonSignInWithApple(isLoading: $isLoading, appState: appState, buttonType: .signIn, client: client) { error in
//
//                self.error = error
//                self.alertHeader = "Error logging in"
//                if let data = self.client.lastError {
//                    self.alertText = self.convertErrorText(data)
//                }
//                self.showingAlert.toggle()
//            } completeSignupAction: {_ in }
//            .frame(maxWidth:350, maxHeight:48)
//            .cornerRadius(100)
//
//            Button(action: {
//                self.showRegisterView.wrappedValue = true
//            }){
//                Text("Register Today")
//            }
//
//            Button(action: {
//                self.viewForgotPassword.toggle()
//            }){
//                Text("Forgot Password?")
//            }
//        }
//        .disabled(cancellable != nil)
//        .overlay(ActivityIndicatorView().opacity(cancellable != nil ? 1.0 : 0.0))
//    }
//    private func resetPassword() {
//        cancellable = self.client
//            .forgotPassword(email: email)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { completion in
//                    self.cancellable = nil
//                    switch completion {
//                        case .finished:
//                            break
//                        case .failure(let error):
//                            self.error = error
//
//                            if let data = self.client.lastError {
//                                self.alertHeader = "Error resetting password"
//                                self.alertText = self.convertErrorText(data)
//                            }
//                            self.showingAlert.toggle()
//
//                    }
//            },
//                receiveValue: { session in
//                    self.viewForgotPassword.toggle()
//                    self.alertHeader = "Success"
//                    self.alertText = "Reset email has been sent."
//                    self.showingAlert.toggle()
//            })
//    }
//    private func login() {
//        cancellable = self.client
//            .login(email: email, password: password)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { completion in
//                    self.cancellable = nil
//                    switch completion {
//                    case .finished:
//                        break
//                    case .failure(let error):
//                        self.error = error
//
//                        if let data = self.client.lastError {
//                            self.alertHeader = "Error logging in"
//                            self.alertText = self.convertErrorText(data)
//                        }
//                        self.showingAlert.toggle()
//
//                    }
//                },
//                receiveValue: { user in
//                    AuthController.shared.didLogIn(user: user)
//                    self.saveLoggedOut(user: user)
//                })
//    }
//
//    public func saveLoggedOut(user: UserModel){
//
//        guard let userClient = AuthController.shared.apiClient else {
//            print("NO CLIENT")
//            return
//        }
//
//        var favoriteIds = user.favorite_product_ids ?? []
//
//        //1. let's sync up any previously saved favorites that might not exist on the server.
//        appState.wrappedValue.favoriteProductIDs.forEach{ id in
//
//            //we will check if the user already has the favorite in their list, if not, we will add it
//            if !favoriteIds.contains(id) {
//                userClient.addFavoriteProduct(id)
//                    .receive(on: DispatchQueue.main)
//                    .sink(
//                        receiveCompletion: { completion in
//                            switch completion {
//                                case .finished:
//                                    break
//                                case .failure(let error):
//                                    print(error.localizedDescription)
//                            }
//                        },
//                        receiveValue: { _ in
//                            //we added it, so let's append it ot the favorite_products_ids
//                            favoriteIds.append(id)
//                        }
//                    )
//                    .store(in: &cancellables)
//            }
//        }
//
//
//        appState.wrappedValue.favoriteProductIDs = favoriteIds
//
//        //2. Let's now synch any items that may not have been set up logged in
//        if let loggedOutFavorite = UserDefaults.loggedOutFavorite, !favoriteIds.contains(loggedOutFavorite) {
//
//            userClient.addFavoriteProduct(loggedOutFavorite)
//                .receive(on: DispatchQueue.main)
//                .sink(
//                    receiveCompletion: { completion in
//                        switch completion {
//                            case .finished:
//                                break
//                            case .failure(let error):
//                                print(error.localizedDescription)
//                        }
//                    },
//                    receiveValue: { product in
//                        analytics?.favoriteComplete(product)
//                        UserDefaults.loggedOutFavorite = nil
//                        appState.wrappedValue.favoriteProductIDs.append(loggedOutFavorite)
//                    }
//                ).store(in: &self.cancellables)
//
//        }
//
//    }
//
//}
//
//
////struct AuthView_Previews: PreviewProvider {
////    static var previews: some View {
////        AuthView()
////    }
////}
//
//
//
