//
//  View.swift
//  Primer
//
//  Created by James Hall on 8/7/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//
import SwiftUI

extension View {
    func animate(using animation: Animation = Animation.easeInOut(duration: 1), _ action: @escaping () -> Void) -> some View {
        return onAppear {
            withAnimation(animation) {
                action()
            }
        }
    }
}

extension View {
    func animateForever(using animation: Animation = Animation.easeInOut(duration: 1), autoreverses: Bool = false, _ action: @escaping () -> Void) -> some View {
        let repeated = animation.repeatForever(autoreverses: autoreverses)
        
        return onAppear {
            withAnimation(repeated) {
                action()
            }
        }
    }
}
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

extension View{
    public func convertErrorText(_ error: [String:Any]?) -> String {
        if let error = error {
            var errorString = ""
            for (key, value) in error {
                if let valueArray = value as? Array<String> {
                    // obj is a string array. Do something with stringArray
                    errorString.append("\(key.capitalizingFirstLetter()) \(valueArray.joined(separator: ", "))\(error.count > 1 ? "\n" : "")")
                }
                else {
                    // obj is not a string array
                    errorString.append("\(key.capitalizingFirstLetter()) \(value)\(error.count > 1 ? "\n" : "")")
                }
            }
            return errorString
        }
        return ""
    }
}

extension View {
    public func isDeviceCompact() -> Bool { return UIScreen.main.bounds.width <= 375 && UIScreen.main.bounds.height <= 750 }
    public func isDeviceIpad() -> Bool { return UIDevice.current.userInterfaceIdiom == .pad }
}

extension View {
    @ViewBuilder
    func navigate<Value, Destination: View>(
        using binding: Binding<Value?>,
        @ViewBuilder destination: (Value) -> Destination
    ) -> some View {
        background(NavigationLink(binding, destination: destination))
    }
}
