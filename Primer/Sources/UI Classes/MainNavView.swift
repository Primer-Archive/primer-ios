//
//  MainNavView.swift
//  Primer
//
//  Created by James Hall on 6/29/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI


struct MainNavViewItem{
    var buttonText: String
    var buttonIconName: String
    var buttonAction: () -> Void
}


struct MainNavView: View {
    var bottomInset:CGFloat
    var buttons:[MainNavViewItem]

    var body: some View {
        HStack{
            ForEach(buttons.indices, id: \.self) { idx in
                self.button(for: idx)
            }
            
        }
        //heyadam, make sure to take into account home buttons here!
        .padding(.top, BrandPadding.Small.pixelWidth)
        .padding(.bottom, BrandPadding.Medium.pixelWidth)
        .frame(width: UIScreen.main.bounds.size.width)
        .background(BrandColors.darkBlue.color)
        .edgesIgnoringSafeArea(.all)
    }
    private func button(for index: Int) -> some View {
        
        let row = buttons[index]
        
        
        return Button(action: {
            row.buttonAction()
        }) {
            VStack{
                SwiftUI.Image(systemName: row.buttonIconName).font(Font.system(size: 22, weight: .regular, design: .rounded))
                    .foregroundColor(BrandColors.sand.color)
                Text(row.buttonText)
                    .font(Font.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(BrandColors.sand.color)
                    .padding(.top, 2)
            }
        }.frame(maxWidth: .infinity)
    }
    
}

struct MainNavView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { proxy in
        MainNavView(
            bottomInset: 0,
            buttons:[
            MainNavViewItem(buttonText: "Products", buttonIconName: "rectangle.on.rectangle.angled", buttonAction: {
                
            }),
            MainNavViewItem(buttonText: "Favorites", buttonIconName: "heart", buttonAction:{
                
            })
        ])
            
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .edgesIgnoringSafeArea(.bottom)
        }
    }
}
