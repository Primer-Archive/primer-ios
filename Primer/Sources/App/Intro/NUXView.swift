//
//  NUXView.swift
//  PrimerTwo
//
//  Created by Adam Debreczeni on 2/5/20.
//  Copyright © 2020 Timothy Donnelly. All rights reserved.
//

import SwiftUI
import PrimerEngine


struct NUXView: View {
    @Environment(\.analytics) var analytics
    @State private var currentScreenIndex: Int = 0
    @State private var landingSheet: AppState.VisibleSheet?
    var onFinished: (AppState.VisibleSheet?) -> Void
    var onCameraAllowed: () -> Void

    private var standardScreens: [NUXScreen]
    private var currentScreen: NUXScreen {
        standardScreens[currentScreenIndex]
    }
    
    init(onFinished: @escaping (AppState.VisibleSheet?) -> Void, onCameraAllowed: @escaping () -> Void) {
        self.onFinished = onFinished
        self.onCameraAllowed = onCameraAllowed
        
        self.standardScreens = [
            NUXScreen(page: .authorizeCamera, viewType: NUXCameraPermissionsScreenView.self),
            NUXScreen(page: .swatchTutorial, viewType: NUXIntroScreenView.self),
            NUXScreen(page: .captureTutorial, viewType: NUXIntroScreenView.self),
            NUXScreen(page: .readyToStart, viewType: NUXIntroScreenView.self)
        ]
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            HStack{
                self.currentScreen.makeView(onContinue: { sheet in
                    self.landingSheet = sheet
                    self.advance()
                })
                    .analytics(self.analytics)
                    .id(self.currentScreen.id)
                    .transition(
                        .asymmetric(
                            insertion: AnyTransition.opacity.animation(Animation.easeIn.delay(0.33)),
                            removal: AnyTransition.opacity)
                    )
            }.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
        .background(isDeviceIpad() ? BrandColors.backgroundView.color : BrandColors.navy.color)
        .onAppear(perform: {
            self.analytics?.didStartNUXExperience()
        })
    }

    func advance() {
        let nextIndex = currentScreenIndex.advanced(by: 1)
        if standardScreens.indices.contains(nextIndex) {
            
            if(nextIndex == 2){
                onCameraAllowed()
            }
            withAnimation() {
                currentScreenIndex = nextIndex
            }
            
        } else {
            onCameraAllowed()
            self.analytics?.didEndNUXExperience()
            UserDefaults.hasSeenIntro = true
            onFinished(landingSheet)
        }
    }
}

// MARK: - Preview

struct NUXView_Previews: PreviewProvider {
    static var previews: some View {
        NUXView(onFinished: {_ in }, onCameraAllowed: {}).environment(\.colorScheme, .dark)
    }
}


