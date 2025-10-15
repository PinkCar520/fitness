import Foundation

// Represents the workout activity for a specific week
struct WeeklyWorkoutActivity: Identifiable {
    let id = UUID()
    let weekOf: Date
    let count: Int
}
