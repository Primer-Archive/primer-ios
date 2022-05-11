//
//  ImageCircleButton.swift
//  Primer
//
//  Created by Sarah Hurtgen on 12/3/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

/**
 A circular button that can display either an `Image` or `SmallSystemIcon` as overlay, with full size of circle being tappable.
 */
public struct ImageCircleButton: View {
    var image: Image?
    var systemIcon: SmallSystemIcon?
    var imageFrame: CGSize = CGSize(width: 32, height: 32)
    var buttonFrame: CGSize = CGSize(width: 60, height: 60)
    var color: ButtonColor
    var btnAction: () -> Void
    
    public var body: some View {
        ZStack {
            Circle()
                .frame(width: buttonFrame.width, height: buttonFrame.height)
                .background(color.background)
                .foregroundColor(color.foreground)
            Button(action: {
                self.btnAction()
            }) {
                if let image = image {
                    image
                        .resizable()
                        .frame(width: imageFrame.width, height: imageFrame.height)
                } else if let icon = systemIcon {
                    icon
                }
            }
        }
        .clipShape(Circle())
    }
}

struct ImageCircleButton_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHelperView(axis: .vertical) {
            ImageCircleButton(systemIcon: SmallSystemIcon(style: .largeSave), color: .solitudeGrey, btnAction: {})
                .padding()
        }
    }
}
