//
//  SwatchTutorialViewModel.swift
//  Primer
//
//  Created by Sarah Hurtgen on 3/23/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import Foundation

extension SwatchTutorialView {
    
    class ViewModel: ObservableObject {
        @Published var steps: [SwatchOnboardingStep] = []
        @Published var primaryButtonText: String = ""
        @Published var secondaryButtonText: String = ""
        @Published var instructionsPreText: String = ""
        @Published var instructions: String = ""
        @Published var buttonColor: ButtonColor = .navy
        @Published var buttonIcon: SystemIconStyle? = nil
        
        private var isValidIndex: Bool {
            return currentIndex < steps.count
        }
        
        private var placeSwatchAction: () -> Void
        
        var currentIndex: Int = 0 {
            didSet {
                updateLabels()
                updateButtons()
            }
        }
        
        var isShowingTutorial: Bool {
            return !UserDefaults.hasCompletedSwatchTutorial
        }
        
        var isLastStep: Bool {
            if isShowingTutorial, isValidIndex {
                return steps[currentIndex].isLast
            }
            return true
        }

        // MARK: - Init
        
        init(placeSwatchAction: @escaping () -> Void) {
            self.placeSwatchAction = placeSwatchAction
            
            if isShowingTutorial {
                self.steps = PlaceSwatchStep.allCases
            } else {
                self.steps = AdjustSwatchStep.allCases
            }
            updateLabels()
            updateButtons()
        }
        
        // MARK: - Actions
        
        func primaryButtonAction() {
            if isShowingTutorial {
                if isLastStep {
                    if !UserDefaults.hasCompletedSwatchTutorial {
                        UserDefaults.hasCompletedSwatchTutorial = true
                    }
                    placeSwatchAction()
                } else {
                    if (currentIndex + 1) < steps.count {
                        currentIndex += 1
                    }
                }
            } else {
                placeSwatchAction()
            }
        }
        
        func footerButtonAction() {
            if isShowingTutorial, !isLastStep {
                if !UserDefaults.hasCompletedSwatchTutorial {
                    UserDefaults.hasCompletedSwatchTutorial = true
                }
                if steps.count - 1 >= 0 {
                    self.currentIndex = steps.count - 1
                }
            } else {
                if UserDefaults.hasCompletedSwatchTutorial {
                    UserDefaults.hasCompletedSwatchTutorial = false
                }
                self.steps = PlaceSwatchStep.allCases
                self.currentIndex = 0
            }
        }
        
        // MARK: - Helpers

        func updateLabels() {
            if isValidIndex {
                self.instructions = steps[currentIndex].instructionText
                self.primaryButtonText = steps[currentIndex].primaryButtonText
                self.secondaryButtonText = steps[currentIndex].secondaryButtonText
                self.instructionsPreText = "\(isShowingTutorial ? "Step" : "Tip") \(currentIndex + 1) of \(steps.count)"
            }
        }
        
        func updateButtons() {
            if isValidIndex {
                if isShowingTutorial, !isLastStep {
                    self.buttonColor = .navy
                    self.buttonIcon = nil
                } else {
                    self.buttonColor = .blue
                    self.buttonIcon = .handTapLarge
                }
            }
        }
    }
}
