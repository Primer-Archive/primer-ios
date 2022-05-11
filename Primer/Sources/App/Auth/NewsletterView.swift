//
//  NewsletterView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/4/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 Full sheet view to allow user the option to opt in to newsletter and select intent, displays after signing up with Apple
 */
struct NewsletterView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.analytics) var analytics
    @Binding var email: String
    @Binding var persona: Persona
    @Binding var isSubscribed: Bool
    @Binding var isLoading: Bool
    var completeAction: () -> Void
    
    var body: some View {
        VStack {
            CustomHeaderView(leadingIcon: .x12, text: "Create Account", leadingBtnAction: {
                presentationMode.wrappedValue.dismiss()
            })
            
            ScrollView(.vertical) {
                
                Spacer()
                    .frame(minHeight: 30, maxHeight: 70)
                
                VStack(spacing: BrandPadding.Smedium.pixelWidth) {

                    HStack {
                        LabelView(text: "Account Details", style: .inputHeader)
                            .padding(.leading, BrandPadding.Small.pixelWidth)
                        Spacer()
                    }
                        
                    PersonaMenuView(currentSelection: $persona)
                        .padding(.bottom, BrandPadding.Small.pixelWidth)
                    
                    InactiveTextfieldView(text: email)
                        .padding(.bottom, BrandPadding.Small.pixelWidth)
                    
                    HStack(spacing: BrandPadding.Small.pixelWidth) {
                        CheckboxButton(isSelected: $isSubscribed) {
                            handleNewsletterSelection()
                        }

                        LabelView(text: "Keep me up to date with the Primer newsletter", style: .subtitle)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Button("Complete sign up") {
                        completeAction()
                    }
                    .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue, font: LabelStyle.buttonSemibold.font, height: 52.0, cornerRadius: 10))
                    .padding(.top, BrandPadding.Large.pixelWidth)

                    Image("HandheldDeviceIllustration")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 320, height: 240)
                        .padding(.top, 55)
                    Spacer()
                        .frame(minHeight: 20)
                }.padding(.horizontal, BrandPadding.Large.pixelWidth)
                .frame(maxWidth: 380)
            }.overlay(
            ActivityIndicatorView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(isLoading ? 1 : 0)
            )
        }.background(BrandColors.backgroundView.color)
        .edgesIgnoringSafeArea(.bottom)
    }
    
    func handleNewsletterSelection() {
        if isSubscribed {
            isSubscribed = false
        } else {
            isSubscribed = true
        }
    }
}

struct NewsletterView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            ScrollView(.vertical) {
                NewsletterView(email: .constant("email@emailtown.com"), persona: .constant(Persona.unselected), isSubscribed: .constant(true), isLoading: .constant(false), completeAction: {})
            }
        }
    }
}
