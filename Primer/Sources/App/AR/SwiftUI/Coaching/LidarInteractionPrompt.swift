//
//  InteractionPrompt.swift
//  PrimerTwo
//
//  Created by James Hall on 3/11/20.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import ARKit
import PrimerEngine

struct LidarInteractionPrompt: View {
    
    var appState: AppState
    var engineContext: EngineContext
    
    var isVisible: Bool {
        return  AppState.canUseLidar() && UserDefaults.hasSeenLidarHelp && appState.engineState.swatch == nil && appState.engineState.worldMappingStatus != .notAvailable
    }
    @State private var hasTimeElapsed = false
    private let appearanceDelayInSeconds: TimeInterval = 3.0
    
    var body: some View {
        Group {
            if isVisible {
                VStack {
                    Spacer()
                    Spacer()
                    
                    LidarInteractionPromptView(engineContext: engineContext)
                        .background(BackgroundView(color: UIColor.black.withAlphaComponent(0.25)))
                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                        .shadow(radius: 12)
                        .frame(width: 200, height: 50, alignment: .bottom)
                        .padding(.bottom, 110)
                }
                .opacity(hasTimeElapsed ? 1.0 : 0.0).animation(.default)
                .transition(AnyTransition.opacity.animation(.default))
                .onAppear(perform: delayedAppearance)
                .onDisappear { self.hasTimeElapsed = false }
            }
        }
    }
    
    private func delayedAppearance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + appearanceDelayInSeconds) {
            self.hasTimeElapsed = true
        }
    }
}

struct LidarInteractionPromptView: View {
    
    var engineContext: EngineContext
    
    init(engineContext: EngineContext) {
        self.engineContext = engineContext
    }
    
    var body: some View {
        HStack(alignment: .center) {
            
            Image(systemName: "hand.tap.fill")
                .imageScale(.large)
                .foregroundColor(SwiftUI.Color.white)
            
            Text("Tap your wall to place a swatch")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(SwiftUI.Color.white)
                .fixedSize()
        }
        .padding(10)
    }
}
