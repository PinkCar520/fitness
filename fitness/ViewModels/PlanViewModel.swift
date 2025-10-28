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
    
    private var modelContext: ModelContext
    private var profileViewModel: ProfileViewModel
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

    func generatePlan(config: PlanConfiguration, recommendationManager: RecommendationManager) { // Re-added method with recommendationManager argument
        archiveOldPlan() // Archive existing active plan

        // Create a temporary UserProfile for plan generation based on config
        var tempUserProfile = profileViewModel.userProfile // Start with current user profile
        tempUserProfile.goal = config.goal
        tempUserProfile.experienceLevel = config.experienceLevel
        // For manual plan generation, we might need to map more config properties
        // For now, let's assume config provides enough to override/set these.
        // This part needs careful mapping. For now, just use goal and experienceLevel from config.

        // Call the RecommendationManager to generate the plan
        let newPlan = recommendationManager.generateInitialWorkoutPlan(userProfile: tempUserProfile)
        modelContext.insert(newPlan)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save new plan: \(error.localizedDescription)")
        }

        refreshData() // Refresh data to load the new active plan
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
}
