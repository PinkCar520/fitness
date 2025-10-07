import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snack = "加餐"

    var id: String { self.rawValue }
}

struct Meal: Identifiable, Codable {
    let id = UUID()
    var name: String
    var calories: Int
    var date: Date
    var mealType: MealType
}
