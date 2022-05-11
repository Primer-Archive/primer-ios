//
//  CurationView.swift
//  PrimerTwo
//
//  Created by Adam Debreczeni on 11/6/19.
//  Copyright © 2019 Timothy Donnelly. All rights reserved.
//

import SwiftUI

struct CurationView: View {
    var body: some View {
        Image("curation")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(minHeight: 0, maxHeight: .infinity)
            .frame(minWidth: 0, maxWidth: .infinity)
            .clipped()
            .overlay(overlay, alignment: .bottom)
            
    }
    
    private var overlay: some View {
        HStack(alignment: .center) {
            
            VStack(alignment: .leading) {
                Text("Brit + Co’s Fall Picks")
                    .font(.headline)
                    .foregroundColor(SwiftUI.Color.white)
                    .multilineTextAlignment(.leading)
                Text("See the curation")
                    .font(.subheadline)
                    .fontWeight(.light)
                    .foregroundColor(SwiftUI.Color.white)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            VStack{
                Image("logo")
                    .fixedSize(horizontal: true, vertical: true)
                    .clipped()
            }
        }
        .padding(12)
        .background(SwiftUI.Color(
            red: 0.24,
            green: 0.33,
            blue: 0.37,
            opacity: 1.00))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(20.0)
        .shadow(radius: 10)
    }
}

struct CurationView_Previews: PreviewProvider {
    static var previews: some View {
        CurationView()
            .frame(height: 400)
    }
}
