//
//  CurationCardView.swift
//  PrimerTwo
//
//  Created by Adam Debreczeni on 11/13/19.
//  Copyright © 2019 Timothy Donnelly. All rights reserved.
//

import SwiftUI

struct CurationCardView: View {
    
    var body: some View {
        Image("curation")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(overlay, alignment: .center)
    }
    
    private var overlay: some View {
        VStack(spacing: 10) {
            Image("logo")
            .fixedSize(horizontal: true, vertical: true)
            .clipped()
                .shadow(color: SwiftUI.Color.black.opacity(0.9), radius: 100, x: 0, y: 2)
            
            Text("Brit + Co's picks")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(SwiftUI.Color.white)
                .shadow(color: SwiftUI.Color.black.opacity(0.8), radius: 10, x: 0, y: 2)
        }
//        .padding(.bottom, 20)
    }
}

struct CurationCardView_Previews: PreviewProvider {
    static var previews: some View {
        CurationCardView()
        .frame(width: 250, height: 300)
    }
}
