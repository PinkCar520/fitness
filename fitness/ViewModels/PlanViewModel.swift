import Foundation
import Combine

class PlanViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var meals: [Meal] = []

    private var profileViewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()

    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        setupSubscriptions()
        generatePlan()
    }

    private func setupSubscriptions() {
        profileViewModel.$userProfile
            .sink { [weak self] userProfile in
                // Only regenerate if workoutFrequency or equipment changes
                // This is a simplified check, a more robust solution might compare old and new values
                self?.generatePlan()
            }
            .store(in: &cancellables)
    }

    func generatePlan() {
        let userProfile = profileViewModel.userProfile
        let workoutFrequency = userProfile.workoutFrequency
        let equipment = userProfile.equipment

        // --- Dynamic Workout Plan Generation Logic ---
        // This is where you'd implement the logic to create workouts
        // based on workoutFrequency and equipment.
        // For now, I'll keep a simplified version.
        let today = Date()
        let calendar = Calendar.current

        var generatedWorkouts: [Workout] = []

        // Example: If workoutFrequency is 3-4 days, generate 3 workouts
        if workoutFrequency == .threeToFour {
            generatedWorkouts.append(Workout(name: "全身力量训练", durationInMinutes: 60, caloriesBurned: 450, date: calendar.date(byAdding: .day, value: 0, to: today)!))
            generatedWorkouts.append(Workout(name: "有氧跑步", durationInMinutes: 30, caloriesBurned: 300, date: calendar.date(byAdding: .day, value: 2, to: today)!))
            generatedWorkouts.append(Workout(name: "核心与柔韧性", durationInMinutes: 40, caloriesBurned: 200, date: calendar.date(byAdding: .day, value: 4, to: today)!))
        } else if workoutFrequency == .fiveOrMore {
            generatedWorkouts.append(Workout(name: "胸部与三头肌", durationInMinutes: 60, caloriesBurned: 500, date: calendar.date(byAdding: .day, value: 0, to: today)!))
            generatedWorkouts.append(Workout(name: "背部与二头肌", durationInMinutes: 60, caloriesBurned: 500, date: calendar.date(byAdding: .day, value: 1, to: today)!))
            generatedWorkouts.append(Workout(name: "腿部与肩部", durationInMinutes: 75, caloriesBurned: 600, date: calendar.date(byAdding: .day, value: 2, to: today)!))
            generatedWorkouts.append(Workout(name: "高强度间歇训练", durationInMinutes: 30, caloriesBurned: 400, date: calendar.date(byAdding: .day, value: 3, to: today)!))
            generatedWorkouts.append(Workout(name: "瑜伽与恢复", durationInMinutes: 45, caloriesBurned: 250, date: calendar.date(byAdding: .day, value: 4, to: today)!))
        } else { // Default to 1-2 days or if nil
            generatedWorkouts.append(Workout(name: "全身基础训练", durationInMinutes: 45, caloriesBurned: 350, date: calendar.date(byAdding: .day, value: 0, to: today)!))
            generatedWorkouts.append(Workout(name: "轻度有氧", durationInMinutes: 25, caloriesBurned: 200, date: calendar.date(byAdding: .day, value: 3, to: today)!))
        }

        // Further refine workouts based on equipment
        if let userEquipment = equipment, !userEquipment.isEmpty {
            // Example: If user has dumbbells, add dumbbell exercises
            if userEquipment.contains(.dumbbells) {
                // Modify existing workouts or add new ones
                if let index = generatedWorkouts.firstIndex(where: { $0.name == "全身力量训练" }) {
                    generatedWorkouts[index].name = "全身力量训练 (含哑铃)"
                }
            }
        }

        self.workouts = generatedWorkouts

        // --- Dynamic Meal Plan Generation Logic ---
        // For now, keeping mock meals, but this would also be dynamic
        self.meals = [
            Meal(name: "燕麦片", calories: 350, date: today, mealType: .breakfast),
            Meal(name: "鸡胸肉沙拉", calories: 500, date: today, mealType: .lunch),
            Meal(name: "三文鱼和蔬菜", calories: 600, date: today, mealType: .dinner),
            Meal(name: "苹果", calories: 95, date: calendar.date(byAdding: .day, value: -1, to: today)!, mealType: .snack),
            Meal(name: "蛋白棒", calories: 200, date: calendar.date(byAdding: .day, value: -1, to: today)!, mealType: .lunch),
        ]
    }
}

