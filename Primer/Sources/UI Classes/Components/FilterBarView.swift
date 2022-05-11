//
//  FilterBarView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/6/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

struct FilterBarView: View {
    var filters: [SearchFilterModel?]
    var categoryAction: () -> Void
    var sortByAction: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            LazyButtonStack(axis: .horizontal, vPadding: .None, hPadding: .Small) {
                ForEach(filters.indices, id: \.self) { index in
                    let filter = filters[index]

                    CategoryButton(
                        text: filter?.name ?? "", filter: filter, hasDropdown: true, buttonColor: .categoryWhite) {
                        categoryAction()
                    }
                }
            }
//            .padding(BrandPadding.Small.pixelWidth)
            
            // Uncomment for future iterations with "Sort By" functionality
//            HStack {
//                Spacer()
//
//                ZStack {
//                    CategoryButton(text: "Sort By") {
//                        sortByAction()
//                    }.padding(BrandPadding.Small.pixelWidth)
//                }.background(BrandColors.darkBlueToggleBlack.color)
//                .shadow(color: .black, radius: 5, x: 0.0, y: 0.0)
//            }
        }.background(BrandColors.navy.color)
        .frame(height: 50)
        .cornerRadius(BrandPadding.Large.pixelWidth)
    }
}

// MARK: - Preview

struct FilterBarView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            FilterBarView(filters: [], categoryAction: {}, sortByAction: {})
                .padding()
        }
    }
}
