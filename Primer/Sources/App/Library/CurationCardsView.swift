//
//  CurationCardsView.swift
//  PrimerTwo
//
//  Created by Adam Debreczeni on 11/13/19.
//  Copyright © 2019 Timothy Donnelly. All rights reserved.
//

import SwiftUI

struct CurationCardsView: View {
    var height: CGFloat
    var width: CGFloat
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0..<3) { item in
                    GeometryReader { geometry in
                        CurationCardView()
                            .frame(width: self.width, height: self.height)
                            .shadow(color: SwiftUI.Color.black.opacity(0.2), radius: 6, x: 0, y: 2)
                            .rotation3DEffect(Angle(degrees:
                                Double(geometry.frame(in: .global).minX - 40) / -40
                            ), axis: (x: 0.0, y: 10.0, z: 0.0))
                            .blur(radius: CGFloat(abs(Double(geometry.frame(in: .global).minX - 40) / 100)))
                    }
                    .frame(width: self.width, height: self.height)
                }
            }
            .padding(.leading, 30)
            .padding(.trailing, 30)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
    }
}

struct CurationCardsView_Previews: PreviewProvider {
    static var previews: some View {
        CurationCardsView(height: 200, width: 300)
    }
}
