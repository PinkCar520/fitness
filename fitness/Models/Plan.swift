import Foundation
import SwiftData

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
final class DailyTask {
    var date: Date
    
    @Relationship(deleteRule: .cascade) var workouts: [Workout] = []
    @Relationship(deleteRule: .cascade) var meals: [Meal] = []
    
    init(date: Date, workouts: [Workout] = [], meals: [Meal] = []) {
        self.date = date
        self.workouts = workouts
        self.meals = meals
    }
}
