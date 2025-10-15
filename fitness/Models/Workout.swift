import Foundation
import SwiftData

@Model
final class Workout {
    var name: String
    var durationInMinutes: Int
    var caloriesBurned: Int
    var date: Date

    init(name: String, durationInMinutes: Int, caloriesBurned: Int, date: Date) {
        self.name = name
        self.durationInMinutes = durationInMinutes
        self.caloriesBurned = caloriesBurned
        self.date = date
    }
}
