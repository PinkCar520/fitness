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
    
    // Store full Workout/Meal objects as JSON data
    var workoutsData: Data?
    var mealsData: Data? // Store an array of meals for the day
    
    init(date: Date, workouts: [Workout] = [], meals: [Meal] = []) {
        self.date = date
        
        if !workouts.isEmpty {
            self.workoutsData = try? JSONEncoder().encode(workouts)
        }
        
        if !meals.isEmpty {
            self.mealsData = try? JSONEncoder().encode(meals)
        }
    }
}
