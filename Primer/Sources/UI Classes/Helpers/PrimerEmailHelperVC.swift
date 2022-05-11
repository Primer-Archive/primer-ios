//
//  PrimerEmailHelperVC.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/28/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import Foundation
import MessageUI

/**
 Helper class for using mail composer in app. Defaults recipient to `support@primer.com` and includes device details in message body. `mailComposeDelegate` should be set to self on init to properly dismiss view once email is sent or cancelled.
 */
class PrimerEmailHelperVC: MFMailComposeViewController, MFMailComposeViewControllerDelegate {

    func setupPrimerEmail(recipients: [String] = ["support@primer.com"], subject: String, body: String, isHTML: Bool = false, includeVersionHeader: Bool = true) {
        self.setToRecipients(recipients)
        self.setSubject(subject)
        self.setMessageBody(includeVersionHeader ? self.includeDeviceHeader(in: body) : body, isHTML: isHTML)
    }
    
    private func includeDeviceHeader(in messageBody: String) -> String{
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let device = UIDevice().type.rawValue
        let systemVersion = UIDevice.current.systemVersion
        
        return "Device type: \(device)\nOS version: \(systemVersion)\nApp version: \(appVersion ?? "")\n\n\(messageBody)"
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
