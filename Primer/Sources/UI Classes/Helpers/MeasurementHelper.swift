//
//  MeasurementHelper.swift
//  Primer
//
//  Created by Sarah Hurtgen on 10/23/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import Foundation

/**
 Initialize `width` and `height` to access readable calculations of various swatch measurements.
 */
struct MeasurementHelper {
    
    var width: Float?
    var height: Float?
    
    var stringWidth: String {
        return self.measurementFrom(width)
    }
    var stringHeight: String {
        return self.measurementFrom(height)
    }
    var squaredFeet: String {
        return self.squaredUnit(.feet, unit: .foot)
    }
    var squaredMeters: String {
        return self.squaredUnit(.meters, unit: .meter)
    }
    
    var gallons: String {
        return self.calculatedGallons()
    }

    var splitFormatter: LengthFormatter {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        formatter.isForPersonHeightUse = true
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }
    
    var decimalFormatter: LengthFormatter {
        let formatter = LengthFormatter()
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter
    }
   
    // MARK: - Functions
    
    func measurementFrom(_ meters: Float?) -> String {
        let metersAsDouble = Double(meters ?? 0)

        if Locale.current.usesMetricSystem {
            return splitFormatter.string(fromMeters: metersAsDouble)
        } else {
            // avoid the bug where splitFormatter would return 1' 12" instead of 2' 0"

            // convert meters to inches (multiply by 39.370) and calculate how many feet total
            let totalFeet = (metersAsDouble * 39.370) / 12.0

            // grab remaining feet decimal and convert back to inches
            let remainderInInches = (totalFeet - totalFeet.rounded(.down)) * 12

            // round foot value up if remaining inches pass 11.5
            if remainderInInches >= 11.5 {
                return "\(Int(totalFeet) + 1)‘ 0“"
            } else {
                return splitFormatter.string(fromMeters: metersAsDouble)
            }
        }
    }
    
    func squaredUnit(_ unitLength: UnitLength, unit: LengthFormatter.Unit) -> String {
        // confirm we have active measurements
        guard let width = width, let height = height else {
            return "\(decimalFormatter.string(fromValue: 0, unit: unit))²"
        }
        // calculate the the squared meter amount
        let metersSquared = Double(width * height)

        // if desired unit is already meters, calculate and return
        if unit == .meter {
            // format string
            return "\(decimalFormatter.string(fromValue: metersSquared, unit: .meter))²"
        } else {
            // convert from square meter to square feet by multiplying by 10.76391041671
            let squaredUnit = metersSquared * 10.76391041671
            
            // format string
            return "\(decimalFormatter.string(fromValue: squaredUnit, unit: unit))²"
        }
    }
    
    func calculatedGallons() -> String {
        // confirm we have active measurements
        guard let width = self.width, let height = self.height else {
            return "0"
        }

        // calculate square meters
        let squareMeters = width * height

        // convert from square meter to square feet by multiplying by 10.76391041671
        let squareFeet = squareMeters * 10.76391041671

        // times squareFeet by 400
        let requiredGallons = squareFeet / 400

        // restrict decimals, always round up to avoid displaying "0" gallons on small swatch
        return String(format: "%.2f", ceil(requiredGallons * 100) / 100)
    }
}
