//
//  SwatchTutorialView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 3/22/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 A multi-stage, multi-step onboarding modal. Initial stage displays tutorial steps guiding user on how to place a swatch, follow up appearances display tips for adjusting placed swatches. 
 */
struct SwatchTutorialView: View {
    @Environment(\.analytics) var analytics
    @StateObject var viewModel: ViewModel
    var isLoading: Bool
    var containerWidth: CGFloat

    init(isLoading: Bool, containerWidth: CGFloat, placeSwatchAction: @escaping () -> Void) {
        let viewModel = ViewModel(placeSwatchAction: placeSwatchAction)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.isLoading = isLoading
        self.containerWidth = containerWidth
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            SwipeableCarousel(count: viewModel.steps.count, selection: $viewModel.currentIndex) {
                ForEach(viewModel.steps.indices, id: \.self) { index in
                    VStack {
                        VideoPlayerView(
                            fileURL: viewModel.steps[index].videoURL,
                            frameSize: CGSize(width: containerWidth, height: isDeviceCompact() ? (containerWidth * 0.6) : containerWidth))
                            .id("TabView\(viewModel.steps[index].instructionText)")
                            .background(BrandColors.navy.color)
                            .padding(.bottom, 20)
                            .overlay(instructions, alignment: .bottom)
                        Spacer()
                    }
                }
            }
            .frame(maxHeight: isDeviceCompact() ? (containerWidth * 0.6) + 40 : containerWidth + 40) // video + spacing for pagination dots
            .overlay(
                // pagination dots
                HStack(spacing: BrandPadding.Small.pixelWidth) {
                    ForEach(viewModel.steps.indices, id: \.self) { index in
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(BrandColors.blue.color)
                            .opacity((index == viewModel.currentIndex) ? 1 : 0.33)
                    }
                }.padding(.bottom, BrandPadding.Smedium.pixelWidth), alignment: .bottom
            )
            
            primaryButton
                .disabled(!isLoading)
                .padding(.horizontal, BrandPadding.Medium.pixelWidth)
            
            footerButton
                .padding(BrandPadding.Smedium.pixelWidth)
            
            Spacer()
        }.background(BrandColors.backgroundView.color)
        .frame(maxWidth: containerWidth, maxHeight: isDeviceCompact() ? (containerWidth * 0.6) + 145 : containerWidth + 145)
        .onAppear {
            analytics?.swatchInstructionsAppeared()
        }
    }
    
    // MARK: - Buttons
    
    var primaryButton: some View {
        Button(viewModel.primaryButtonText) {
            withAnimation {
                viewModel.primaryButtonAction()
            }
            if viewModel.isShowingTutorial, !viewModel.isLastStep {
                analytics?.didCompleteSwatchStep(viewModel.currentIndex + 1, type: .manual)
            }
        }
        .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: viewModel.buttonColor, leadingIconStyle: viewModel.buttonIcon, font: LabelStyle.bodySemibold.font, height: 50.0))
    }
    
    var footerButton: some View {
        ButtonWithText(
            btnText: viewModel.secondaryButtonText,
            labelStyle: .featuredCardTitle,
            btnAction: {
                withAnimation {
                    self.viewModel.footerButtonAction()
                }
                if viewModel.isShowingTutorial, !viewModel.isLastStep {
                    if viewModel.isLastStep {
                        analytics?.didRestartSwatchTutorial(fromTips: false)
                    } else {
                        analytics?.didSkipSwatchTutorial()
                    }
                } else {
                    analytics?.didRestartSwatchTutorial(fromTips: true)
                }
            }).opacity(0.8)
    }
    
    // MARK: - Instruction Pill
    
    var instructions: some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
                .clipShape(Capsule())
            HStack {
                LabelView(text: viewModel.instructionsPreText, style: .smallCategoryLight).opacity(0.6)
                    .padding(.trailing, 10)
                LabelView(text: viewModel.instructions, style: .bodySemiboldWhite)
                Spacer()
            }.padding(.horizontal, BrandPadding.Smedium.pixelWidth)
        }.frame(height: 40)
        .padding(20)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

struct SwatchTutorialView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            GeometryReader { proxy in
                SwatchTutorialView(isLoading: false, containerWidth: proxy.size.width, placeSwatchAction: {})
                    .cornerRadius(20)
            }.padding(BrandPadding.Medium.pixelWidth)
            
            Spacer()
        }
    }
}
