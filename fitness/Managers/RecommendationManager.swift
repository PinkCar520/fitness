
import Foundation
import Combine
import SwiftData // For Plan and DailyTask

class RecommendationManager: ObservableObject {
    @Published var recommendedContent: [String] = []
    private var allExercises: [Exercise]

    private var profileViewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()

    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        self.allExercises = ExerciseDataLoader.loadExercises()
        setupSubscriptions()
        generateRecommendations()
    }

    private func setupSubscriptions() {
        profileViewModel.$userProfile
            .sink { [weak self] userProfile in
                self?.generateRecommendations()
                // Potentially trigger workout plan generation here in the future
            }
            .store(in: &cancellables)
    }

    func generateRecommendations() {
        let dietaryHabits = profileViewModel.userProfile.dietaryHabits

        var newRecommendations: [String] = []

        if let habits = dietaryHabits, !habits.isEmpty {
            if habits.contains(.vegetarian) || habits.contains(.balanced) {
                newRecommendations.append("探索素食食谱")
                newRecommendations.append("健康均衡餐指南")
            }
            if habits.contains(.highProtein) {
                newRecommendations.append("高蛋白增肌餐")
                newRecommendations.append("蛋白质补充剂推荐")
            }
            if habits.contains(.lowCarb) {
                newRecommendations.append("低碳水食谱合集")
                newRecommendations.append("生酮饮食入门")
            }
            if habits.contains(.takeout) || habits.contains(.irregular) {
                newRecommendations.append("15分钟快手健康餐")
                newRecommendations.append("外卖健康选择攻略")
            }
        } else {
            newRecommendations.append("个性化饮食推荐")
            newRecommendations.append("从这里开始健康饮食")
        }
        self.recommendedContent = newRecommendations
    }

    func generateInitialWorkoutPlan(userProfile: UserProfile, planGoal: PlanGoal, planDuration: Int) -> Plan {
        var filteredExercises = allExercises

        // 1. Filter by Workout Location
        if let location = userProfile.workoutLocation {
            filteredExercises = filteredExercises.filter { exercise in
                switch location {
                case .home:
                    // For home workouts, only allow exercises that require no equipment or common home equipment
                    return exercise.equipmentNeeded.contains(.none) ||
                           exercise.equipmentNeeded.contains(.yogaMat) ||
                           exercise.equipmentNeeded.contains(.resistanceBands) ||
                           exercise.equipmentNeeded.contains(.dumbbells)
                case .gym:
                    // For gym workouts, allow all exercises (assuming gym has all equipment)
                    return true
                }
            }
        }

        // 2. Filter by User's Available Equipment (if specified and not empty)
        if let userEquipment = userProfile.equipment, !userEquipment.isEmpty {
            filteredExercises = filteredExercises.filter { exercise in
                // An exercise is suitable if it requires no equipment OR all its required equipment is available to the user
                exercise.equipmentNeeded.contains(.none) ||
                exercise.equipmentNeeded.allSatisfy { requiredEquipment in
                    userEquipment.contains(requiredEquipment)
                }
            }
        }

        // 3. Filter by Health Conditions
        if let healthConditions = userProfile.healthConditions, !healthConditions.isEmpty {
            filteredExercises = filteredExercises.filter { exercise in
                // An exercise is suitable if it's not high impact AND doesn't have any avoidForConditions that match user's conditions
                // If exercise is high impact, it must not be avoided for any of the user's conditions
                if exercise.isHighImpact {
                    return !healthConditions.contains(where: { userCondition in
                        exercise.avoidForConditions?.contains(userCondition) ?? false
                    })
                } else {
                    // If not high impact, check if it's specifically avoided for any condition
                    return !healthConditions.contains(where: { userCondition in
                        exercise.avoidForConditions?.contains(userCondition) ?? false
                    })
                }
            }
        }

        // 4. Select Exercises based on Goal and Experience Level
        // var selectedWorkouts: [Workout] = [] // Removed unused variable
        let goal = userProfile.goal ?? .healthImprovement // Default to health improvement
        let experienceLevel = userProfile.experienceLevel ?? .beginner // Default to beginner

        // Determine target number of strength and cardio exercises
        var targetStrengthExercises = 3
        var targetCardioExercises = 0

        switch goal {
        case .fatLoss:
            targetStrengthExercises = 3
            targetCardioExercises = 2
        case .muscleGain:
            targetStrengthExercises = 5
            targetCardioExercises = 0
        case .healthImprovement:
            targetStrengthExercises = 3
            targetCardioExercises = 1
        }

        // Filter exercises by difficulty matching user's experience level
        let suitableExercises = filteredExercises.filter { exercise in
            switch experienceLevel {
            case .beginner:
                return exercise.difficultyLevel == .beginner
            case .intermediate:
                return exercise.difficultyLevel == .beginner || exercise.difficultyLevel == .intermediate
            case .advanced:
                return true // All difficulties are suitable for advanced
            }
        }

        // Separate strength and cardio exercises
        let strengthExercises = suitableExercises.filter { $0.targetMuscles.contains(.chest) || $0.targetMuscles.contains(.back) || $0.targetMuscles.contains(.shoulders) || $0.targetMuscles.contains(.legs) || $0.targetMuscles.contains(.glutes) || $0.targetMuscles.contains(.core) || $0.targetMuscles.contains(.fullBody) }
        let cardioExercises = suitableExercises.filter { $0.targetMuscles.contains(.cardio) || ($0.targetMuscles.contains(.fullBody) && $0.isHighImpact) } // Simple heuristic for cardio

        // Select strength exercises
        var chosenStrengthExercises: [Exercise] = []
        chosenStrengthExercises = Array(strengthExercises.shuffled().prefix(targetStrengthExercises))


        // Select cardio exercises
        var chosenCardioExercises: [Exercise] = []
        chosenCardioExercises = Array(cardioExercises.shuffled().prefix(targetCardioExercises))


        // 5. Construct DailyTask and Plan Objects
        let today = Calendar.current.startOfDay(for: planGoal.startDate)
        var dailyTasks: [DailyTask] = []

        // For MVP, create 3 workout days in a week
        let workoutDays = [today, Calendar.current.date(byAdding: .day, value: 2, to: today)!, Calendar.current.date(byAdding: .day, value: 4, to: today)!]

        for day in workoutDays {
            var dailyWorkouts: [Workout] = []

            // Configure strength workouts
            for exercise in chosenStrengthExercises {
                var sets: [WorkoutSet] = []
                var numSets: Int
                var minReps: Int
                var maxReps: Int

                switch experienceLevel {
                case .beginner:
                    numSets = 3
                    minReps = 12
                    maxReps = 15
                case .intermediate:
                    numSets = 4
                    minReps = 8
                    maxReps = 12
                case .advanced:
                    numSets = 5
                    minReps = 6
                    maxReps = 10
                }

                for _ in 0..<numSets {
                    // For MVP, weight can be nil, reps can be a range midpoint
                    sets.append(WorkoutSet(reps: (minReps + maxReps) / 2, weight: nil))
                }

                let workout = Workout(name: exercise.name, durationInMinutes: 5, caloriesBurned: 50, date: day, type: .strength, sets: sets)
                dailyWorkouts.append(workout)
            }

            // Configure cardio workouts
            for exercise in chosenCardioExercises {
                let duration = (experienceLevel == .beginner) ? 20 : 30 // minutes
                let workout = Workout(name: exercise.name, durationInMinutes: duration, caloriesBurned: duration * 8, date: day, type: .cardio, duration: Double(duration * 60)) // duration in seconds
                dailyWorkouts.append(workout)
            }

            // Ensure we have at least one workout if possible
            if dailyWorkouts.isEmpty && !filteredExercises.isEmpty {
                if let fallbackExercise = filteredExercises.randomElement() {
                    let workout = Workout(name: fallbackExercise.name, durationInMinutes: 20, caloriesBurned: 100, date: day, type: .other)
                    dailyWorkouts.append(workout)
                }
            }
            
            let task = DailyTask(date: day, workouts: dailyWorkouts) // Use the new set of workouts for each day
            dailyTasks.append(task)
        }

        let planName = "\(userProfile.name)的\(planGoal.fitnessGoal.rawValue)计划"
        let plan = Plan(name: planName, planGoal: planGoal, startDate: today, duration: planDuration, tasks: dailyTasks)

        return plan
    }
}
