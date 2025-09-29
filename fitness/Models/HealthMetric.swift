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
        }
    }
}

@Model
final class HealthMetric {
    var date: Date
    var value: Double
    var type: MetricType

    init(date: Date, value: Double, type: MetricType) {
        self.date = date
        self.value = value
        self.type = type
    }
}