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
    @Published var currentDailyTask: DailyTask? = nil

    private var activePlan: Plan?
    private var _allWorkouts: [Workout] = []
    private var _allMeals: [Meal] = []
    
    private var modelContext: ModelContext
    private var profileViewModel: ProfileViewModel

    init(profileViewModel: ProfileViewModel, modelContext: ModelContext) {
        self.profileViewModel = profileViewModel
        self.modelContext = modelContext
        
        refreshData()
    }

    private func refreshData() {
        loadActivePlan()
        filterPlansForSelectedDate()
    }

    private func loadActivePlan() {
        let predicate = #Predicate<Plan> { $0.status == "active" }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        
        self.activePlan = try? modelContext.fetch(descriptor).first
        
        guard let activePlan = self.activePlan else {
            // No active plan, clear current data
            self._allWorkouts = []
            self._allMeals = []
            return
        }
        
        // Directly access workouts and meals from DailyTask relationships
        var workouts: [Workout] = []
        var meals: [Meal] = []
        
        for task in activePlan.dailyTasks {
            workouts.append(contentsOf: task.workouts)
            meals.append(contentsOf: task.meals)
        }
        _allWorkouts = workouts
        _allMeals = meals
        
        filterPlansForSelectedDate()
    }

    func generatePlan(config: PlanConfiguration) {
        archiveOldPlan()

        var generatedWorkouts: [Workout] = []
        var generatedMeals: [Meal] = []
        let startDate = Date()
        let calendar = Calendar.current

        // Convert Set<Weekday> to a Set<Int> that matches Calendar's weekday component (Sunday=1, Monday=2, etc.)
        let trainingWeekdayInts = Set(config.trainingDays.map { weekday -> Int in
            switch weekday {
            case .sunday: return 1
            case .monday: return 2
            case .tuesday: return 3
            case .wednesday: return 4
            case .thursday: return 5
            case .friday: return 6
            case .saturday: return 7
            }
        })

        for dayOffset in 0..<config.planDuration {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let weekday = calendar.component(.weekday, from: date)

            // Schedule workout if the current day is a selected training day
            if trainingWeekdayInts.contains(weekday) {
                var workoutName = "综合训练"
                var baseCalories = 400

                switch config.goal {
                case .fatLoss:
                    workoutName = "减脂有氧"
                    baseCalories = 350
                case .muscleGain:
                    workoutName = "力量增肌"
                    baseCalories = 450
                case .healthImprovement:
                    workoutName = "健康综合"
                    baseCalories = 300
                }

                // Adjust calories based on duration
                let finalCalories = Int(Double(baseCalories) * (Double(config.workoutDurationPerSession) / 45.0))

                let workoutType: WorkoutType
                switch config.goal {
                case .fatLoss:
                    workoutType = .cardio
                case .muscleGain:
                    workoutType = .strength
                case .healthImprovement:
                    workoutType = .other
                }

                let workout = Workout(name: workoutName, durationInMinutes: config.workoutDurationPerSession, caloriesBurned: finalCalories, date: date, type: workoutType)
                generatedWorkouts.append(workout)
                modelContext.insert(workout) // Insert workout into context
            }

            // Add meals for every day
            let meal1 = Meal(name: "健康早餐", calories: 400, date: date, mealType: .breakfast)
            let meal2 = Meal(name: "均衡午餐", calories: 600, date: date, mealType: .lunch)
            let meal3 = Meal(name: "清淡晚餐", calories: 500, date: date, mealType: .dinner)
            generatedMeals.append(meal1)
            generatedMeals.append(meal2)
            generatedMeals.append(meal3)
            modelContext.insert(meal1) // Insert meals into context
            modelContext.insert(meal2)
            modelContext.insert(meal3)
        }
        
        var dailyTasks: [DailyTask] = []
        for dayOffset in 0..<config.planDuration {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let workoutsForDay = generatedWorkouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let mealsForDay = generatedMeals.filter { calendar.isDate($0.date, inSameDayAs: date) }
            
            if !workoutsForDay.isEmpty || !mealsForDay.isEmpty {
                let dailyTask = DailyTask(date: date, workouts: workoutsForDay, meals: mealsForDay)
                dailyTasks.append(dailyTask)
                modelContext.insert(dailyTask) // Insert dailyTask into context
            }
        }
        
        let newPlan = Plan(name: "\(config.planDuration)天\(config.goal.rawValue)计划", goal: config.goal, startDate: startDate, duration: config.planDuration, tasks: dailyTasks, status: "active")
        
        modelContext.insert(newPlan)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save new plan: \(error.localizedDescription)")
        }
        
        refreshData()
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
        
        if let activePlan = activePlan {
            self.currentDailyTask = activePlan.dailyTasks.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        } else {
            self.currentDailyTask = nil
        }
    }
}
