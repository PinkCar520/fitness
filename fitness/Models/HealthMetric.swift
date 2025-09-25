import Foundation
import SwiftData

// Enum to define the type of health metric
enum MetricType: String, Codable, CaseIterable {
    case weight = "体重"
    case bodyFatPercentage = "体脂率"
    case waistCircumference = "腰围"
    // Future types can be added here, e.g.:
    // case height = "身高"
    // case bodyMassIndex = "BMI"
    
    var unit: String {
        switch self {
        case .weight:
            return "kg"
        case .bodyFatPercentage:
            return "%"
        case .waistCircumference:
            return "cm"
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