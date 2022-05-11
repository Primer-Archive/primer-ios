//
//  FavoriteBadge.swift
//  Primer
//
//  Created by James Hall on 9/3/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI


struct FavoriteBadge: View {
    
    var isVisible: Bool = true
    var isFavorite: Bool
    var favoriteAction: () -> Void
    var unfavoriteAction: () -> Void

    @State var currentBadge: SystemIconStyle = .unfavoritedBadge
    
    var body: some View {
        ZStack {
            SmallSystemIcon(style: currentBadge, isButton: true, btnAction: {
                if currentBadge == .unfavoritedBadge {
                    if AuthController.shared.isLoggedIn {
                        currentBadge = .favoriteBadge
                    }
                    favoriteAction()
                } else if currentBadge == .favoriteBadge {
                    if AuthController.shared.isLoggedIn {
                        currentBadge = .unfavoritedBadge
                    }
                    unfavoriteAction()
                }
            }).onAppear {
                if isFavorite {
                    currentBadge = .favoriteBadge
                }
            }
            
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))

        }
        .padding(BrandPadding.Tiny.pixelWidth)
        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 1.0)))
        .opacity(isVisible ? 1 : 0)
    }
}

struct FavoriteBadge_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteBadge(isFavorite: true, favoriteAction: {}, unfavoriteAction: {})
    }
}
