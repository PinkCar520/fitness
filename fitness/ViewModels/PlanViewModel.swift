import Foundation
import Combine
import SwiftData
import SwiftUI

struct PlanWeeklySummary {
    let completionRate: Double
    let completedDays: Int
    let pendingDays: Int
    let skippedDays: Int
    let streakDays: Int
    let totalDays: Int
}

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
    
    private var modelContext: ModelContext
    private var profileViewModel: ProfileViewModel
    private let calendar = Calendar.current
    // private var recommendationManager: RecommendationManager // Removed property

    init(profileViewModel: ProfileViewModel, modelContext: ModelContext) { // Updated init
        self.profileViewModel = profileViewModel
        self.modelContext = modelContext
        // self.recommendationManager = recommendationManager // Removed assignment
        
        refreshData()
    }

    func refreshData() {
        loadActivePlan()
        filterPlansForSelectedDate()
    }

    private func loadActivePlan() {
        let predicate = #Predicate<Plan> { $0.status == "active" }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        
        self.activePlan = try? modelContext.fetch(descriptor).first
        
        guard self.activePlan != nil else {
            // No active plan, clear current data
            self.workouts = []
            self.meals = []
            return
        }
        
        filterPlansForSelectedDate()
    }

    func generatePlanAsync(config: PlanConfiguration, recommendationManager: RecommendationManager) async {
        await MainActor.run {
            generatePlan(config: config, recommendationManager: recommendationManager)
        }
    }

    func generatePlan(config: PlanConfiguration, recommendationManager: RecommendationManager) {
        archiveOldPlan() // Archive existing active plan

        let startOfToday = Calendar.current.startOfDay(for: Date())
        let latestWeight = fetchLatestWeight() ?? config.targetWeight
        let targetDate = Calendar.current.date(byAdding: .day, value: config.planDuration, to: startOfToday)

        // Create goal payload
        let planGoal = PlanGoal(
            fitnessGoal: config.goal,
            startWeight: latestWeight,
            targetWeight: config.targetWeight,
            startDate: startOfToday,
            targetDate: targetDate,
            isProfessionalMode: config.professionalModeEnabled
        )

        // Sync profile state so other features (widgets, onboarding summaries) stay aligned
        profileViewModel.userProfile.goal = config.goal
        profileViewModel.userProfile.targetWeight = config.targetWeight
        profileViewModel.saveProfile()

        // Create a temporary UserProfile for plan generation based on config
        var tempUserProfile = profileViewModel.userProfile
        tempUserProfile.goal = config.goal
        tempUserProfile.experienceLevel = config.experienceLevel

        // Call the RecommendationManager to generate the plan
        let newPlan = recommendationManager.generateInitialWorkoutPlan(
            userProfile: tempUserProfile,
            planGoal: planGoal,
            planDuration: config.planDuration
        )
        modelContext.insert(newPlan)

        do {
            try modelContext.save()
            notifyPlanChange()
        } catch {
            print("Failed to save new plan: \(error.localizedDescription)")
        }

        refreshData() // Refresh data to load the new active plan
    }

    private func fetchLatestWeight() -> Double? {
        var descriptor = FetchDescriptor<HealthMetric>(sortBy: [SortDescriptor(\HealthMetric.date, order: .reverse)])
        descriptor.fetchLimit = 20
        guard let metrics = try? modelContext.fetch(descriptor) else { return nil }
        return metrics.first(where: { $0.type == .weight })?.value
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
        
        guard let activePlan = activePlan else {
            self.workouts = []
            self.meals = []
            self.currentDailyTask = nil
            return
        }

        self.currentDailyTask = activePlan.dailyTasks.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        self.workouts = currentDailyTask?.workouts ?? []
        self.meals = currentDailyTask?.meals ?? []
    }

    func findDailyTask(by id: UUID) -> DailyTask? {
        // Search through all tasks in the active plan
        return activePlan?.dailyTasks.first { $0.id == id }
    }

    @MainActor
    func markTask(_ task: DailyTask, completed: Bool) {
        task.isCompleted = completed
        if completed {
            task.isSkipped = false
        }
        persistChanges()
        filterPlansForSelectedDate()
    }

    @MainActor
    func toggleSkip(for task: DailyTask) {
        task.isSkipped.toggle()
        if task.isSkipped {
            task.isCompleted = false
            task.workouts.forEach { $0.isCompleted = false }
        }
        persistChanges()
        filterPlansForSelectedDate()
    }

    @MainActor
    func toggleWorkoutCompletion(_ workout: Workout) {
        workout.isCompleted.toggle()
        if let task = currentDailyTask {
            if task.workouts.allSatisfy({ $0.isCompleted }) {
                task.isCompleted = true
                task.isSkipped = false
            } else if !workout.isCompleted {
                task.isCompleted = false
            }
        }
        persistChanges()
        filterPlansForSelectedDate()
    }

    private func calculateStreak(from tasks: [DailyTask], upTo date: Date) -> Int {
        let sorted = tasks.sorted { $0.date > $1.date }
        var streak = 0
        var currentDate = calendar.startOfDay(for: date)

        for task in sorted {
            let taskDate = calendar.startOfDay(for: task.date)
            if taskDate == currentDate {
                if task.isCompleted {
                    streak += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            } else if taskDate < currentDate {
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                if taskDate == currentDate && task.isCompleted {
                    streak += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            }
        }

        return streak
    }

    @MainActor
    private func persistChanges() {
        do {
            try modelContext.save()
            notifyPlanChange()
        } catch {
            print("Failed to persist plan changes: \(error)")
        }
    }

    private func notifyPlanChange() {
        NotificationCenter.default.post(name: .planDataDidChange, object: nil)
    }
}
