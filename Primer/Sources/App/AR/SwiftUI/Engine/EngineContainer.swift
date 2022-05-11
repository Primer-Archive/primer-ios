//
//  EngineContainer.swift
//  Primer
//
//  Created by James Hall on 7/16/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine



struct EngineContainer: View{
    
    var proxy: GeometryProxy
    @Binding var appState: AppState
    var client: APIClient
    
    @Environment(\.analytics) var analytics

    var body: some View{
        ZStack {
            
            EngineView(
                material: appState.selectedProductMaterial,
                state: $appState.engineState,
                onEvent: handle) { engineContext in
                EngineOverlayContent(engineContext:engineContext, appState: self.$appState, showCameraToolTip: !appState.hasClearedCameraTip, client: self.client)
            }
            //.frame(height: UIScreen.main.bounds.height, alignment: .top)
            .cornerRadius(20)
            // Safe space offset is around 16pt
            .edgesIgnoringSafeArea(.all)
            .zIndex(2.0)
//                .frame(height:400)
            
            Rectangle()
                .fill(BrandColors.darkBlue.color)
        }
    }
    
    private func handle(engineEvent: EngineEvent, swatch:Swatch) {
        switch engineEvent {
        case .movedSwatch:
            analyticInstance.didMoveSwatch(product:self.appState.selectedProduct, swatch: swatch)
            break
        case .resizedSwatch:
            analyticInstance.didResizeSwatch(product: self.appState.selectedProduct, swatch: swatch)
            break
        case .placedSwatch:
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false){ timer in
                self.appState.showSuccessSwatchPlacement = true
            }
            
            analyticInstance.didMountSwatch(product: self.appState.selectedProduct, swatch: swatch)
        }
    }
}
