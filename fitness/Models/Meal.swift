import Foundation

enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snack = "加餐"

    var id: String { self.rawValue }
}

struct Meal: Identifiable {
    let id = UUID()
    var name: String
    var calories: Int
    var date: Date
    var mealType: MealType
}
