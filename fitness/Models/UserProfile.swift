import Foundation

// MARK: - Enums for UserProfile

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "男"
    case female = "女"
    case preferNotToSay = "保密"

    var id: String { self.rawValue }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary = "久坐 (很少或没有运动)"
    case light = "轻度活跃 (每周1-3天轻度运动)"
    case moderate = "中度活跃 (每周3-5天中度运动)"
    case active = "非常活跃 (每周6-7天剧烈运动)"

    var id: String { self.rawValue }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg = "公斤 (kg)"
    case lb = "磅 (lb)"

    var id: String { self.rawValue }
}

enum HeightUnit: String, Codable, CaseIterable, Identifiable {
    case cm = "厘米 (cm)"
    case inch = "英寸 (inch)"

    var id: String { self.rawValue }
}

// MARK: - UserProfile Struct

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var gender: Gender
    var dateOfBirth: Date
    var height: Double // in cm by default
    var targetWeight: Double // in kg by default
    var activityLevel: ActivityLevel
    var weightUnit: WeightUnit
    var heightUnit: HeightUnit

    // Default initializer
    init(id: UUID = UUID(),
         name: String = "新用户",
         gender: Gender = .preferNotToSay,
         dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date())!, // Default to 25 years ago
         height: Double = 170.0, // Default to 170 cm
         targetWeight: Double = 60.0, // Default to 60 kg
         activityLevel: ActivityLevel = .sedentary,
         weightUnit: WeightUnit = .kg,
         heightUnit: HeightUnit = .cm) {
        self.id = id
        self.name = name
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.height = height
        self.targetWeight = targetWeight
        self.activityLevel = activityLevel
        self.weightUnit = weightUnit
        self.heightUnit = heightUnit
    }
}
