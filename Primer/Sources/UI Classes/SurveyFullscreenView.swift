//
//  SurveyFullscreenView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 3/15/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine
import MessageUI

/**
 A `SurveyCardView` with a dimmed fullscreen overlay and email feedback composer.
 */
struct SurveyFullscreenView: View {
    @Environment(\.analytics) var analytics
    @Binding var isActive: Bool
    @Binding var shouldShowRating: Bool
    @StateObject var viewModel: ViewModel
    @State private var isShowingEmail = false
    
    init(client: APIClient, survey: SurveyModel, isActive: Binding<Bool>, shouldShowRating: Binding<Bool>) {
        let viewModel = ViewModel(client: client, survey: survey)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._isActive = isActive
        self._shouldShowRating = shouldShowRating
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.black.opacity(!isActive ? 0 : 0.75)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            .edgesIgnoringSafeArea(.vertical)
            .overlay(
                VStack {
                    if viewModel.survey.questions.count == 0 {
                        ActivityIndicatorView()
                    } else {
                        SurveyCardView(survey: $viewModel.survey, isSubmitting: $viewModel.isLoading, exitAction: {
                            let answeredQuestions = viewModel.responses.responses.filter( { $0.response != "" })
                            analytics?.didEndSurvey(id: viewModel.survey.id, questionsAnswered: answeredQuestions.count, submittedResponse: false)
                            withAnimation {
                                viewModel.exitWithoutSubmitting()
                            }
                        }, emailAction: {
                            analytics?.tappedEmailFeedbackFromSurvey(id: viewModel.survey.id)
                            displayEmailComposer()
                        }, storeResponse: { response in
                            analytics?.didTapSurveySelection(response, surveyId: viewModel.survey.id)
                            
                            // only show app store rating if user scores us 4+
                            if viewModel.survey.id == 1, response.questionId == 1, (response.response == "4" || response.response == "5") {
                                self.shouldShowRating = true
                            }
                            viewModel.store(response)
                        }, submitAction: {
                            let answeredQuestions = viewModel.responses.responses.filter( { $0.response != "" })
                            analytics?.didEndSurvey(id: viewModel.survey.id, questionsAnswered: answeredQuestions.count, submittedResponse: true)
                            viewModel.submitSurvey()
                        })
                        .frame(width: 345, height: 325, alignment: .center)
                        .ignoresSafeArea(.keyboard)
                        .cornerRadius(30)
                        .offset(y: !isActive ? 360 : -35)
                        .edgesIgnoringSafeArea(.bottom)
                        .onAppear {
                            analytics?.didStartSurvey(id: viewModel.survey.id)
                        }
                        .overlay(
                            ActivityIndicatorView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .opacity(viewModel.isLoading ? 1 : 0)
                                .opacity(viewModel.isSurveyComplete && viewModel.didSubmitResponse ? 1 : 0)
                        )
                    }
                },
                alignment: .bottom
            )
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: viewModel.isSurveyComplete, perform: { value in
            withAnimation {
                self.isActive = !value
            }
        })
    }
    
    // MARK: - Email Helper
    
    func displayEmailComposer() {
        if MFMailComposeViewController.canSendMail() {
            let vc = PrimerEmailHelperVC()
            vc.setupPrimerEmail(subject: "Survey Feedback", body: "Hi Primer team,\n\n(Describe your feedback or issue here. Screenshots or screen recordings showing the issue help too!)")
            vc.mailComposeDelegate = vc
            
            let scene = UIApplication.shared.connectedScenes.first as! UIWindowScene
            var presentingViewController = scene.windows.first!.rootViewController!
            presentingViewController.modalPresentationStyle = .fullScreen

            if let popoverController = vc.popoverPresentationController {
                popoverController.sourceView = presentingViewController.view //to set the source of your alert
                popoverController.sourceRect = CGRect(x: presentingViewController.view.bounds.midX, y: presentingViewController.view.bounds.midY, width: 0, height: 0) // you can set this as per your requirement.
            }

            while let presented = presentingViewController.presentedViewController {
                presentingViewController = presented
            }
            isShowingEmail = true
            presentingViewController.present(vc, animated: true, completion: nil)
            
        } else {
            print("Device not setup for Mail")
        }
    }
    
}
