import SwiftUI
import Combine
import PrimerEngine


struct AuthView: View {
    var appState: Binding<AppState>
    var client:APIClient
    
    @State private var email = "tim@tdonnelly.com"
    @State private var password = "test"
    
    @State private var cancellable: AnyCancellable? = nil
    @State private var error: Error? = nil
    
     @State var name : String = ""

    var body: some View {
        Form {
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            SecureField("Password", text: $password)
            
            Button(action: login) {
                Text("Log in")
            }
            
            Text("or")
            
            ButtonSignInWithApple(client: client)
                .frame(maxWidth:350, maxHeight:50)
        }
        .disabled(cancellable != nil)
        .overlay(ActivityIndicatorView().opacity(cancellable != nil ? 1.0 : 0.0))
    }
    
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
                    }
                },
                receiveValue: { session in
                    AuthController.shared.didLogIn(accessToken: session.token, siwaToken: nil)
                })
    }
    
}


//struct AuthView_Previews: PreviewProvider {
//    static var previews: some View {
//        AuthView()
//    }
//}



