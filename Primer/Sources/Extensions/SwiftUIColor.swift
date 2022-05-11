import SwiftUI
import Foundation

extension SwiftUI.Color {

        /// NOTE: Don't add the # before the hex or this returns black
        init(hex: String) {
            let scanner = Scanner(string: hex)
            var rgbValue: UInt64 = 0
            scanner.scanHexInt64(&rgbValue)

            let r = (rgbValue & 0xff0000) >> 16
            let g = (rgbValue & 0xff00) >> 8
            let b = rgbValue & 0xff


            self.init(red: Double(r) / 0xff, green: Double(g) / 0xff, blue: Double(b) / 0xff)
        }

}
