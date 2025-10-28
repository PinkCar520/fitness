import Foundation
import SwiftData

// The new enum for classifying workouts
enum WorkoutType: String, Codable {
    case strength = "Strength"
    case cardio = "Cardio"
    case flexibility = "Flexibility"
    case other = "Other"
}

// The new struct for detailed set tracking in strength workouts
struct WorkoutSet: Codable, Hashable {
    var reps: Int
    var weight: Double? // Changed to optional
    var isCompleted: Bool? = false
}

@Model
final class Workout {
    // Existing properties
    var name: String
    var durationInMinutes: Int? // Changed to optional
    var caloriesBurned: Int
    var date: Date
    
    // New mandatory property for classification
    var type: WorkoutType
    
    // New optional properties for detailed logging
    var distance: Double? // For Cardio
    var duration: Double? // For Cardio (more precise than durationInMinutes)
    var sets: [WorkoutSet]? // For Strength
    var notes: String? // For Other/General

    var isCompleted: Bool = false

    var dailyTaskID: UUID? // Link to the DailyTask

    // Updated initializer
    init(name: String,
         durationInMinutes: Int? = nil, // Changed to optional with default nil
         caloriesBurned: Int,
         date: Date,
         type: WorkoutType,
         distance: Double? = nil,
         duration: Double? = nil,
         sets: [WorkoutSet]? = nil,
         notes: String? = nil,
         isCompleted: Bool = false,
         dailyTaskID: UUID? = nil) { // Added dailyTaskID
        self.name = name
        self.durationInMinutes = durationInMinutes
        self.caloriesBurned = caloriesBurned
        self.date = date
        self.type = type
        self.distance = distance
        self.duration = duration
        self.sets = sets
        self.notes = notes
        self.isCompleted = isCompleted
        self.dailyTaskID = dailyTaskID // Added assignment
    }
}

