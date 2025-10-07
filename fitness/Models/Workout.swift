import Foundation

struct Workout: Identifiable, Codable {
    let id = UUID()
    var name: String
    var durationInMinutes: Int
    var caloriesBurned: Int
    var date: Date
}
