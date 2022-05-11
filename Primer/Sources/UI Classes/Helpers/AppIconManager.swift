//
//  AppIconManager.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/20/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import UIKit

/**
 Used to track and update data around App Icon Customizations.
 */

class AppIconManager {
    var current: PrimerAppIcon {
        return PrimerAppIcon.allCases.first(where: {
            $0.name == UIApplication.shared.alternateIconName
        }) ?? .standard
    }
    
    func setIcon(_ appIcon: PrimerAppIcon, completion: ((Bool) -> Void)? = nil) {
        guard current != appIcon, UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(appIcon.name) { error in
            if let error = error {
                print("Error setting alternate icon \(appIcon.name ?? "invalid name"): \(error.localizedDescription)")
            }
            completion?(error != nil)
        }
    }
}
