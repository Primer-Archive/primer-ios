//
//  SurveyCardView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 2/5/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine

/**
 A small card to hold individual survey questions, nexted in a swipable tabview. Passes up user input information to parent view. 
 */

struct SurveyCardView: View {
    @Binding var survey: SurveyModel
    @Binding var isSubmitting: Bool
    @State private var selection = 0
    @State private var isSubmitVisible = false
    @State var currentSelectedIndexes: [Int] = []
    @State var userTypedResponse: String = ""
    
    var exitAction: () -> Void
    var emailAction: () -> Void
    var submitAction: () -> Void
    var storeResponse: (SurveyResponse) -> Void

    init(survey: Binding<SurveyModel>, isSubmitting: Binding<Bool>, exitAction: @escaping () -> Void, emailAction: @escaping () -> Void, storeResponse: @escaping (SurveyResponse) -> Void, submitAction: @escaping () -> Void) {
        self._survey = survey
        self._isSubmitting = isSubmitting
        self.exitAction = exitAction
        self.emailAction = emailAction
        self.submitAction = submitAction
        self.storeResponse = storeResponse
        
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(red: 0.341, green: 0.435, blue: 0.761, alpha: 1)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(red: 0.341, green: 0.435, blue: 0.761, alpha: 1).withAlphaComponent(0.2)
    }
    
    // MARK: - Body
    
    var body: some View {

        VStack(spacing: 0) {
            HStack {
                SmallSystemIcon(style: .x12, isButton: true, btnAction: exitAction)
                Spacer()
                ButtonWithText(btnText: "Email us Feedback", labelStyle: .buttonSemibold, btnAction: emailAction)
                    .padding(.trailing, BrandPadding.Tiny.pixelWidth)
            }.padding(.horizontal, BrandPadding.Smedium.pixelWidth)
            
            ZStack {
                TabView(selection: $selection) {
                    ForEach(survey.questions.indices, id: \.self) { index in
                        let question = survey.questions[index]
                        let hasTwoRows: Bool = (question.type == .multi && question.options.count > 3) || (question.type == .single && question.options.count > 5) || question.type == .text
                        VStack(spacing: 0) {
                            LabelView(text: question.question, style: .bodyMedium)
                                .frame(height: 40)
                                .padding(.vertical, hasTwoRows ? 10 : 10)
                                .padding(.horizontal, BrandPadding.Smedium.pixelWidth)
                            Spacer()
                            
                            SurveyButtonsView(selectedIndexes: $currentSelectedIndexes, text: $userTypedResponse, question: question, btnAction: { responseText in
                                if question != survey.questions.last, question.type != .multi {
                                    storeResponse(SurveyResponse(questionId: question.id, response: responseText))
                                    withAnimation {
                                        selectionTapped()
                                    }
                                }
                            })
                            .frame(maxWidth: 345)
                            
                            Spacer()
                                .frame(height: 40)
                        }
                        .padding(.top, hasTwoRows ? 0 : 16)
                        .padding(.bottom, 50) // keep view pushed above pagination dots
                        .frame(maxWidth: .infinity, maxHeight: 210)
                        .tag(index)
                    }
                }.tabViewStyle(PageTabViewStyle())
                
                VStack {
                    Spacer()
                    Button("Submit") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        storeResponse(SurveyResponse(questionId: survey.questions[survey.questions.count - 1].id, response: userTypedResponse))
                        submitAction()
                    }
                    .disabled(isSubmitting || (self.selection != (survey.questions.count - 1)))
                    .buttonStyle(PrimaryCapsuleButtonStyle(buttonColor: .blue, font: LabelStyle.featuredCardTitle.font, height: 40.0))
                    .padding(.vertical, 10)
                    .padding(.bottom, 80)
                    .frame(maxWidth: 150, maxHeight: 40.0)
                    .opacity(isSubmitVisible ? 1 : 0)
                }.frame(maxHeight: .infinity)
            }
        }
        .padding(.top, BrandPadding.Smedium.pixelWidth)
        .cornerRadius(30)
        .background(BrandColors.backgroundView.color)
        .onChange(of: selection) { current in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            withAnimation {
                if current == (survey.questions.count - 1) {
                    self.isSubmitVisible = true
                } else {
                    self.isSubmitVisible = false
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    func selectionTapped() {
        self.selection += 1
    }
}
