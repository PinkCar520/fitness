import Foundation

// MARK: - Onboarding & Profile Enums

enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
    case fatLoss = "减脂塑形"
    case muscleGain = "增肌与力量"
    case healthImprovement = "提升健康与活力"
    var id: Self { self }
}

// MARK: - Onboarding & Profile Enums

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "男"
    case female = "女"
    case preferNotToSay = "保密"
    var id: Self { self }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg = "公斤 (kg)"
    case lb = "磅 (lb)"
    var id: Self { self }
}

enum HeightUnit: String, Codable, CaseIterable, Identifiable {
    case cm = "厘米 (cm)"
    case inch = "英寸 (inch)"
    var id: Self { self }
}

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "纯新手，刚开始探索"
    case intermediate = "有一定经验，但曾中断过"
    case advanced = "经验丰富，寻求系统性提升"
    var id: Self { self }
}

enum WorkoutLocation: String, Codable, CaseIterable, Identifiable {
    case home = "居家训练"
    case gym = "健身房"
    var id: Self { self }
}

enum HealthCondition: String, Codable, CaseIterable, Identifiable {
    case kneeDiscomfort = "膝盖不适"
    case backPain = "腰部不适"
    case shoulderNeckDiscomfort = "肩颈不适"
    var id: Self { self }
}


enum Interest: String, Codable, CaseIterable, Identifiable {
    case hiit = "高强度间歇训练 (HIIT)"
    case yoga = "瑜伽或普拉提"
    case running = "跑步"
    case strength = "健身房器械"
    case bodyweight = "居家徒手训练"
    var id: Self { self }
}

// Removed old Equipment enum
// enum Equipment: String, Codable, CaseIterable, Identifiable {
//     case yogaMat = "瑜伽垫"
//     case dumbbells = "哑铃"
//     case resistanceBands = "弹力带"
//     case treadmill = "跑步机/单车"
//     var id: Self { self }
// }

enum Motivator: String, Codable, CaseIterable, Identifiable {
    case appearance = "看到身体外形的变化"
    case healthMetrics = "健康指标的改善"
    case achievement = "解锁App内的成就和徽章"
    case social = "朋友或社区的鼓励与监督"
    case stressRelief = "释放压力，改善心情"
    case performance = "提升运动表现"
    var id: Self { self }
}

enum Challenge: String, Codable, CaseIterable, Identifiable {
    case time = "时间不够用"
    case motivation = "缺乏动力，难以坚持"
    case knowledge = "不知道如何正确地做动作"
    case soreness = "锻炼后身体过于酸痛"
    case results = "看不到效果，容易灰心"
    var id: Self { self }
}

enum DietaryHabit: String, Codable, CaseIterable, Identifiable {
    case balanced = "三餐均衡"
    case highProtein = "偏好高蛋白"
    case vegetarian = "素食或纯素"
    case takeout = "经常外卖或快餐"
    case lowCarb = "尝试低碳水"
    case irregular = "饮食不规律"
    var id: Self { self }
}

enum WaterIntake: String, Codable, CaseIterable, Identifiable {
    case low = "很少喝水 (<1L)"
    case medium = "正常饮水 (1-2L)"
    case high = "饮水充足 (>2L)"
    var id: Self { self }

    var recommendedLiters: Double {
        switch self {
        case .low: return 1.0
        case .medium: return 1.6
        case .high: return 2.3
        }
    }
}

enum SleepQuality: String, Codable, CaseIterable, Identifiable {
    case good = "很好，能一觉到天亮"
    case average = "一般，偶尔会醒"
    case poor = "较差，经常失眠或多梦"
    var id: Self { self }
}

struct Benchmark: Codable, Equatable {
    var pushups: Int?
}

struct BodyTypeSelection: Codable, Equatable {
    var current: BodyType?
    var goal: BodyType?
}

enum BodyType: String, Codable, CaseIterable, Identifiable {
    case slim = "偏瘦"
    case toned = "匀称"
    case muscular = "健壮"
    case heavy = "丰满"
    var id: Self { self }
}

// MARK: - UserProfile Struct

struct UserProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var avatarPath: String?
    var gender: Gender
    var dateOfBirth: Date
    var height: Double // in cm by default
    var targetWeight: Double // in kg by default
    var targetDate: Date?
    var weightUnit: WeightUnit
    var heightUnit: HeightUnit
    
    // Notification Settings
    var trainingReminder: Bool
    var recordingReminder: Bool
    var restDayReminder: Bool

    // Onboarding Data
    var goal: FitnessGoal?
    var experienceLevel: ExperienceLevel?
    var workoutLocation: WorkoutLocation?
    var healthConditions: [HealthCondition]?
    var interests: [Interest]?
    var equipment: [EquipmentType]? // Changed to EquipmentType
    var motivators: [Motivator]?
    var challenges: [Challenge]?
    var dietaryHabits: [DietaryHabit]?
    var waterIntake: WaterIntake?
    var sleepQuality: SleepQuality?
    var benchmarks: Benchmark?
    var bodyType: BodyTypeSelection?
    var hasCompletedOnboarding: Bool

    // Default initializer
    init(id: UUID = UUID(),
         name: String = "新用户",
         avatarPath: String? = nil,
         gender: Gender = .preferNotToSay,
         dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date())!,
         height: Double = 170.0,
         targetWeight: Double = 60.0,
         weightUnit: WeightUnit = .kg,
         heightUnit: HeightUnit = .cm,
         targetDate: Date? = nil,
         trainingReminder: Bool = true,
         recordingReminder: Bool = true,
         restDayReminder: Bool = false,
         goal: FitnessGoal? = nil,
         experienceLevel: ExperienceLevel? = nil,
         workoutLocation: WorkoutLocation? = nil,
         healthConditions: [HealthCondition]? = nil,
         interests: [Interest]? = nil,
         equipment: [EquipmentType]? = nil, // Changed to EquipmentType
         motivators: [Motivator]? = nil,
         challenges: [Challenge]? = nil,
         dietaryHabits: [DietaryHabit]? = nil,
         waterIntake: WaterIntake? = nil,
         sleepQuality: SleepQuality? = nil,
         benchmarks: Benchmark? = nil,
         bodyType: BodyTypeSelection? = nil,
         hasCompletedOnboarding: Bool = false) {
        self.id = id
        self.name = name
        self.avatarPath = avatarPath
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.height = height
        self.targetWeight = targetWeight
        self.weightUnit = weightUnit
        self.heightUnit = heightUnit
        self.targetDate = targetDate
        self.trainingReminder = trainingReminder
        self.recordingReminder = recordingReminder
        self.restDayReminder = restDayReminder
        self.goal = goal
        self.experienceLevel = experienceLevel
        self.workoutLocation = workoutLocation
        self.healthConditions = healthConditions
        self.interests = interests
        self.equipment = equipment
        self.motivators = motivators
        self.challenges = challenges
        self.dietaryHabits = dietaryHabits
        self.waterIntake = waterIntake
        self.sleepQuality = sleepQuality
        self.benchmarks = benchmarks
        self.bodyType = bodyType
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
