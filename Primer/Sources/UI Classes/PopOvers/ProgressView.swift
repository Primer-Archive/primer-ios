//
//  ProgressView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/25/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

struct OnboardingProgressView: View {
    @Binding var seenLidarHelp: Bool
    @Binding var appState: AppState
    @State var currentStep: ProgressStep = .walkToWall
    var engineContext: EngineContext?
    var isLoaded: Bool
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: BrandPadding.Medium.pixelWidth) {
            VideoPlayerView(fileURL: currentStep.videoURL)
                .frame(width: 320, height: 220)
                .background(BrandColors.navy.color)
            ProgressStepsView(appState: appState, activeStep: $currentStep)
                .onAppear {
                    print("currentStep: \(appState.engineState.smartPlacementState), \(currentStep)")
                }
            
            if currentStep == .tapToPlace {
                Button(currentStep.instructionText) {
                    placeSwatch()
                }
                .disabled(!isLoaded)
                .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blueWhiteOutline, leadingIconStyle: .handTapLarge, font: LabelStyle.bodySemiboldWhite.font, cornerRadius: 30))
                .padding(.horizontal, BrandPadding.Small.pixelWidth)
                .shadow(color: BrandColors.blue.color.opacity(0.5), radius: 5, x: 0.0, y: 0.0)
            } else {
                HStack(spacing: 0) {
                    Spacer()
                    Image(systemName: currentStep.largeIcon.symbol)
                        .font(currentStep.largeIcon.font)
                        .foregroundColor(currentStep.largeIcon.foreground)
                        .frame(width: currentStep.largeIcon.size.width, height: currentStep.largeIcon.size.height)
                        .background(currentStep.largeIcon.background)
                    LabelView(text: currentStep.instructionText, style: .bodySemiboldWhite)
                    Spacer()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(BrandColors.deepBlue.color)
                .cornerRadius(BrandPadding.Small.pixelWidth)
                .padding(.horizontal, BrandPadding.Small.pixelWidth)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, BrandPadding.Medium.pixelWidth)
        .background(BrandColors.backgroundView.color)
        .onDisappear {
            appState.engineState.smartPlacementState = .findingWall
        }
    }
    
    private func placeSwatch() {
        if !UserDefaults.hasSeenLidarHelp, AppState.canUseLidar() {
            UserDefaults.hasSeenLidarHelp = true
            self.seenLidarHelp.toggle()
            return
        }
        engineContext?.placeSwatch()
    }
}

// MARK: - Preview

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingProgressView(seenLidarHelp: .constant(false), appState: .constant(.initialState), engineContext: nil, isLoaded: true)
            .frame(width: 320)
            .cornerRadius(20)
            .padding()
            .background(Color.gray)
    }
}
