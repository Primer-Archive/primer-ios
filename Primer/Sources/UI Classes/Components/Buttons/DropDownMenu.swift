//
//  DropDownMenu.swift
//  Primer
//
//  Created by Sarah Hurtgen on 9/21/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI


struct PersonaMenu: View {
    @State private var isExpanded: Bool = false
    @State private var currentSelection: String = "Persona"
    
    // MARK: - Body
    
    var body: some View {

        VStack {
            
            // MARK: - ActionSheet
            
            
            
            // MARK: - V1
            HStack {
                LabelView(text: $currentSelection.wrappedValue, style: .textfield)
                    .frame(height: 52)
                Spacer()
                
                // Image code copied directly from SystemIcon Button
                SwiftUI.Image(systemName: SFSymbol.chevronDown.rawValue).font(Font.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.6))
            }.onTapGesture(count: 1, perform: {
                self.isExpanded.toggle()
            })
            .padding(.leading, 13)
            .padding(.trailing, 13)
            .actionSheet(isPresented: $isExpanded, content: {
                ActionSheet(title: Text("Persona"), buttons: [
                    .default(Text("Design Professional")) { self.currentSelection = "Design Professional" },
                    .default(Text("Decor Enthusiast")) { self.currentSelection = "Decor Enthusiast" },
                    .default(Text("Manufacturer")) { self.currentSelection = "Manufacturer" },
                    .cancel()
                ])
            })
//
//            if isExpanded {
//                List(categories) { category in
//                    LabelView(text: category.name, style: .textfield)
//                        .onTapGesture(count: 1, perform: {
//                            self.currentSelection = category.name
//                            self.isExpanded.toggle()
//                        })
//                }
//            }
            
            // MARK: - V2
//            DisclosureGroup(currentSelection, isExpanded: $isExpanded) {
//                ForEach(categories) { category in
//                    LabelView(text: category.name, style: .textfield)
//                        .frame(maxWidth: .infinity)
//                        .padding(.top, 4)
//                        .onTapGesture(count: 1, perform: {
//                            self.currentSelection = category.name
//                        })
//                }
//            }
//            .font(LabelStyle.textfield.font)
//            .foregroundColor(BrandColors.textfieldText.color)
//            .accentColor(BrandColors.textfieldText.color)
//            .padding(.leading, 13)
//            .padding(.trailing, 17)
        }
        // MARK: - V1
//        .frame(height: isExpanded ? 195 : 52)
        
        // MARK: - V2
        .frame(height: 52)
        .background(BrandColors.background.color)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.09), radius: 4, x: 0.0, y: 2)
    }
}

// MARK: - Preview

struct DropDownMenu_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PersonaMenu()
        }.padding()
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        .background(BrandColors.sand.color)
    }
}
