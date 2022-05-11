//
//  AboutListView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/26/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import Foundation
import MessageUI


struct AboutListView: View {
    @Environment(\.analytics) var analytics
    @Binding var presentLogout: Bool
    @Binding var tappedurl: URL?
    @State var isShowingEmail: Bool = false
    @State var isShowingURL: Bool = false
    
    var isLoggedIn: Bool

    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(isLoggedIn ? AboutSection.allCases.indices : AboutSection.allCases.filter({ $0 != .account}).indices, id: \.self) { index in
                let section: AboutSection = isLoggedIn ? AboutSection.allCases[index] : AboutSection.allCases.filter({ $0 != .account})[index]
                
                Section(header:
                    HStack {
                        LabelView(text: section.rawValue, style: .bodySemibold)
                            .padding(.horizontal, BrandPadding.Smedium.pixelWidth)
                            .padding(.top, BrandPadding.Large.pixelWidth)
                            .padding(.bottom, BrandPadding.Small.pixelWidth)
                        Spacer()
                }, content: {
                    ForEach(section.items.indices, id: \.self) { itemIndex in
                        let item = section.items[itemIndex]
            
                        VStack(spacing: 0) {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(BrandColors.softSandToggleNavy.color)
                                HStack {
                                    LabelView(text: item.rawValue, style: .bodyMedium)
                                        .padding(.leading, BrandPadding.Tiny.pixelWidth)
                                    Spacer()
                                    SmallSystemIcon(style: .rightChevron)
                                        .opacity(0.3)
                                }
                            }.padding(.horizontal, BrandPadding.Small.pixelWidth)
                        }
                        .onTapGesture {
                            if item == .signOut {
                                self.tappedurl = nil
                                self.presentLogout = true
                            } else if item == .appFeedback {
                                self.tappedurl = nil
                                self.displayEmailComposer()
                            } else {
                                self.tappedurl = item.url
                            }
                            
                            self.analytics?.didTapAboutItem(item)
                        }
                        .frame(height: 44)
                        .background(BrandColors.softSandToggleNavy.color)
                        
                        Divider()
                            .padding(.leading, BrandPadding.Smedium.pixelWidth)
                    }
                })
            }
            
            Image("twoPeopleIllustration")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(BrandPadding.Medium.pixelWidth)
                .frame(maxWidth: 350)
        }
        .navigationBarItems(trailing: EmptyView())
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        .background(BrandColors.backgroundView.color)
        .onChange(of: tappedurl, perform: { url in
            if url != nil {
                isShowingURL = true
            }
        })
        .sheet(isPresented: $isShowingURL, content: {
            if let url = tappedurl {
                FullScreenSafariView(url: url)
                .navigationBarItems(trailing: EmptyView())
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarHidden(true)
                .onDisappear {
                    isShowingURL = false
                    tappedurl = nil
                }
            }
        })
    }
    
    // MARK: - Email Helper
    
    func displayEmailComposer() {
        if MFMailComposeViewController.canSendMail() {
            let vc = PrimerEmailHelperVC()
            vc.setupPrimerEmail(subject: "User Feedback", body: "Hi Primer team,\n\n(Describe your feedback or issue here. Screenshots or screen recordings showing the issue help too!)")
            vc.mailComposeDelegate = vc
            
            let scene = UIApplication.shared.connectedScenes.first as! UIWindowScene
            var presentingViewController = scene.windows.first!.rootViewController!
            presentingViewController.modalPresentationStyle = .fullScreen

            if let popoverController = vc.popoverPresentationController {
                popoverController.sourceView = presentingViewController.view //to set the source of your alert
                popoverController.sourceRect = CGRect(x: presentingViewController.view.bounds.midX, y: presentingViewController.view.bounds.midY, width: 0, height: 0) // you can set this as per your requirement.
            }

            while let presented = presentingViewController.presentedViewController {
                presentingViewController = presented
            }
            isShowingEmail = true
            presentingViewController.present(vc, animated: true, completion: nil)
        } else {
            print("Device not setup for Mail")
        }
    }
    
}

// MARK: - Preview

struct AboutListView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            AboutListView(presentLogout: .constant(false), tappedurl: .constant(nil), isLoggedIn: false)
        }.edgesIgnoringSafeArea(.bottom)
    }
}

