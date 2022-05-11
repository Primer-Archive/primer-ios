//
//  AppSizes.swift
//  Primer
//
//  Created by James Hall on 7/20/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI

enum BrandPadding: CGFloat {
    case None
    case Tiny
    case Small
    case Smedium
    case Medium
    case Large
    
    var pixelWidth: CGFloat {
        switch self{
            case .None:
                return 0.0
            case .Tiny:
                return 6.0
            case .Small:
                return 10.0
            case .Smedium:
                return 16.0
            case .Medium:
                return 20.0
            case .Large:
                return 30.0
        }
    }
}
