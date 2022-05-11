//
//  SurveyButtonGroup.swift
//  Primer
//
//  Created by Sarah Hurtgen on 3/15/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

/**
 Used to handle the different forms of user input for the `SurveyCardView`. Note that response is not automatically stored for the `text` style, and content should be stored using the `State` in the parent view.
 */
struct SurveyButtonsView: View {
    @Binding var selectedIndexes: [Int]
    @State var spacing: CGFloat = 10
    @Binding var text: String
    var question: SurveyQuestionModel
    var btnAction: (String) -> Void

    var rows: Int {
        return question.options.count <= 3 ? 1 : 2
    }
    
    var columns: Int {
        return (question.options.count % 3 == 0) ? 3 : (question.options.count >= 5 ? 5 : question.options.count)
    }
    
    var gridItems: [GridItem] {
        var items: [GridItem] = []
        switch question.type {
        case .multi:
            for _ in 0..<rows {
                items.append(GridItem(.fixed(38), spacing: spacing))
            }
        case .single:
            for _ in 0..<columns {
                items.append(GridItem(.flexible(minimum: 52, maximum: .infinity)))
            }
        case .text:
            return items
        }
        return items
    }
    
    // MARK: - Body
    
    var body: some View {
        switch question.type {
            case .multi:
                LazyHGrid(rows: gridItems, alignment: .center, spacing: 10) {
                    ForEach(question.options.indices, id: \.self) { index in
                        let option = question.options[index]

                        Button(option.text, action: {
                            self.tappedIndex(index)
                        })
                        .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: selectedIndexes.contains(index) ? .blueFilledAndOutline : .whiteBlueOutline, font: LabelStyle.featuredCardTitle.font, height: 38.0, cornerRadius: 14))
                            .frame(width: 90)
                        
                    }
                    .frame(maxWidth: 100, maxHeight: 90)
                }.padding(.horizontal, BrandPadding.Smedium.pixelWidth)
            case .single:
                LazyVGrid(columns: gridItems, alignment: .center, spacing: 10) {
                    ForEach(question.options.indices, id: \.self) { index in
                        let option = question.options[index]

                        if option.text.count == 1 {
                            Button(option.text, action: {
                                btnAction(option.text)
                            })
                            .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue, font: LabelStyle.featuredCardTitle.font, height: 52.0))
                            .frame(width: 52)
                        } else {
                            Button(option.text, action: {
                                btnAction(option.text)
                            })
                            .frame(minWidth: 52)
                            .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue, font: LabelStyle.featuredCardTitle.font, height: 52.0))
                        }
                    }
                }.padding(.horizontal, BrandPadding.Smedium.pixelWidth)
            case .text:
                TextEditor(text: $text)
                    .modifier(TextEditorModifier(text: $text, width: 303, height: 100))
                    .padding(.horizontal, 2)
                    .frame(height: 100)
                    .padding(.horizontal, BrandPadding.Smedium.pixelWidth)
        }
    }
    
    func tappedIndex(_ index: Int) {
        if selectedIndexes.contains(index) {
            selectedIndexes.removeAll(where: { $0 == index } )
        } else {
            selectedIndexes.append(index)
        }
        
        var response = ""
        for selection in selectedIndexes {
            if selection == selectedIndexes.first, selection < question.options.count {
                response.append("\(question.options[selection].text)")
            } else if selection < question.options.count {
                response.append(", \(question.options[selection].text)")
            }
        }
        btnAction(response)
    }
}
