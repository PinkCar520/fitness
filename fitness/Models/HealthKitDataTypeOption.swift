
import Foundation
import HealthKit

enum HealthKitDataTypeOption: CaseIterable, Identifiable {
    case bodyMass
    case bodyFatPercentage
    case waistCircumference
    case stepCount
    case distanceWalkingRunning
    case activeEnergyBurned
    case appleExerciseTime
    case workout
    case heartRate
    case sleepAnalysis
    case vo2Max

    var id: Self { self }

    var title: String {
        switch self {
        case .bodyMass:
            return "体重"
        case .bodyFatPercentage:
            return "体脂率"
        case .waistCircumference:
            return "腰围"
        case .stepCount:
            return "步数"
        case .distanceWalkingRunning:
            return "步行+跑步距离"
        case .activeEnergyBurned:
            return "活动能量"
        case .appleExerciseTime:
            return "锻炼分钟数"
        case .workout:
            return "体能训练"
        case .heartRate:
            return "心率"
        case .sleepAnalysis:
            return "睡眠分析"
        case .vo2Max:
            return "VO2max"
        }
    }

    var description: String {
        switch self {
        case .bodyMass:
            return "用于跟踪您的体重变化，帮助您实现减重或增重目标。"
        case .bodyFatPercentage:
            return "监测身体成分，更精确地了解您的健康状况。"
        case .waistCircumference:
            return "作为评估内脏脂肪和相关健康风险的指标。"
        case .stepCount:
            return "记录每日步数，鼓励您保持活跃。"
        case .distanceWalkingRunning:
            return "追踪您步行和跑步的距离，量化您的运动成果。"
        case .activeEnergyBurned:
            return "估算您在活动中消耗的卡路里，帮助您管理能量平衡。"
        case .appleExerciseTime:
            return "记录您每天的锻炼时长，确保达到运动目标。"
        case .workout:
            return "从其他应用或设备导入体能训练数据，全面记录您的运动历史。"
        case .heartRate:
            return "记录您的心率数据，帮助您监测心血管健康。"
        case .sleepAnalysis:
            return "分析您的睡眠模式和质量，改善睡眠健康。"
        case .vo2Max:
            return "最大摄氧量，反映心肺耐力水平。"
        }
    }

    var hkObjectType: HKObjectType? {
        switch self {
        case .bodyMass:
            return HKObjectType.quantityType(forIdentifier: .bodyMass)
        case .bodyFatPercentage:
            return HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)
        case .waistCircumference:
            return HKObjectType.quantityType(forIdentifier: .waistCircumference)
        case .stepCount:
            return HKObjectType.quantityType(forIdentifier: .stepCount)
        case .distanceWalkingRunning:
            return HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
        case .activeEnergyBurned:
            return HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        case .appleExerciseTime:
            return HKObjectType.quantityType(forIdentifier: .appleExerciseTime)
        case .workout:
            return HKObjectType.workoutType()
        case .heartRate:
            return HKObjectType.quantityType(forIdentifier: .heartRate)
        case .sleepAnalysis:
            return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        case .vo2Max:
            return HKObjectType.quantityType(forIdentifier: .vo2Max)
        }
    }
}
