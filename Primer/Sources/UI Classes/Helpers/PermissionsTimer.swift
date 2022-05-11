//
//  PermissionsTimer.swift
//  Primer
//
//  Created by Sarah Hurtgen on 4/1/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import Combine

class PermissionsTimer {
    let cancellable: AnyCancellable?

    init(sinkAction: @escaping () -> Void) {
        self.cancellable = Timer.publish(every: 0.5, on: .main, in: .default)
            .autoconnect()
            .sink { _ in
                sinkAction()
            }
    }

    deinit {
        self.cancellable?.cancel()
    }
}
