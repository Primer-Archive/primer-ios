////
////  ProfileView.swift
////  Primer
////
////  Created by James Hall on 8/14/20.
////  Copyright © 2020 Primer Inc. All rights reserved.
////
//
//import SwiftUI
//import PrimerEngine
//
//struct ProfileView: View {
//    var appState: Binding<AppState>
//    var client: APIClient
//
//    @State var showRegisterView:Bool = false
//
//    @ObservedObject private var authController = AuthController.shared
//
//    @Environment(\.analytics) var analytics
//
//    var body: some View {
//        NavigationView {
//            GeometryReader { proxy in
//                VStack{
//                    if self.authController.isLoggedIn {
//                        Text("logged in!")
//
//                        Button(action:{
//                            withAnimation {
//                                self.authController.logOut()
//                                self.appState.wrappedValue.favoriteProductIDs = []
//                                UserDefaults.favoriteProductIDs = []
//                            }
//
//                        }){
//                            Text("Log Out")
//                        }
//                    }else{
//                        if !self.showRegisterView {
//                            AuthView(appState: self.appState,client: self.client, showRegisterView: self.$showRegisterView )
//                        }else{
//                            RegisterView(appState: self.appState,
//                                         client:self.client)
//                        }
//
//                    }
//
//                }
//
//            }
//        }
//    }
//}
////
//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileView(appState: .constant(.initialState), client: APIClient(accessToken: "asdf"))
//    }
//}
