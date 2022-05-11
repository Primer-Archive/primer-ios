//
//  AboutPageView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/26/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine
import Combine


struct AboutPageView: View {
    @Environment(\.analytics) var analytics
    @Environment(\.presentationMode) var presentationMode
    @State private var presentNewsletterSignup = false
    @State private var isPresented = false
    @State var activeURL: URL?

    var appState: Binding<AppState>
    var client: APIClient
    var signupText: String = "Create an account to start favoriting."
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                ScrollView(.vertical) {
                    VStack(spacing: BrandPadding.Medium.pixelWidth) {
                        
                        // if newsletter signup is presented from within logged out options, dont switch off of that view until it's dismissed
                        if !AuthController.shared.isLoggedIn || presentNewsletterSignup {
                            LoggedOutOptionsView(presentNewsletterSignup: $presentNewsletterSignup, appState: appState, client: client, location: .aboutTab, isCompact: true, proxy: proxy, mainText: signupText).analytics(analytics)
                                .overlay(CustomHeaderView(leadingIcon: .x12, text: "", leadingBtnAction: {
                                    presentationMode.wrappedValue.dismiss()
                                }), alignment: .topLeading)
                            
                            AboutListView(presentLogout: self.$isPresented, tappedurl: $activeURL, isLoggedIn: false)
                                .padding(.bottom, BrandPadding.Large.pixelWidth)
                                .padding(.top, AuthController.shared.isLoggedIn ? 60 : 0)
                                .overlay(headerOverlay, alignment: .topLeading).analytics(analytics)
                        } else {
                            AboutListView(presentLogout: self.$isPresented, tappedurl: $activeURL, isLoggedIn: true)
                                .padding(.bottom, BrandPadding.Large.pixelWidth)
                                .padding(.top, AuthController.shared.isLoggedIn ? 60 : 0)
                                .overlay(headerOverlay, alignment: .topLeading).analytics(analytics)
                        }
                    }
                }
            }.navigationBarItems(trailing: EmptyView())
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
            .background(BrandColors.backgroundView.color)
            .edgesIgnoringSafeArea(.bottom)
            
            // MARK: - Log Out popover
        }.actionSheet(isPresented: self.$isPresented) {
            ActionSheet(title: Text("Log Out"),
                message: Text("Do you want to log out? This will remove all of your favorites until you login again."),
                buttons: [
                    .destructive(Text("Log Out"), action: {
                        self.analytics?.didLogOut()
                        self.analytics?.signOutMixpanelUser()
                        AuthController.shared.logOut()
                        self.appState.wrappedValue.favoriteProductIDs = []
                        UserDefaults.favoriteProductIDs = []
                    }),
                    .default(Text("Cancel"), action: {
                        self.analytics?.didCancelLogout()
                    })
                ])
        }
        
        .onAppear {
            self.analytics?.didStartAboutView()
        }
        .onDisappear{
            self.analytics?.didEndAboutView()
        }
    }
    
    var headerOverlay: some View {
        CustomHeaderView(leadingIcon: .x12, text: "", leadingBtnAction: {
            presentationMode.wrappedValue.dismiss()
        }) .opacity(AuthController.shared.isLoggedIn ? 1 : 0)
    }
}

// MARK: - Preview

struct AboutPageView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            AboutPageView(appState: .constant(.initialState), client: APIClient.init())
        }
    }
}
