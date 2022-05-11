//
//  CategoryButton.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/27/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

struct CategoryButton: View {
    var text: String
    var filter: SearchFilterModel?
    var hasDropdown: Bool = true
    var buttonColor: ButtonColor = .categoryGrey
    var height: CGFloat = 30
    var btnAction: () -> Void

    var isSelected: Bool {
        guard let currentItems = filter?.items else { return false }
        if let _ = currentItems.first(where: { $0.isSelected }) {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Body

    public var body: some View {
        Button(action: {
            btnAction()
        }, label: {
            HStack(spacing: BrandPadding.Small.pixelWidth) {
                if isSelected, buttonColor == .categoryWhite {
                    LabelView(text: currentText(), style: .smallCategoryLight)
                } else {
                    LabelView(text: currentText(), style: (buttonColor == .categoryWhite) ? .smallCategoryDark : .smallCategoryLight)
                }
                
                if hasDropdown, buttonColor == .categoryWhite {
                    SmallSystemIcon(style: isSelected ? .downChevron : .downChevronGrey)
                } else if hasDropdown {
                    SmallSystemIcon(style: .downChevron)
                }
            }.padding(.leading, BrandPadding.Smedium.pixelWidth)
            .padding(.trailing, hasDropdown ? 0 : BrandPadding.Smedium.pixelWidth)
            .frame(height: height)
            .background(isSelected ? buttonColor.selected : buttonColor.background)
            .cornerRadius(height / 2)
        })
        .frame(height: 44)
    }
    
    func currentText() -> String {
        guard let filter = filter, let currentItems = filter.items else { return text }
        let count = currentItems.filter({ $0.isSelected }).count
        if count == 1 {
            return currentItems.first(where: { $0.isSelected })?.name ?? text
        } else if count > 1 {
            return "\(count) \(filter.plural)"
        } else {
            return text
        }
    }
}

// MARK: - Preview

struct CategoryButton_Previews: PreviewProvider {

    static var filter: SearchFilterModel?
    static var text: String = ""
    
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            LazyButtonStack(axis: .horizontal, content: {
                CategoryButton(text: "Sample 1", hasDropdown: false, btnAction: {})
                CategoryButton(text: "Sample 2", btnAction: {})
                if let filter = filter {
                    CategoryButton(text: filter.name, filter: filter, hasDropdown: true, btnAction: {})
                } else {
                    Text(text)
                }
            })
        }.onAppear {
            loadFilters()
        }
    }
    static func loadFilters() {
        let decoder = JSONDecoder()
        guard let url = Bundle.main.url(forResource: "filter", withExtension: "json") else {
            text = "failed url"
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            text = "failed data"
            return
        }
        guard let filt = try? decoder.decode(SearchFilterModel.self, from: data) else {
            text = "failed product decode"
            return
        }
        filter = filt
    }
}
