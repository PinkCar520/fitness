import Foundation
import SwiftData
import SwiftUI // Added for Identifiable

// MARK: - Supporting Enums for Plan Configuration

enum Weekday: String, Codable, CaseIterable, Identifiable {
    case monday = "周一"
    case tuesday = "周二"
    case wednesday = "周三"
    case thursday = "周四"
    case friday = "周五"
    case saturday = "周六"
    case sunday = "周日"
    var id: String { self.rawValue }
}



// MARK: - Plan Goal

struct PlanGoal: Codable, Hashable {
    var fitnessGoal: FitnessGoal
    var startWeight: Double
    var targetWeight: Double
    var startDate: Date
    var targetDate: Date?

    var durationInDays: Int {
        guard let targetDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: startDate), to: Calendar.current.startOfDay(for: targetDate)).day ?? 0
    }

    var headline: String {
        let start = String(format: "%.1fkg", startWeight)
        let target = String(format: "%.1fkg", targetWeight)
        return "\(fitnessGoal.rawValue) · \(start) → \(target)"
    }

    /// Returns a baseline weight that reflects the user's state when the plan started.
    /// Falls back to historical weight metrics when the stored `startWeight` is missing
    /// or identical to the target weight (common when no weight was recorded during setup).
    func resolvedStartWeight(from metrics: [HealthMetric]) -> Double {
        let weightMetrics = metrics.filter { $0.type == .weight }
        guard !weightMetrics.isEmpty else { return startWeight }

        let storedStartIsValid = abs(startWeight) > 0.001 && abs(startWeight - targetWeight) > 0.001
        if storedStartIsValid {
            return startWeight
        }

        let startOfPlan = Calendar.current.startOfDay(for: startDate)

        if let baselineBefore = weightMetrics.last(where: { $0.date <= startOfPlan }) {
            return baselineBefore.value
        }

        if let firstAfterStart = weightMetrics.first(where: { $0.date >= startOfPlan }) {
            return firstAfterStart.value
        }

        return weightMetrics.last?.value ?? startWeight
    }
}

@Model
final class Plan {
    @Attribute(.unique) var id: UUID
    var name: String
    private var planGoalData: Data
    var startDate: Date
    var duration: Int // in days
    var status: String // "active" or "archived"
    
    @Relationship(deleteRule: .cascade)
    var dailyTasks: [DailyTask] = []
    
    init(id: UUID = UUID(), name: String, planGoal: PlanGoal, startDate: Date, duration: Int, tasks: [DailyTask], status: String = "active") {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.duration = duration
        self.dailyTasks = tasks
        self.status = status
        if let encodedPlanGoal = try? JSONEncoder().encode(planGoal) {
            self.planGoalData = encodedPlanGoal
        } else {
            self.planGoalData = Data()
            assertionFailure("Failed to encode PlanGoal for persistence.")
        }
    }

    var planGoal: PlanGoal {
        get {
            if let decoded = try? JSONDecoder().decode(PlanGoal.self, from: planGoalData) {
                return decoded
            }
            assertionFailure("Failed to decode PlanGoal from persistent storage.")
            return PlanGoal(fitnessGoal: .healthImprovement, startWeight: 0, targetWeight: 0, startDate: startDate, targetDate: nil)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                planGoalData = encoded
            } else {
                assertionFailure("Failed to encode PlanGoal for persistence. Keeping existing value.")
            }
        }
    }
    
    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? startDate
    }

    var fitnessGoal: FitnessGoal {
        planGoal.fitnessGoal
    }

    var goalHeadline: String {
        planGoal.headline
    }
}

@Model
final class DailyTask: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    
    @Relationship(deleteRule: .cascade) var workouts: [Workout] = []
    @Relationship(deleteRule: .cascade) var meals: [Meal] = []
    
    var isCompleted: Bool = false
    var isSkipped: Bool = false
    
    init(id: UUID = UUID(), date: Date, workouts: [Workout] = [], meals: [Meal] = [], isCompleted: Bool = false, isSkipped: Bool = false) {
        self.id = id
        self.date = date
        self.workouts = workouts
        self.meals = meals
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
    }
}
