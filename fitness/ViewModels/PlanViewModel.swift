import Foundation

class PlanViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var meals: [Meal] = []

    init() {
        generateMockData()
    }

    func generateMockData() {
        let today = Date()
        let calendar = Calendar.current

        // Mock Workouts for the week
        self.workouts = [
            Workout(name: "跑步", durationInMinutes: 30, caloriesBurned: 300, date: calendar.date(byAdding: .day, value: -2, to: today)!),
            Workout(name: "举重", durationInMinutes: 60, caloriesBurned: 400, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            Workout(name: "瑜伽", durationInMinutes: 45, caloriesBurned: 200, date: today)
        ]

        // Mock Meals for the week
        self.meals = [
            Meal(name: "燕麦片", calories: 350, date: today, mealType: .breakfast),
            Meal(name: "鸡胸肉沙拉", calories: 500, date: today, mealType: .lunch),
            Meal(name: "三文鱼和蔬菜", calories: 600, date: today, mealType: .dinner),
            Meal(name: "苹果", calories: 95, date: calendar.date(byAdding: .day, value: -1, to: today)!, mealType: .snack),
            Meal(name: "蛋白棒", calories: 200, date: calendar.date(byAdding: .day, value: -1, to: today)!, mealType: .lunch),
        ]
    }
}
