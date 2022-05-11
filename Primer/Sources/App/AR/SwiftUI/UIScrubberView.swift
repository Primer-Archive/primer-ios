//
//  UIScrubberView.swift
//  PrimerTwo
//
//  Created by Timothy Donnelly on 11/7/19.
//  Copyright © 2019 Timothy Donnelly. All rights reserved.
//

import SwiftUI

struct UIScrubberView<StateType, Content: View>: View {
        
    var content: (Binding<StateType>) -> Content
    
    @State private var states: [StateType]
    
    @State private var activeIndex: Double = 0
    
    init(initialState: StateType, content: @escaping (Binding<StateType>) -> Content) {
        _states = State(initialValue: [initialState, initialState])
        self.content = content
    }
    
    var body: some View {
        
        let indexRange = ClosedRange(uncheckedBounds: (lower: 0, upper: Double(states.count-1)))
        
        return VStack(spacing: 0.0) {
            content(binding)
                .frame(minWidth: 0.0, maxWidth: .infinity, minHeight: 0.0, maxHeight: .infinity)

            Slider(value: $activeIndex, in: indexRange, step: 1.0)
                .padding()
                .background(BackgroundView().edgesIgnoringSafeArea(.all))

        }
        
    }
    
    var binding: Binding<StateType> {
        return Binding(
            get: {
                let index = Int(self.activeIndex)
                return self.states[index]
            },
            set: { newState in
                self.states.append(newState)
                self.activeIndex = Double(self.states.count-1)
            })
    }
    
    func append(state: StateType) {
        states.append(state)
    }
    
}

//struct UIScrubberView_Previews: PreviewProvider {
//    static var previews: some View {
//        UIScrubberView()
//    }
//}
