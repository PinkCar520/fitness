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

struct PlanInsightItem: Identifiable, Equatable {
    enum Intent: Equatable {
        case startWorkout
        case logWeight
        case reviewMeals
        case none
    }

    let id = UUID()
    let title: String
    let message: String
    let tone: InsightCard.Tone
    let intent: Intent
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
    @Published var insights: [PlanInsightItem] = []

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
            targetDate: targetDate
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

    // Weekly summary calculation migrated to Shared/WeeklySummaryCalculator

    func refreshInsights(weightMetrics: [HealthMetric]) {
        insights = buildInsights(weightMetrics: weightMetrics)
    }

    private func buildInsights(weightMetrics: [HealthMetric]) -> [PlanInsightItem] {
        var items: [PlanInsightItem] = []

        guard let plan = activePlan else {
            items.append(
                PlanInsightItem(
                    title: "还没有训练计划",
                    message: "立即制定个人目标，系统会生成本周训练与饮食安排。",
                    tone: .informational,
                    intent: .none
                )
            )
            return items
        }

        if let task = currentDailyTask {
            if task.isSkipped {
                items.append(
                    PlanInsightItem(
                        title: "今日任务已跳过",
                        message: "如果状态恢复不错，可以重新安排轻量训练或进行伸展恢复。",
                        tone: .warning,
                        intent: .startWorkout
                    )
                )
            } else if task.workouts.isEmpty {
                items.append(
                    PlanInsightItem(
                        title: "今日是休息日",
                        message: "休息同样重要，保持充足睡眠与营养补给，为下一次训练做好准备。",
                        tone: .positive,
                        intent: .none
                    )
                )
            } else if !task.isCompleted {
                items.append(
                    PlanInsightItem(
                        title: "今日训练待完成",
                        message: "完成今日 \(task.workouts.count) 项训练，保持连续性让成果更稳固。",
                        tone: .informational,
                        intent: .startWorkout
                    )
                )
            }

            if !task.meals.isEmpty && task.meals.allSatisfy({ !$0.isCompleted }) {
                items.append(
                    PlanInsightItem(
                        title: "别忘了记录饮食",
                        message: "完成餐食计划有助于维持能量均衡，及时补记今天的饮食安排。",
                        tone: .informational,
                        intent: .reviewMeals
                    )
                )
            }
        } else {
            items.append(
                PlanInsightItem(
                    title: "选择训练日期",
                    message: "在日历中选择一个日期查看训练详情，保持每周的节奏。",
                    tone: .informational,
                    intent: .none
                )
            )
        }

        if let weightInsight = weightTrendInsight(from: weightMetrics) {
            items.append(weightInsight)
        }

        // Removed weekly summary based insights; widget handles weekly summary presentation

        if items.isEmpty {
            items.append(
                PlanInsightItem(
                    title: "保持节奏",
                    message: "你的计划执行良好，继续按照节奏完成训练与饮食。",
                    tone: .positive,
                    intent: .none
                )
            )
        }

        return items
    }

    private func weightTrendInsight(from metrics: [HealthMetric]) -> PlanInsightItem? {
        let weightMetrics = metrics.filter { $0.type == .weight }.sorted { $0.date < $1.date }
        guard let latest = weightMetrics.last else { return nil }

        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: latest.date) ?? latest.date
        let reference = weightMetrics.last(where: { $0.date <= oneWeekAgo }) ?? weightMetrics.dropLast().last

        guard let baseline = reference else { return nil }
        let delta = latest.value - baseline.value

        if abs(delta) < 0.3 { return nil }

        if delta > 0 {
            return PlanInsightItem(
                title: "体重上升提醒",
                message: "比一周前增加了 \(String(format: "%.1f", delta)) kg，调整饮食结构或增加低强度运动。",
                tone: .warning,
                intent: .logWeight
            )
        } else {
            return PlanInsightItem(
                title: "体重下降",
                message: "较一周前下降 \(String(format: "%.1f", abs(delta))) kg，保持充足睡眠帮助恢复。",
                tone: .positive,
                intent: .none
            )
        }
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
                } else if taskDate < currentDate {
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
