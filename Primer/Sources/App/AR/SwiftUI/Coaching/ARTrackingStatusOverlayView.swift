//
//  ARTrackingStatusOverlayView.swift
//  PrimerTwo
//
//  Created by Tony Morales on 3/10/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import ARKit
import PrimerEngine

struct ARTrackingStatusOverlayView: View {
    
    var appState: AppState
    var engineContext: EngineContext
    
    var errorStyle: ARTrackingErrorStyle {
        
        // check for custom low light warning
        if appState.engineState.lowLightWarning {
            return ARTrackingErrorStyle.lowLight
        } else {
            // check ARTracking responses
            switch appState.engineState.trackingState {
            case .limited(let reason):
                switch reason {
                case .excessiveMotion:
                    return ARTrackingErrorStyle.excessiveMotion
                case .insufficientFeatures:
                    return ARTrackingErrorStyle.insufficientFeatures
                default:
                    return ARTrackingErrorStyle.none
                }
            case .normal, .notAvailable:
                if !appState.engineState.lidarDidFindWall {
                    return ARTrackingErrorStyle.cantFindWall
                }
                return ARTrackingErrorStyle.none
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack { 
            ARErrorStateView(style: errorStyle)
                .transition(AnyTransition.opacity.animation(.default))
        }
    }
}

struct TrackingView: View {
    
    var engineContext: EngineContext
    var limitedTrackingReason: String
    var limitedTrackingSuggestion: String
    
    init(engineContext: EngineContext, engineState: EngineState) {
        self.engineContext = engineContext
        if(!engineState.lidarDidFindWall){
            limitedTrackingReason = "LIDAR could not detect wall."
            limitedTrackingSuggestion = "Move closer to a wall."
        }else{
            limitedTrackingReason = engineState.trackingState.limitedTrackingReason
            limitedTrackingSuggestion = engineState.trackingState.limitedTrackingSuggestion
        }

    }
    
    var body: some View {
        ZStack {
            HStack(alignment: .center) {
                Text("AR")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .fontWeight(.heavy)
                    .fixedSize()
                    .padding(4)
                    .background(BackgroundView(color: .orange))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            VStack(alignment: .center) {
                Text(limitedTrackingReason)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .bold()
                    .fixedSize()
                
                Text(limitedTrackingSuggestion)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .fixedSize()
                    .opacity(0.75)
            }
        }
        .padding(10)
    }
}

//struct ARTrackingStatusOverlayView_Previews: PreviewProvider {
//    static var previews: some View {
//        ARTrackingStatusOverlayView(appState: .initialState, engineContext: )
//    }
//}
