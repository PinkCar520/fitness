import Foundation
import SwiftData

// Enum to define the type of health metric
enum MetricType: String, Codable, CaseIterable {
    case weight = "体重"
    case bodyFatPercentage = "体脂率"
    case waistCircumference = "腰围"
    case heartRate = "心率"
    case chestCircumference = "胸围"
    case bodyFatMass = "体脂肪量"
    case skeletalMuscleMass = "骨骼肌量"
    case bodyWaterPercentage = "身体水分率"
    case basalMetabolicRate = "基础代谢率"
    case waistToHipRatio = "腰臀比"
    case vo2Max = "VO2max"
    // Future types can be added here, e.g.:
    // case height = "身高"
    // case bodyMassIndex = "BMI"
    
    var unit: String {
        switch self {
        case .weight, .bodyFatMass, .skeletalMuscleMass:
            return "kg"
        case .bodyFatPercentage, .bodyWaterPercentage:
            return "%"
        case .waistCircumference, .chestCircumference:
            return "cm"
        case .heartRate:
            return "bpm"
        case .basalMetabolicRate:
            return "kcal"
        case .waistToHipRatio:
            return ""
        case .vo2Max:
            return "ml/kg/min"
        }
    }
}

@Model
final class HealthMetric: Equatable, Hashable {
    var date: Date
    var value: Double
    var type: MetricType

    init(date: Date, value: Double, type: MetricType) {
        self.date = date
        self.value = value
        self.type = type
    }

    static func == (lhs: HealthMetric, rhs: HealthMetric) -> Bool {
        lhs.date == rhs.date && lhs.value == rhs.value && lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(value)
        hasher.combine(type)
    }
}
