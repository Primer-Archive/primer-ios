//
//  LoggedOutOptionsView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/28/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine
import Combine

struct LoggedOutOptionsView: View {
    @Environment(\.analytics) var analytics
    @Binding var presentNewsletterSignup: Bool
    @State private var cancellable: AnyCancellable? = nil
    @State var isLoadingSIWA: Bool = false
    @State private var presentSignIn = false
    @State private var presentRegister = false

    @State var isLoadingNewsletter: Bool = false
    @State var newsletterUserId: String = ""
    @State var newsletterEmail: String = ""
    @State var selectedIntent: Persona = .unselected
    @State var optInSubscription: Bool = true
    
    var appState: Binding<AppState>
    var client: APIClient
    var location: ViewLocation
    var isCompact: Bool = false
    var proxy: GeometryProxy
    var mainText: String
    
    public var videoURL: URL? {
        return URL(string: isDeviceIpad() ? Video.remoteIpadFavoriting.rawValue : Video.remoteIphoneFavoriting.rawValue)
    }
    
    var body: some View {
        VStack(spacing: BrandPadding.Smedium.pixelWidth) {
            VideoPlayerView(
                fileURL: videoURL,
                frameSize: CGSize(width: proxy.size.width, height: isDeviceIpad() ? (proxy.size.height * 0.47) : (proxy.size.height * 0.4)))
                .aspectRatio(contentMode: .fit)
                .background(BrandColors.navy.color)
                
            VStack(spacing: BrandPadding.Smedium.pixelWidth) {
                HStack(spacing: 0) {
                    LabelView(text: "Collect your favorites to cycle through them quickly.", style: .nuxTitleLeading)
                        .frame(height: 60)
                    Spacer()
                }
                HStack(spacing: 0) {
                    LabelView(text: mainText, style: .nuxDescriptionLeading)
                    Spacer()
                }
            }
            .padding(.horizontal, BrandPadding.Large.pixelWidth)
            .frame(maxWidth: isDeviceIpad() ? 380 : .infinity)
            
            ButtonSignInWithApple(isLoading: $isLoadingSIWA,
                appState: appState,
                buttonType: .signIn, client: self.client, location: location) { error in
                    print("login error: \(error) - \(error.localizedDescription)")
                } completeSignupAction: { user in
                displayNewsletterPrompt(for: user)
            }.analytics(self.analytics)
                .frame(height: 52)
                .cornerRadius(10)
                .padding(.horizontal, BrandPadding.Large.pixelWidth)
                .frame(maxWidth: isDeviceIpad() ? 380 : .infinity)
            #if !APPCLIP
            
            ZStack {
                NavigationLink(
                    destination: RegisterView(appState: self.appState, client: self.client, location: location).analytics(self.analytics),
                    isActive: $presentRegister) { EmptyView() }
                
                Button("Create account with email") {
                    self.analytics?.didTapCreateAccountNav(from: location)
                    self.presentRegister = true
                }
                .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue, font: LabelStyle.lightModeMedium.font, height: 52.0, cornerRadius: 10))
            }.padding(.horizontal, BrandPadding.Large.pixelWidth)
            .frame(maxWidth: isDeviceIpad() ? 380 : .infinity)
            
            ZStack {
                NavigationLink(
                    destination: SignInView(appState: self.appState, client: self.client).analytics(self.analytics),
                    isActive: $presentSignIn) { EmptyView() }

                ButtonWithText(btnText: "Sign in with email", labelStyle: .buttonSemibold) {
                    self.analytics?.didTapSIWEmailNav()
                    self.presentSignIn = true
                }
            }
            .frame(maxWidth: .infinity)
            #endif
        }.sheet(isPresented: $presentNewsletterSignup) {
            NewsletterView(email: $newsletterEmail, persona: $selectedIntent, isSubscribed: $optInSubscription, isLoading: $isLoadingNewsletter, completeAction: {
                submitNewsletterPreferences(for: "\(newsletterUserId)")
            }).analytics(analytics)
        }
    }
    
    // MARK: - Newsletter popover
    
    func displayNewsletterPrompt(for user: UserModel) {
        newsletterEmail = user.email
        newsletterUserId = "\(user.id)"
        presentNewsletterSignup = true
    }
    
    func submitNewsletterPreferences(for userId: String) {
        guard userId != "" else {
            print("invalid user for submitting newsletter preferences")
            return
        }
        
        isLoadingNewsletter = true
        cancellable = self.client
            .updateIntentAndNewsletter(userid: userId, intent: selectedIntent.parsingFriendly, subscribe: optInSubscription)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingNewsletter = false
                    self.cancellable = nil
                    switch completion {
                        case .finished:
                            presentNewsletterSignup = false
                            break
                        case .failure(let error):
                            print("newsletter pref error: \(error)")
                    }
            }, receiveValue: { user in
                    isLoadingNewsletter = false
                    analytics?.didGiveIntent(intent: selectedIntent.rawValue)
                    if optInSubscription {
                        analytics?.subscribedToNewsletter(from: .siwa, location: location)
                    }
            })
    }
}

struct LoggedOutOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { proxy in
            LoggedOutOptionsView(presentNewsletterSignup: .constant(false), appState: .constant(.initialState), client: APIClient(), location: .favoritesDrawer, proxy: proxy, mainText: "Label label")
        }
    }
}
