//
//  AltIconModalView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/20/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI


// MARK: - Icon Modal

struct AltIconModalView: View {
    @Environment(\.analytics) var analytics
    var header: String
    var btnAction: () -> Void = {}
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            CustomHeaderView(leadingIcon: .x12, text: header, leadingBtnAction: btnAction)
            ScrollView {
                VStack {
                    AppIconGridView().analytics(self.analytics)
                        .padding(.horizontal, BrandPadding.Medium.pixelWidth)
                    LabelView(text: "Want to change the app icon? Tap on a color you like and swap it out.", style: .bodyRegular)
                        .padding(BrandPadding.Medium.pixelWidth)
                    Image("workingAtKiln")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, BrandPadding.Medium.pixelWidth)
                }.padding(.horizontal, BrandPadding.Medium.pixelWidth)
                .frame(maxWidth: 450)
            }
        }
    }
}

// MARK: - Icon Grid

struct AppIconGridView: View {
    @Environment(\.analytics) var analytics
    @State var shouldUpdateBorder: Bool = false // current workaround to trigger refresh on border update
    private var gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    private var appManager: AppIconManager = AppIconManager()
    
    // MARK: - Body
    
    var body: some View {
        LazyVGrid(columns: gridItems) {
            // Only iterate through icons that have a name (default will be represented as nil)
            ForEach(PrimerAppIcon.allCases.filter( { $0.name != nil }), id: \.self) { item in
                Button(action: {
                    analytics?.didTapAlternateIcon(item.name ?? "")
                    appManager.setIcon(item)
                    shouldUpdateBorder.toggle()
                }) {
                    Image(item.name ?? "")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                            .stroke(shouldUpdateBorder ? BrandColors.blue.color : BrandColors.blue.color,
                                lineWidth: ((
                                    appManager.current.name == nil && item == .orange) ||
                                    appManager.current.name == item.name) ? 6 : 0)
                            // if no customization has been chosen yet, add border to orange (our default)
                            // otherwise, match border with current icon selection
                        )
                        .padding(BrandPadding.Smedium.pixelWidth)
                }
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

struct AppIconGridView_Previews: PreviewProvider {
    static var previews: some View {
        
        PreviewHelperView(axis: .vertical) {
            AltIconModalView(header: "App Icons", btnAction: {})
        }.edgesIgnoringSafeArea(.bottom)
    }
}
