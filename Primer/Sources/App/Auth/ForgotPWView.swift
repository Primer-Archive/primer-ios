//
//  ForgotPWView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 9/23/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import Combine
import PrimerEngine

struct ForgotPWView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var isVisible: Bool
    
    @State private var cancellable: AnyCancellable? = nil
    @State private var error: Error? = nil
    @State private var showingAlert: Bool = false
    
    @State private var email = ""
    
    @State var errorText = ""
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
                CustomHeaderView(leadingIcon: .arrowLeft, text: "Password Reset", leadingBtnAction: {
                    presentationMode.wrappedValue.dismiss()
                }).padding(.leading, BrandPadding.Small.pixelWidth)
                .padding(.trailing, BrandPadding.Small.pixelWidth)
                
                Spacer()
                VStack(spacing: BrandPadding.Smedium.pixelWidth) {
                    TextField("email address", text: $email)
                        .modifier(TextFieldModifier(keyboardType: .emailAddress, textContentType: .username))
                    
                    Button("Reset password") {
                        resetPassword()
                    }
                        .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue, font: LabelStyle.buttonSemibold.font, height: 52.0, cornerRadius: 10))
                        .padding(.top, BrandPadding.Smedium.pixelWidth)
                    
                    ButtonWithText(btnText: "Return to Log In ", labelStyle: .buttonSemibold) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.isVisible.toggle()
                        }
                    }
                }
                
                // MARK: - Alert
                
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Error Resetting"),
                        message: Text(self.errorText),
                        dismissButton: .default(Text("OK")){
                            print("ok")
                        }
                    )
                }
                .disabled(cancellable != nil)
                .overlay(ActivityIndicatorView().opacity(cancellable != nil ? 1.0 : 0.0))
                .frame(maxWidth:340)
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Reset PW
    
    private func resetPassword() {
        cancellable = self.client
            .forgotPassword(email: email)
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
                                self.alertHeader = "Error resetting password"
                                self.alertText = self.convertErrorText(data)
                            }
                            self.showingAlert.toggle()
                        
                    }
            },
                receiveValue: { session in
                    self.isVisible.toggle()
                    self.alertHeader = "Success"
                    self.alertText = "Reset email has been sent."
                    self.showingAlert.toggle()
            })
    }
    
}

struct ForgotPWView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPWView(isVisible: .constant(true), appState: .constant(.initialState), client: APIClient(accessToken: ""))
    }
}
