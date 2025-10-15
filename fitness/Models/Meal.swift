import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snack = "加餐"

    var id: String { self.rawValue }
}

@Model
final class Meal {
    var name: String
    var calories: Int
    var date: Date
    var mealType: MealType

    init(name: String, calories: Int, date: Date, mealType: MealType) {
        self.name = name
        self.calories = calories
        self.date = date
        self.mealType = mealType
    }
}
