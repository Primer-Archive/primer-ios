//
//  SCNNode.swift
//  PrimerEngine
//
//  Created by Erik Foss on 9/23/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SceneKit

extension SCNNode {
    
    // MARK: Specifying Categories
    
    /// Categories to which a node may belong.
    struct CategorySet: OptionSet {
        
        let rawValue: Int
        
        /// The default category to which nodes automatically belong by default.
        static let `default` = CategorySet(rawValue: 1 << 0)
        
        /// The category to which nodes comprising the swatch belong.
        static let swatch = CategorySet(rawValue: 1 << 1)
        
        /// The category to which nodes comprising the swatch's resizing controls belong.
        static let resizer = CategorySet(rawValue: 1 << 2)
        
    }
    
}
