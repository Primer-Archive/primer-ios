//
//  ImageTimer.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/18/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI
import Combine

class ImageTimer {
    let cancellable: AnyCancellable?

    init(sinkAction: @escaping () -> Void) {
        self.cancellable = Timer.publish(every: 8.0, on: .main, in: .default)
            .autoconnect()
            .sink { _ in
                sinkAction()
            }
    }

    deinit {
        self.cancellable?.cancel()
    }
}
