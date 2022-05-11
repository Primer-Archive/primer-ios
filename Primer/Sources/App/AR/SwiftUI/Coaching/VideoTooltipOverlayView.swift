//
//  VideoTooltipOverlayView.swift
//  PrimerTwo
//
//  Created by Tony Morales on 3/11/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import ARKit
import PrimerEngine

struct VideoTooltipOverlayView: View {
    
    var appState: AppState
    var engineContext: EngineContext
    
    var isVisible: Bool {
        return !appState.hasRecorded && appState.engineState.swatch != nil && appState.engineState.hideResizeTooltip
    }
    @State private var hasTimeElapsed = false
    private let appearanceDelayInSeconds: TimeInterval = 2.5
    
    var body: some View {
        Group {
            if isVisible {
                VStack {
                    Spacer()
                    Spacer()
                    
                    VideoTooltipView(engineContext: engineContext)
                        .background(BackgroundView(color: UIColor.black.withAlphaComponent(0.25)))
                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                        .shadow(radius: 12)
                        .frame(width: 200, height: 50, alignment: .bottom)
                        .padding(.bottom, 75)
                    
                    Highlight()
                        .frame(width: 100, height: 100)
                        .padding(.leading, 100)
                        .offset(x:0,y:45)
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

struct VideoTooltipView: View {
    
    var engineContext: EngineContext
    
    init(engineContext: EngineContext) {
        self.engineContext = engineContext
    }
    
    var body: some View {
        HStack(alignment: .center) {
            
            Image(systemName: "video.circle.fill")
                .imageScale(.large)
                .foregroundColor(SwiftUI.Color.white)
            
            Text("Tap and hold to capture video")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(SwiftUI.Color.white)
                .fixedSize()
        }
        .padding(10)
    }
}

struct Highlight: UIViewRepresentable {
    
    func makeUIView(context: Context) -> TooltipView {
        TooltipView(resizeTooltip: false,
                    circleBackgroundOpacity: 0.0,
                    innerCircleRadius: 40,
                    outerCircleRadius: 45)
    }
    
    func updateUIView(_ uiView: TooltipView, context: Context) {
        
    }
}
