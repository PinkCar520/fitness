import Foundation
import SwiftUI
import HealthKit // Add this
import SwiftData // Add this
import Combine
import WidgetKit

// Shared insights
import Foundation

// 1. Model for a single dashboard card
struct DashboardCard: Identifiable, Codable, Hashable {
    let id: CardType
    var name: String
    var isVisible: Bool = true

    enum CardType: String, Codable, CaseIterable {
        case todaysWorkout = "TodaysWorkout" // Add this new case
        case fitnessRings = "FitnessRings"
        case goalProgress = "GoalProgress"
        case stepsAndDistance = "StepsAndDistance"
        case monthlyChallenge = "MonthlyChallenge"
        case recentActivity = "RecentActivity"
        case historyList = "HistoryList"
    }
}

struct DashboardQuickAction: Identifiable, Equatable {
    enum Intent: Equatable {
        case startWorkout
        case openPlan
        case logWeight
        case openNutrition
    }

    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String
    let tint: Color
    let intent: Intent
}

typealias DashboardInsightItem = InsightItem

// 2. View Model to manage the cards
class DashboardViewModel: ObservableObject {
    @Published var cards: [DashboardCard] = []
    @Published var quickActions: [DashboardQuickAction] = []
    // Insights removed from in-app dashboard; now provided via Widget
    private let userDefaultsKey = "dashboard_card_order"

    // Dependencies
    private let healthKitManager: HealthKitManager
    private let weightManager: WeightManager
    private var cancellables = Set<AnyCancellable>()

    // Dashboard Data
    @Published var stepCount: Double = 0
    @Published var distance: Double = 0
    @Published var activitySummary: HKActivitySummary?
    @Published var weeklyStepData: [DailyStepData] = []
    @Published var weeklyDistanceData: [DailyDistanceData] = []
    // Extended ranges for sheets
    @Published var monthlyStepData: [DailyStepData] = []
    @Published var quarterStepData: [DailyStepData] = []
    @Published var yearStepData: [DailyStepData] = []
    @Published var monthlyDistanceData: [DailyDistanceData] = []
    @Published var quarterDistanceData: [DailyDistanceData] = []
    @Published var yearDistanceData: [DailyDistanceData] = []
    @Published var monthlyChallengeCompletion: [Int: Bool] = [:]
    @Published var mostRecentWorkout: HKWorkout?
    @Published var lastWeightSample: HKQuantitySample?
    @Published var lastBodyFatSample: HKQuantitySample?
    @Published var lastWaistCircumferenceSample: HKQuantitySample?

    private let calendar = Calendar.current

    init(healthKitManager: HealthKitManager, weightManager: WeightManager) {
        self.healthKitManager = healthKitManager
        self.weightManager = weightManager
        loadCardOrder()
        setupSubscriptions()
        
        // Trigger initial data load for non-reactive data
        Task {
            await loadNonReactiveData()
        }
    }
    
    private func setupSubscriptions() {
        healthKitManager.$stepCount
            .receive(on: DispatchQueue.main)
            .assign(to: \.stepCount, on: self)
            .store(in: &cancellables)

        healthKitManager.$distance
            .receive(on: DispatchQueue.main)
            .assign(to: \.distance, on: self)
            .store(in: &cancellables)
            
        healthKitManager.$activitySummary
            .receive(on: DispatchQueue.main)
            .assign(to: \.activitySummary, on: self)
            .store(in: &cancellables)

        healthKitManager.$weeklyStepData
            .receive(on: DispatchQueue.main)
            .assign(to: \.weeklyStepData, on: self)
            .store(in: &cancellables)

        healthKitManager.$weeklyDistanceData
            .receive(on: DispatchQueue.main)
            .assign(to: \.weeklyDistanceData, on: self)
            .store(in: &cancellables)

        healthKitManager.$lastWeightSample
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastWeightSample, on: self)
            .store(in: &cancellables)

        healthKitManager.$lastBodyFatSample
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastBodyFatSample, on: self)
            .store(in: &cancellables)

        healthKitManager.$lastWaistCircumferenceSample
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastWaistCircumferenceSample, on: self)
            .store(in: &cancellables)
    }

    // Computed properties to easily get filtered lists
    var visibleCards: [DashboardCard] {
        cards.filter { $0.isVisible }
    }

    var hiddenCards: [DashboardCard] {
        cards.filter { !$0.isVisible }
    }

    func moveCard(from source: IndexSet, to destination: Int) {
        var visibleCardIDs = visibleCards.map { $0.id }
        visibleCardIDs.move(fromOffsets: source, toOffset: destination)

        // Sort the main cards array: visible cards first, in their new order, then hidden cards
        cards.sort { (card1, card2) -> Bool in
            let isVisible1 = visibleCardIDs.contains(card1.id)
            let isVisible2 = visibleCardIDs.contains(card2.id)

            if isVisible1 && !isVisible2 {
                return true
            }
            if !isVisible1 && isVisible2 {
                return false
            }
            if !isVisible1 && !isVisible2 {
                return false // Keep original relative order of hidden items
            }

            // Both are visible, sort according to the new explicit order
            if let index1 = visibleCardIDs.firstIndex(of: card1.id),
               let index2 = visibleCardIDs.firstIndex(of: card2.id) {
                return index1 < index2
            }

            return false
        }
        
        saveCardOrder()
    }
    
    func toggleVisibility(for card: DashboardCard) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index].isVisible.toggle()
        saveCardOrder()
    }

    func deleteVisibleCard(at offsets: IndexSet) {
        if let index = offsets.first {
            let cardToToggle = visibleCards[index]
            toggleVisibility(for: cardToToggle)
        }
    }

    func saveCardOrder() {
        if let encoded = try? JSONEncoder().encode(cards) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func loadCardOrder() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([DashboardCard].self, from: data) {
            self.cards = decoded
            addNewCardTypes(to: &self.cards)
        } else {
            self.cards = defaultCards
        }
    }
    
    private var defaultCards: [DashboardCard] {
        [
            DashboardCard(id: .todaysWorkout, name: "今日训练"), // Add this
            DashboardCard(id: .fitnessRings, name: "健身圆环"),
            DashboardCard(id: .goalProgress, name: "目标进度"),
            DashboardCard(id: .stepsAndDistance, name: "步数与距离"),
            DashboardCard(id: .monthlyChallenge, name: "每月挑战"),
            DashboardCard(id: .recentActivity, name: "最近活动"),
            DashboardCard(id: .historyList, name: "历史记录", isVisible: false) // Hidden by default
        ]
    }
    
    private func addNewCardTypes(to existingCards: inout [DashboardCard]) {
        let allTypes = DashboardCard.CardType.allCases
        let existingTypes = Set(existingCards.map { $0.id })
        
        for type in allTypes {
            if !existingTypes.contains(type) {
                if let newCard = defaultCards.first(where: { $0.id == type }) {
                    existingCards.append(newCard)
                }
            }
        }
    }

    // MARK: - Data Loading
    @MainActor
    func loadNonReactiveData() async {
        // Fetch data that is not covered by publishers
        
        // This method still uses a completion handler
        healthKitManager.fetchMonthlyActivitySummaries { [weak self] data in
            DispatchQueue.main.async {
                self?.monthlyChallengeCompletion = data
            }
        }

        // Fetch most recent workout
        self.mostRecentWorkout = await healthKitManager.fetchMostRecentWorkout()
    }

    // MARK: - Demand loading for extended ranges (used by sheets)
    enum SeriesRange { case week, month, quarter, year }

    @MainActor
    func loadStepsSeriesIfNeeded(_ range: SeriesRange) async {
        switch range {
        case .week:
            if weeklyStepData.isEmpty { weeklyStepData = await healthKitManager.readWeeklyStepCounts() }
        case .month:
            if monthlyStepData.isEmpty { monthlyStepData = await healthKitManager.readDailySteps(days: 30) }
        case .quarter:
            if quarterStepData.isEmpty { quarterStepData = await healthKitManager.readDailySteps(days: 90) }
        case .year:
            if yearStepData.isEmpty { yearStepData = await healthKitManager.readDailySteps(days: 365) }
        }
    }

    @MainActor
    func loadDistanceSeriesIfNeeded(_ range: SeriesRange) async {
        switch range {
        case .week:
            if weeklyDistanceData.isEmpty { weeklyDistanceData = await healthKitManager.readWeeklyDistance() }
        case .month:
            if monthlyDistanceData.isEmpty { monthlyDistanceData = await healthKitManager.readDailyDistance(days: 30) }
        case .quarter:
            if quarterDistanceData.isEmpty { quarterDistanceData = await healthKitManager.readDailyDistance(days: 90) }
        case .year:
            if yearDistanceData.isEmpty { yearDistanceData = await healthKitManager.readDailyDistance(days: 365) }
        }
    }

    // MARK: - Insight & Quick Action Builders

    func refreshAuxiliaryData(
        activePlan: Plan?,
        todaysTask: DailyTask?,
        weightMetrics: [HealthMetric]
    ) {
        quickActions = buildQuickActions(activePlan: activePlan, todaysTask: todaysTask)
        // In-app insights removed; only generate shared snapshot for Widget

        // Write snapshot for widget consumption
        let engineMetrics = weightMetrics
            .filter { $0.type == .weight }
            .map { InsightsEngine.WeightMetric(date: $0.date, value: $0.value) }
        let context = InsightsEngine.Context(
            hasActivePlan: (activePlan != nil),
            todaysHasWorkouts: todaysTask.map { !$0.workouts.isEmpty },
            todaysCompletedWorkoutsCount: todaysTask.map { $0.workouts.filter { $0.isCompleted }.count },
            weightMetrics: engineMetrics
        )
        let sharedItems = InsightsEngine.generate(from: context)
        let snapshot = InsightsSnapshot(generatedAt: Date(), items: sharedItems)
        let store = InsightsSnapshotStore(appGroup: "group.com.pineapple.fitness")
        store.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func buildQuickActions(activePlan: Plan?, todaysTask: DailyTask?) -> [DashboardQuickAction] {
        var actions: [DashboardQuickAction] = []

        if let task = todaysTask, !(task.workouts.isEmpty) {
            actions.append(
                DashboardQuickAction(
                    title: "开始今日训练",
                    subtitle: "专注完成当前计划",
                    icon: "play.fill",
                    tint: .accentColor,
                    intent: .startWorkout
                )
            )
        } else if activePlan != nil {
            actions.append(
                DashboardQuickAction(
                    title: "查看训练计划",
                    subtitle: "查看本周安排与摘要",
                    icon: "calendar.badge.clock",
                    tint: .blue,
                    intent: .openPlan
                )
            )
        } else {
            actions.append(
                DashboardQuickAction(
                    title: "制定新计划",
                    subtitle: "让系统为你生成专属训练",
                    icon: "target",
                    tint: .blue,
                    intent: .openPlan
                )
            )
        }

        actions.append(
            DashboardQuickAction(
                title: "记录今日体重",
                subtitle: "跟踪目标进度",
                icon: "scalemass.fill",
                tint: .orange,
                intent: .logWeight
            )
        )

        if let task = todaysTask, !task.meals.isEmpty {
            actions.append(
                DashboardQuickAction(
                    title: "查看饮食安排",
                    subtitle: "确保补给到位",
                    icon: "fork.knife",
                    tint: .green,
                    intent: .openNutrition
                )
            )
        }

        return actions
    }

    // buildInsights removed from ViewModel

    private func weightTrendInsight(from metrics: [HealthMetric]) -> DashboardInsightItem? {
        // Delegate to shared engine for consistency
        let engineMetrics = metrics
            .filter { $0.type == .weight }
            .map { InsightsEngine.WeightMetric(date: $0.date, value: $0.value) }
        return InsightsEngine.generate(from: .init(
            hasActivePlan: true,
            todaysHasWorkouts: nil,
            todaysCompletedWorkoutsCount: nil,
            weightMetrics: engineMetrics
        )).first { item in
            switch item.intent { case .openBodyProfileWeight: return true; default: return false }
        }
    }
}
