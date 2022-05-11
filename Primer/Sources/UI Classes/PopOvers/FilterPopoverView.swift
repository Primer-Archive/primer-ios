//
//  FilterPopoverView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/30/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine


// MARK: - Popover

struct FilterPopoverView: View {
    @Binding var filter: SearchFilterModel?
    var closeBtnAction: () -> Void = {}
    var tappedFilterAction: (Int) -> Void
    var resetFiltersAction: () -> Void
    var selectType: SearchFilterModel.selectType {
        return filter?.select_type ?? .multi
    }

    // MARK: - Body
    
    var body: some View {
        VStack {
            if let filter = filter, let items = filter.items {
                ZStack(alignment: .trailing) {
                    CustomHeaderView(leadingIcon: .xFillGrey, text: "Filter by \(filter.name)", leadingBtnAction: closeBtnAction)
                    ButtonWithText(btnText: "Reset", btnAction: {
                        for (index, _) in items.enumerated() {
                            self.filter?.items?[index].isSelected = false
                        }
                        resetFiltersAction()
                    })
                    .padding(.trailing, BrandPadding.Medium.pixelWidth)
                }
                
                ScrollView(.vertical) {
                    ForEach(items.indices, id: \.self) { index in
                        FilterCell(isSelected: items[index].isSelected, text: items[index].name, selectType: filter.select_type) {
                            switch filter.select_type {
                            case .multi:
                                self.filter?.items?[index].isSelected.toggle()
                                self.tappedFilterAction(index)
                            case .single:
                                if let previousSelectedIndex = items.firstIndex(where: {$0.isSelected}) {
                                    self.filter?.items?[previousSelectedIndex].isSelected = false
                                }
                                self.filter?.items?[index].isSelected = true
                                withAnimation {
                                    self.tappedFilterAction(index)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        closeBtnAction()
                                    }
                                }
                            }
                        }
                    }.padding(.horizontal, BrandPadding.Smedium.pixelWidth)
                }
                Rectangle().foregroundColor(BrandColors.backgroundView.color)
                    .frame(height: 25)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 485 : .infinity)
        .background(BrandColors.backgroundView.color)
    }
}

// MARK: - Cell

struct FilterCell: View {
    
    var isSelected: Bool
    var text: String
    var selectType: SearchFilterModel.selectType
    var btnAction: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        
        VStack {
            Button(action: {
                btnAction()
            }, label: {
                HStack {
                    LabelView(text: text, style: .bodyMedium)
                    Spacer()
                    switch selectType {
                    case .multi:
                        SmallSystemIcon(style: !isSelected ? .emptyCircle : .checkmarkFill)
                    case .single:
                        SmallSystemIcon(style: !isSelected ? .emptyCircle : .filledCircle)
                    }
                }
                .padding(BrandPadding.Tiny.pixelWidth)
            })
            Divider()
                .foregroundColor(BrandColors.buttonGrey.color)
        }
    }
}

// MARK: - Preview

struct FilterPopoverView_Previews: PreviewProvider {
    static var filter: SearchFilterModel?
    static var text = ""

    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            ScrollView {
                VStack {
                    if let filter = filter {
                        FilterPopoverView(filter: .constant(filter), closeBtnAction: {}, tappedFilterAction: {_ in }, resetFiltersAction: {})
                        FilterPopoverView(filter: .constant(filter), closeBtnAction: {}, tappedFilterAction: {_ in }, resetFiltersAction: {})
                    } else {
                        Text(text)
                    }
                }
            }.onAppear {
                loadFilters()
            }
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
