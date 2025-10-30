import Foundation

enum HealthStandards {
    // MARK: - BMI
    enum BMICategory: String { case underweight, normal, overweight, obese }

    static func bmi(_ weightKg: Double, heightCm: Double) -> Double {
        guard heightCm > 0 else { return 0 }
        let h = heightCm / 100.0
        return weightKg / (h * h)
    }

    // WHO primary thresholds, CN as supplemental guidance (not used for category but can be shown)
    static func bmiCategoryWHO(_ bmi: Double) -> BMICategory {
        switch bmi {
        case ..<18.5: return .underweight
        case 18.5..<25: return .normal
        case 25..<30: return .overweight
        default: return .obese
        }
    }

    // MARK: - Waist-to-Hip Ratio (WHR)
    enum WHRRisk: String { case low, moderate, high }

    static func whrRiskWHO(gender: Gender, whr: Double) -> WHRRisk {
        // Common WHO thresholds (adult):
        // Men: low <0.90, moderate 0.90–0.99, high >=1.00
        // Women: low <0.80, moderate 0.80–0.84, high >=0.85
        switch gender {
        case .male:
            if whr < 0.90 { return .low }
            if whr < 1.00 { return .moderate }
            return .high
        case .female:
            if whr < 0.80 { return .low }
            if whr < 0.85 { return .moderate }
            return .high
        case .preferNotToSay:
            // Fallback: use male thresholds conservatively
            if whr < 0.90 { return .low }
            if whr < 1.00 { return .moderate }
            return .high
        }
    }

    // MARK: - VO2max
    enum VO2MaxCategory: String { case veryLow, low, fair, good, excellent }

    static func vo2MaxCategoryWHO(gender: Gender, age: Int, vo2max: Double) -> VO2MaxCategory {
        // Simplified normative ranges aggregated from common exercise physiology tables
        // Values in mL·kg⁻¹·min⁻¹; thresholds vary by age and sex.
        let ageBand: [(upper: Int, bands: (veryLow: Double, low: Double, fair: Double, good: Double))]
        if gender == .male {
            ageBand = [
                (29, (25, 32, 38, 45)),
                (39, (24, 31, 37, 43)),
                (49, (22, 29, 35, 41)),
                (59, (20, 27, 33, 39)),
                (150, (18, 25, 31, 37))
            ]
        } else {
            ageBand = [
                (29, (20, 27, 33, 40)),
                (39, (19, 26, 32, 38)),
                (49, (18, 25, 31, 37)),
                (59, (16, 23, 29, 35)),
                (150, (15, 22, 28, 34))
            ]
        }
        let band = ageBand.first { age <= $0.upper }!.bands
        if vo2max < band.veryLow { return .veryLow }
        if vo2max < band.low { return .low }
        if vo2max < band.fair { return .fair }
        if vo2max < band.good { return .good }
        return .excellent
    }

    // MARK: - Body Fat (simplified bands)
    enum BodyFatBand: String { case athletic, fit, average, high }
    static func bodyFatBand(gender: Gender, value: Double) -> BodyFatBand {
        // Simplified reference bands; can be refined by age if needed
        if gender == .male {
            switch value {
            case ..<10: return .athletic
            case 10..<17: return .fit
            case 17..<25: return .average
            default: return .high
            }
        } else {
            switch value {
            case ..<18: return .athletic
            case 18..<25: return .fit
            case 25..<32: return .average
            default: return .high
            }
        }
    }
}

extension Date {
    var yearsSinceNow: Int { Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0 }
}

