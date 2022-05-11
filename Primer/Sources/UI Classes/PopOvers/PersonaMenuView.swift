//
//  PersonaMenuView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 9/21/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 For use in account creation, triggers an `ActionSheet` for user to select their "Persona"
 */
struct PersonaMenuView: View {
    @Binding var currentSelection: Persona
    @State private var isExpanded: Bool = false

    // MARK: - Body
    
    var body: some View {
        VStack {
            HStack {
                LabelView(text: $currentSelection.wrappedValue.rawValue, style: .textfield)
                    .frame(height: 52)
                Rectangle().foregroundColor(BrandColors.backgroundBW.color)
                SwiftUI.Image(systemName: SFSymbol.chevronDown.rawValue).font(Font.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(BrandColors.textfieldText.color)
            }.onTapGesture(count: 1, perform: {
                self.isExpanded.toggle()
            })
            .padding(.leading, BrandPadding.Small.pixelWidth)
            .padding(.trailing, BrandPadding.Small.pixelWidth)
            
            .actionSheet(isPresented: $isExpanded, content: {
                ActionSheet(title: Text(Persona.unselected.rawValue), buttons: [
                    .default(Text(Persona.designer.rawValue)) { self.currentSelection = Persona.designer },
                    .default(Text(Persona.decorator.rawValue)) { self.currentSelection = Persona.decorator },
                    .default(Text(Persona.manufacturer.rawValue)) { self.currentSelection = Persona.manufacturer },
                    .cancel()
                ])
            })
        }
        .frame(height: 52)
        .background(BrandColors.backgroundBW.color)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.09), radius: 4, x: 0.0, y: 2)
    }
}

// MARK: - Preview

struct PersonaMenuView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PersonaMenuView(currentSelection: .constant(Persona.unselected))
        }.padding()
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        .background(BrandColors.sand.color)
    }
}
