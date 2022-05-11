//
//  SIMD3+Extension.swift
//  PrimerEngine
//
//  Created by Eric Florenzano on 12/10/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SceneKit

extension float4x4 {
    
    var translation: SIMD3<Float> {
        get {
            let translation = columns.3
            return SIMD3(translation.x, translation.y, translation.z)
        }
        set(newValue) {
            columns.3 = SIMD4(newValue.x, newValue.y, newValue.z, columns.3.w)
        }
    }
}
