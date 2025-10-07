import Foundation
import Combine
import SwiftData

class PlanViewModel: ObservableObject {
    @Published var selectedDate: Date = Date() {
        didSet {
            filterPlansForSelectedDate()
        }
    }
    @Published var workouts: [Workout] = []
    @Published var meals: [Meal] = []

    private var _allWorkouts: [Workout] = []
    private var _allMeals: [Meal] = []
    
    private var modelContext: ModelContext
    private var profileViewModel: ProfileViewModel

    init(profileViewModel: ProfileViewModel, modelContext: ModelContext) {
        self.profileViewModel = profileViewModel
        self.modelContext = modelContext
        
        loadActivePlan()
    }

    private func loadActivePlan() {
        let predicate = #Predicate<Plan> { $0.status == "active" }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        
        guard let activePlan = try? modelContext.fetch(descriptor).first else {
            // No active plan, clear current data
            self._allWorkouts = []
            self._allMeals = []
            self.filterPlansForSelectedDate()
            return
        }
        
        var workouts: [Workout] = []
        var meals: [Meal] = []
        
        let decoder = JSONDecoder()
        
        for task in activePlan.dailyTasks {
            if let workoutData = task.workoutsData,
               let dailyWorkouts = try? decoder.decode([Workout].self, from: workoutData) {
                workouts.append(contentsOf: dailyWorkouts)
            }
            if let mealsData = task.mealsData,
               let dailyMeals = try? decoder.decode([Meal].self, from: mealsData) {
                meals.append(contentsOf: dailyMeals)
            }
        }
        _allWorkouts = workouts
        _allMeals = meals
        
        filterPlansForSelectedDate()
    }

    func generatePlan(goal: FitnessGoal, duration: Int) {
        archiveOldPlan()

        var generatedWorkouts: [Workout] = []
        var generatedMeals: [Meal] = []
        let startDate = Date()
        let calendar = Calendar.current

        for dayOffset in 0..<duration {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let weekday = calendar.component(.weekday, from: date)

            switch goal {
            case .fatLoss:
                if weekday == 2 || weekday == 4 || weekday == 6 {
                    generatedWorkouts.append(Workout(name: "减脂有氧", durationInMinutes: 45, caloriesBurned: 350, date: date))
                }
            case .muscleGain:
                if weekday == 2 { generatedWorkouts.append(Workout(name: "胸部 & 三头肌", durationInMinutes: 60, caloriesBurned: 450, date: date)) }
                if weekday == 3 { generatedWorkouts.append(Workout(name: "背部 & 二头肌", durationInMinutes: 60, caloriesBurned: 450, date: date)) }
                if weekday == 5 { generatedWorkouts.append(Workout(name: "腿部 & 肩部", durationInMinutes: 70, caloriesBurned: 550, date: date)) }
                if weekday == 6 { generatedWorkouts.append(Workout(name: "核心 & 全身", durationInMinutes: 50, caloriesBurned: 400, date: date)) }
            case .healthImprovement:
                if weekday == 3 || weekday == 5 || weekday == 7 {
                    generatedWorkouts.append(Workout(name: "全身综合训练", durationInMinutes: 50, caloriesBurned: 400, date: date))
                }
            }
            generatedMeals.append(Meal(name: "健康早餐", calories: 400, date: date, mealType: .breakfast))
            generatedMeals.append(Meal(name: "均衡午餐", calories: 600, date: date, mealType: .lunch))
            generatedMeals.append(Meal(name: "清淡晚餐", calories: 500, date: date, mealType: .dinner))
        }
        
        var dailyTasks: [DailyTask] = []
        for dayOffset in 0..<duration {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let workoutsForDay = generatedWorkouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let mealsForDay = generatedMeals.filter { calendar.isDate($0.date, inSameDayAs: date) }
            
            if !workoutsForDay.isEmpty || !mealsForDay.isEmpty {
                dailyTasks.append(DailyTask(date: date, workouts: workoutsForDay, meals: mealsForDay))
            }
        }
        
        let newPlan = Plan(name: "\(duration)天\(goal.rawValue)计划", goal: goal, startDate: startDate, duration: duration, tasks: dailyTasks, status: "active")
        
        modelContext.insert(newPlan)
        
        _allWorkouts = generatedWorkouts
        _allMeals = generatedMeals
        filterPlansForSelectedDate()
    }

    private func archiveOldPlan() {
        let predicate = #Predicate<Plan> { $0.status == "active" }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        if let activePlans = try? modelContext.fetch(descriptor) {
            for plan in activePlans {
                plan.status = "archived"
            }
        }
    }

    private func filterPlansForSelectedDate() {
        let calendar = Calendar.current
        workouts = _allWorkouts.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        meals = _allMeals.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }
}

