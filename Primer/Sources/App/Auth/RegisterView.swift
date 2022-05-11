import SwiftUI
import Combine
import PrimerEngine


struct RegisterView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.analytics) var analytics
    
    var appState: Binding<AppState>
    var client: APIClient
    var location: ViewLocation

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var persona = Persona.unselected
    
    @State private var cancellable: AnyCancellable? = nil
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var error: Error? = nil
    @State var errorText: String = ""
    @State private var showingAlert: Bool = false
    @State var isSubscribed = true
    
    @State private var isPWErrorState = false
    @State private var isPersonaErrorState = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            BackgroundView()
                .edgesIgnoringSafeArea(.all)
            
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    CustomHeaderView(leadingIcon: .arrowLeft, text: "Create Account", leadingBtnAction: {
                        self.analytics?.didTapToExitAccountCreation()
                        presentationMode.wrappedValue.dismiss()
                    })
                    
                    VStack {
                        HStack {
                            LabelView(text: "Your Login", style: .inputHeader)
                                .padding(.leading, BrandPadding.Small.pixelWidth)
                                .padding(.bottom, BrandPadding.Tiny.pixelWidth)
                            Spacer()
                        }
                            
                        TextField("email address", text: $email)
                            .modifier(TextFieldModifier(keyboardType: .emailAddress, textContentType: .username))
                            .padding(.bottom, BrandPadding.Smedium.pixelWidth)
                        
                        SecureField("password", text: $password)
                            .modifier(TextFieldModifier(keyboardType: .default, textContentType: .newPassword))
                            .overlay(RoundedRectangle(cornerRadius: 10) .stroke(BrandColors.orangeTogglePink.color, lineWidth: $isPWErrorState.wrappedValue ? 2 : 0))
                            .padding(.bottom, BrandPadding.Medium.pixelWidth)

                        HStack {
                            LabelView(text: "Account Details", style: .inputHeader)
                                .padding(.leading, BrandPadding.Small.pixelWidth)
                                .padding(.bottom, BrandPadding.Tiny.pixelWidth)
                            Spacer()
                        }
                            
                        TextField("Full name", text: $name)
                            .modifier(TextFieldModifier(keyboardType: .default, textContentType: .name))
                            .padding(.bottom, BrandPadding.Smedium.pixelWidth)

                        PersonaMenuView(currentSelection: $persona)
                            .overlay(RoundedRectangle(cornerRadius: 10) .stroke(BrandColors.orangeTogglePink.color, lineWidth: $isPersonaErrorState.wrappedValue ? 2 : 0))
                            .padding(.bottom, BrandPadding.Smedium.pixelWidth)
                        
                        HStack(spacing: BrandPadding.Small.pixelWidth) {
                            CheckboxButton(isSelected: $isSubscribed) {
                                if isSubscribed {
                                    isSubscribed = false
                                } else {
                                    isSubscribed = true
                                }
                            }

                            LabelView(text: "Keep me up to date with the Primer newsletter", style: .subtitle)
                                .frame(maxWidth: .infinity)
                        }
                        
                        Button("Create account") {
                            self.analytics?.didTapCreateAccount(from: location)
                            createAccount()
                        }
                        .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue, font: LabelStyle.buttonSemibold.font, height: 52.0, cornerRadius: 10))
                        .padding(.top, BrandPadding.Medium.pixelWidth)

                        VideoPlayerView(fileURL: Bundle.main.url(forResource: "c3", withExtension: "mov")!, frameSize: CGSize(width: 320, height: 240))
                            .aspectRatio(contentMode: .fit)
                            .padding(.top, BrandPadding.Medium.pixelWidth)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .opacity(0.33)
                    }.padding(.horizontal, BrandPadding.Large.pixelWidth)
                    
                    .frame(maxWidth:380)
                }
            }
            
            //MARK: - Alert
            
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error Signing Up"),
                    message: Text(self.errorText),
                    dismissButton: .default(Text("OK")){
                        print("ok")
                    }
                )
            }
            .disabled(cancellable != nil)
            .overlay(ActivityIndicatorView().opacity(cancellable != nil ? 1.0 : 0.0))
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Create Account
    
    private func createAccount() {
        if password.count < 8 {
            self.errorText = "Passwords need to be at least 8 characters."
            self.isPWErrorState = true
            self.showingAlert = true
            return
        } else if persona == .unselected {
            self.errorText = "Please select your user type."
            self.isPersonaErrorState = true
            self.isPWErrorState = false
            self.showingAlert = true
            return
        } else {
            self.isPWErrorState = false
            self.isPersonaErrorState = false
        }
        
        
        cancellable = self.client
            .register(name: name, email: email, password: password, persona: persona.parsingFriendly, subscribe: isSubscribed)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.cancellable = nil
                    switch completion {
                        case .finished:
                            self.analytics?.createAccountComplete(.email, location: location)
                            self.analytics?.didGiveIntent(intent: persona.rawValue)
                            break
                        case .failure(let error):
                            self.error = error

                            if let data = self.client.lastError {
                                self.errorText = self.convertErrorText(data)
                            }
                            self.showingAlert.toggle()
                    }
            },
                receiveValue: { user in
                    self.appState.wrappedValue.currentUser = user
                    self.analytics?.signInMixpanelUser(user)
                    if isSubscribed {
                        analytics?.subscribedToNewsletter(from: .email, location: location)
                    }
                    AuthController.shared.didLogIn(user: user)
                    self.saveLoggedOut(user: user)
                    presentationMode.wrappedValue.dismiss()
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

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(appState: .constant(.initialState), client: APIClient(accessToken: ""), location: .favoritesDrawer)
        
        // uncomment for dark mode
//            .environment(\.colorScheme, .dark)
    }
}



