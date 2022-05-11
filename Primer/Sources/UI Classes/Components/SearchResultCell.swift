//
//  SearchResultCell.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/29/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

struct SearchResultCell: View {
    
    var result: SearchResult
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {

        }) {
            HStack {
                switch result.category {
                case .material:
                    SmallSystemIcon(style: .squareOnCircle)
                case .brand:
                    SmallSystemIcon(style: .bag)
                case .color:
                    SmallSystemIcon(style: .colorPalette)
                }
                
                LabelView(text: result.description, style: .bodyMedium)
                
                Spacer()
                
                SmallSystemIcon(style: .rightChevron)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(BrandColors.whiteToggleDeepBlue.color)
        }
    }
}

// MARK: - Preview

struct SearchResultCell_Previews: PreviewProvider {

    static var previews: some View {
        
        PreviewHelperView(axis: .vertical) {
            SearchResultCell(result: SearchResult(description: "Sample", category: .color))
        }
        .frame(maxWidth: .infinity, maxHeight: 500)
        .background(BrandColors.backgroundView.color)
    }
}

enum ResultCategory {

    case material
    case brand
    case color
    
}

struct SearchResult {
    var description: String
    var category: ResultCategory
}
