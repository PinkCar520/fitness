
import Foundation

// MARK: - Supporting Enums for Exercise Properties

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest = "胸部"
    case back = "背部"
    case shoulders = "肩部"
    case biceps = "肱二头肌"
    case triceps = "肱三头肌"
    case legs = "腿部"
    case glutes = "臀部"
    case core = "核心"
    case cardio = "有氧"
    case fullBody = "全身"
    var id: Self { self }
}

enum EquipmentType: String, Codable, CaseIterable, Identifiable {
    case none = "徒手"
    case dumbbells = "哑铃"
    case resistanceBands = "弹力带"
    case barbell = "杠铃"
    case machine = "器械"
    case cardioMachine = "有氧器械"
    case yogaMat = "瑜伽垫"
    var id: Self { self }
}

enum ExerciseDifficulty: String, Codable, CaseIterable, Identifiable {
    case beginner = "初级"
    case intermediate = "中级"
    case advanced = "高级"
    var id: Self { self }
}

enum ExerciseImpact: String, Codable, CaseIterable, Identifiable {
    case low = "低冲击"
    case medium = "中冲击"
    case high = "高冲击"
    var id: Self { self }
}

// MARK: - Exercise Struct

struct Exercise: Identifiable, Codable, Equatable {
    let id: String // Unique identifier for the exercise, e.g., "dumbbell_squat"
    let name: String // Display name, e.g., "哑铃深蹲"
    let description: String // Detailed description of the exercise
    let videoURL: String? // URL or local asset name for demonstration video
    let targetMuscles: [MuscleGroup] // Primary muscle groups targeted
    let equipmentNeeded: [EquipmentType] // Equipment required for the exercise
    let difficultyLevel: ExerciseDifficulty // Difficulty rating
    let isHighImpact: Bool // True if the exercise is high impact (e.g., jumping)
    let avoidForConditions: [HealthCondition]? // Health conditions for which this exercise should be avoided

    // Default initializer for convenience
    init(id: String, name: String, description: String, videoURL: String? = nil, targetMuscles: [MuscleGroup], equipmentNeeded: [EquipmentType], difficultyLevel: ExerciseDifficulty, isHighImpact: Bool, avoidForConditions: [HealthCondition]? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.videoURL = videoURL
        self.targetMuscles = targetMuscles
        self.equipmentNeeded = equipmentNeeded
        self.difficultyLevel = difficultyLevel
        self.isHighImpact = isHighImpact
        self.avoidForConditions = avoidForConditions
    }
}
