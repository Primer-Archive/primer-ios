//
//  HalfSquareTriangle.swift
//  Primer
//
//  Created by Sarah Hurtgen on 1/25/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import SwiftUI

// MARK: - Half Square Triangle

/**
 Stack two together (init the bottom as `isTopHalf = false`) to output a "rectangle" style shape that has an extra triangular point towards the right.
 
 The triangle point defaults to 20 width but can be customized using `pointWidth`.
 
 Slight rounding of corners leading into triangle is based off percentages of the rect's width and height.
 */
struct HalfSquareTriangle: Shape {
    var isTopHalf: Bool = true
    var pointWidth: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let xOffset: CGFloat = rect.maxX - pointWidth
        let yOffset: CGFloat = rect.height * 0.02
        let curveIntensity: CGFloat = xOffset * 0.03
        
        if isTopHalf {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: xOffset, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: xOffset + curveIntensity, y: yOffset), control: CGPoint(x: xOffset + curveIntensity, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: xOffset, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: xOffset + curveIntensity, y: rect.maxY - yOffset), control: CGPoint(x: xOffset + curveIntensity, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        }
        
        return path
    }
}

// MARK: - Progress Step Shape

/**
 Stacks two `HalfSquareTriangle` shapes together to form a pentagon that points to the right.
 */
struct ProgressStepShape: View {
    var fillColor: Color
    var width: CGFloat?
    var height: CGFloat?
    var customPointWidth: CGFloat?

    // MARK: - Body
    
    var body: some View {
        ZStack {
            HalfSquareTriangle(isTopHalf: true, pointWidth: customPointWidth ?? 20)
                .fill(fillColor)
                .frame(width: width, height: height)
            HalfSquareTriangle(isTopHalf: false, pointWidth: customPointWidth ?? 20)
                .fill(fillColor)
                .frame(width: width, height: height)
        }
    }
}

// MARK: - Preview

struct HalfSquareTriangle_Previews: PreviewProvider {
    static var previews: some View {
        ProgressStepShape(fillColor: BrandColors.navy.color, width: 200, height: 30)
    }
}
