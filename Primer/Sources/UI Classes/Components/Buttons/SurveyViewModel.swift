//
//  SurveyViewModel.swift
//  Primer
//
//  Created by Sarah Hurtgen on 3/15/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import Foundation
import PrimerEngine
import Combine

extension SurveyFullscreenView {
    class ViewModel: ObservableObject {
        @Published var survey: SurveyModel
        @Published var responses: SurveyResponses
        @Published var didSubmitResponse: Bool = false
        @Published var isLoading: Bool = false
        @Published var isSurveyComplete: Bool = false
        
        var cancellable: AnyCancellable? = nil
        var client: APIClient

        init(client: APIClient, survey: SurveyModel) {
            self.survey = survey
            self.responses = SurveyResponses()
            self.client = client
            
            for question in survey.questions {
                self.responses.responses.append(SurveyResponse(questionId: question.id, response: ""))
            }
            
            self.responses.surveyId = survey.id
            self.responses.userId = survey.userId
        }
        
        // MARK: - Dismiss
        
        func exitWithoutSubmitting() {
            self.isSurveyComplete = true
        }
        
        func dismiss() {
            self.didSubmitResponse = true
            self.isSurveyComplete = true
        }
        
        // MARK: - Store
        
        func store(_ response: SurveyResponse) {
            // find the question id placeholder and update the response
            if let placeholderIndex = responses.responses.firstIndex(where: { $0.questionId == response.questionId }) {
                responses.responses[placeholderIndex] = response
            }
        }
        
        // MARK: - Submit
        
        func submitSurvey() {
            guard isLoading == false else {
                print("Already submitting survey")
                return
            }
            
            self.isLoading = true
            cancellable = self.client
                .sendSurveyResponses(self.responses)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            self.isLoading = false
                            break
                        case .failure(let error):
                            self.isLoading = false
                            print("Error submitting survey id \(self.responses.surveyId): \n\(error)")
                        }
                    },
                    receiveValue: { _ in
                        self.isLoading = false
                        self.dismiss()
                    }
                )
        }
    }
}
