import Foundation
import Combine

class PlanViewModel: ObservableObject {
    @Published var selectedDate: Date = Date() {
        didSet { // Trigger update when selectedDate changes
            filterPlansForSelectedDate()
        }
    }
    @Published var workouts: [Workout] = []
    @Published var meals: [Meal] = []

    private var _allWorkouts: [Workout] = [] // Store all generated workouts
    private var _allMeals: [Meal] = []     // Store all generated meals

    private var profileViewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()

    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        setupSubscriptions()
        generatePlan()
        filterPlansForSelectedDate() // Initial filter
    }

    private func setupSubscriptions() {
        profileViewModel.$userProfile
            .sink { [weak self] userProfile in
                self?.generatePlan()
                self?.filterPlansForSelectedDate()
            }
            .store(in: &cancellables)
    }

    func generatePlan() {
        let userProfile = profileViewModel.userProfile
        let workoutFrequency = userProfile.workoutFrequency
        let equipment = userProfile.equipment

        // --- Dynamic Workout Plan Generation Logic ---
        let today = Date()
        let calendar = Calendar.current

        var generatedWorkouts: [Workout] = []

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

        if let userEquipment = equipment, !userEquipment.isEmpty {
            if userEquipment.contains(.dumbbells) {
                if let index = generatedWorkouts.firstIndex(where: { $0.name == "全身力量训练" }) {
                    generatedWorkouts[index].name = "全身力量训练 (含哑铃)"
                }
            }
        }

        self._allWorkouts = generatedWorkouts

        // --- Dynamic Meal Plan Generation Logic ---
        self._allMeals = [
            Meal(name: "燕麦片", calories: 350, date: today, mealType: .breakfast),
            Meal(name: "鸡胸肉沙拉", calories: 500, date: today, mealType: .lunch),
            Meal(name: "三文鱼和蔬菜", calories: 600, date: today, mealType: .dinner),
            Meal(name: "苹果", calories: 95, date: calendar.date(byAdding: .day, value: -1, to: today)!, mealType: .snack),
            Meal(name: "蛋白棒", calories: 200, date: calendar.date(byAdding: .day, value: -1, to: today)!, mealType: .lunch),
        ]
    }

    private func filterPlansForSelectedDate() {
        let calendar = Calendar.current
        workouts = _allWorkouts.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        meals = _allMeals.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }
}

