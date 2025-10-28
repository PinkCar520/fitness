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



@Model
final class Plan {
    @Attribute(.unique) var id: UUID
    var name: String
    var goal: String // Storing the raw value of FitnessGoal
    var startDate: Date
    var duration: Int // in days
    var status: String // "active" or "archived"
    
    @Relationship(deleteRule: .cascade)
    var dailyTasks: [DailyTask] = []
    
    init(id: UUID = UUID(), name: String, goal: FitnessGoal, startDate: Date, duration: Int, tasks: [DailyTask], status: String = "active") {
        self.id = id
        self.name = name
        self.goal = goal.rawValue
        self.startDate = startDate
        self.duration = duration
        self.dailyTasks = tasks
        self.status = status
    }
    
    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? startDate
    }
}

@Model
final class DailyTask: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    
    @Relationship(deleteRule: .cascade) var workouts: [Workout] = []
    @Relationship(deleteRule: .cascade) var meals: [Meal] = []
    
    var isCompleted: Bool = false
    
    init(id: UUID = UUID(), date: Date, workouts: [Workout] = [], meals: [Meal] = [], isCompleted: Bool = false) {
        self.id = id
        self.date = date
        self.workouts = workouts
        self.meals = meals
        self.isCompleted = isCompleted
    }
}
