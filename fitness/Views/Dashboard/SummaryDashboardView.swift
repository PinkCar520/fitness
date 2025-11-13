import SwiftUI
import SwiftData

struct SummaryDashboardView: View {
    // Environment Objects
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var recommendationManager: RecommendationManager
    @EnvironmentObject var appState: AppState

    // State
    @Binding var showInputSheet: Bool
    @State private var showSettingsSheet = false
    @State private var showEditSheet = false // For the new edit sheet
    @State private var showStepsSheet = false
    @State private var showDistanceSheet = false

    // View Models
    @StateObject private var dashboardViewModel: DashboardViewModel

    // Dependencies (for DashboardViewModel)
    private let healthKitManager: HealthKitManager
    private let weightManager: WeightManager

    // Query for active plan
    @Query(filter: #Predicate<Plan> { $0.status == "active" }) private var activePlans: [Plan]
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]

    init(showInputSheet: Binding<Bool>, healthKitManager: HealthKitManager, weightManager: WeightManager) {
        self._showInputSheet = showInputSheet
        self.healthKitManager = healthKitManager
        self.weightManager = weightManager
        self._dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(healthKitManager: healthKitManager, weightManager: weightManager))
    }

    private var activePlan: Plan? {
        activePlans.first
    }

    private var todaysTask: DailyTask? {
        guard let plan = activePlan else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        return plan.dailyTasks.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    // The dynamic content of the dashboard
    @ViewBuilder
    private func dashboardContent(card: DashboardCard) -> some View {
        switch card.id {
        case .todaysWorkout: cardTodaysWorkout()
        case .fitnessRings: cardFitnessRings()
        case .goalProgress: cardGoalProgress()
        case .stepsAndDistance: cardStepsAndDistance()
        case .monthlyChallenge: cardMonthlyChallenge()
        case .recentActivity: cardRecentActivity()
        case .hydration:
            if shouldRenderHydrationMenstrualRow(for: .hydration) {
                hydrationMenstrualRow()
            } else {
                EmptyView()
            }
        case .menstrualCycle:
            if shouldRenderHydrationMenstrualRow(for: .menstrualCycle) {
                hydrationMenstrualRow()
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Extracted subviews to help compiler
    @ViewBuilder
    private func todaysWorkoutView() -> some View {
        if let activePlan = activePlans.first {
            let today = Calendar.current.startOfDay(for: Date())
            if let todayTask = activePlan.dailyTasks.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                TodaysWorkoutCard(dailyTask: todayTask, isNoActivePlan: false)
            } else {
                let restDayTask = DailyTask(date: today, workouts: [])
                TodaysWorkoutCard(dailyTask: restDayTask, isNoActivePlan: false)
            }
        } else {
            let noPlanTask = DailyTask(date: Date(), workouts: [])
            TodaysWorkoutCard(dailyTask: noPlanTask, isNoActivePlan: true)
        }
    }

    @ViewBuilder
    private func stepsAndDistanceRow() -> some View {
        HStack(spacing: 16) {
            Button(action: { showStepsSheet = true }) {
                StepsCard(stepCount: dashboardViewModel.stepCount, weeklyStepData: dashboardViewModel.weeklyStepData)
            }
            .buttonStyle(.plain)

            Button(action: { showDistanceSheet = true }) {
                DistanceCard(distance: dashboardViewModel.distance, weeklyDistanceData: dashboardViewModel.weeklyDistanceData)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func hydrationMenstrualRow() -> some View {
        HStack(spacing: 16) {
            if isCardVisible(.hydration) {
                cardHydration()
                    .frame(maxWidth: .infinity)
            }
            if isCardVisible(.menstrualCycle) {
                cardMenstrualCycle()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Thin card wrappers to help type-checker
    private func cardTodaysWorkout() -> some View { todaysWorkoutView() }
    private func cardFitnessRings() -> some View { FitnessRingCard(activitySummary: dashboardViewModel.activitySummary) }
    private func cardGoalProgress() -> some View { GoalProgressCard(showInputSheet: $showInputSheet) }
    private func cardStepsAndDistance() -> some View { stepsAndDistanceRow() }
    private func cardHydration() -> some View {
        HydrationCard(
            targetLiters: profileViewModel.userProfile.waterIntake?.recommendedLiters ?? 2.0
        )
    }
    private func cardMenstrualCycle() -> some View {
        MenstrualCycleCard(gender: profileViewModel.userProfile.gender)
    }
    private func cardMonthlyChallenge() -> some View { MonthlyChallengeCard(monthlyChallengeCompletion: dashboardViewModel.monthlyChallengeCompletion) }
    private func cardRecentActivity() -> some View { RecentActivityCard(mostRecentWorkout: dashboardViewModel.mostRecentWorkout) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    let cards = dashboardViewModel.cards
                    let quickActions = dashboardViewModel.quickActions
                    VStack(spacing: 16) {
                        if !quickActions.isEmpty { quickActionsSection }
                        renderCards(cards)
                        bottomActions()
                    }
                    .padding()
                }
            }
            .navigationTitle("概览")
            .task { // Add .task here
                await dashboardViewModel.loadNonReactiveData()
            }
            .onAppear(perform: refreshAuxiliaryData)
            .onChange(of: activePlans.map(\.id)) { _, _ in refreshAuxiliaryData() }
            .onChange(of: allMetrics.map(\.date)) { _, _ in refreshAuxiliaryData() }
            .onReceive(NotificationCenter.default.publisher(for: .planDataDidChange)) { _ in
                refreshAuxiliaryData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettingsSheet = true }) {
                        if let avatarPath = profileViewModel.userProfile.avatarPath, !avatarPath.isEmpty {
                            Image(uiImage: profileViewModel.displayAvatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showStepsSheet) {
                StepsDetailSheet(stepCount: Int(dashboardViewModel.stepCount), weeklyData: dashboardViewModel.weeklyStepData)
                    .environmentObject(dashboardViewModel)
                    // 固定为中等高度，禁止向上拉至 large
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
            // removed share sheet per new design
            .sheet(isPresented: $showDistanceSheet) {
                DistanceDetailSheet(distanceKM: dashboardViewModel.distance, weeklyData: dashboardViewModel.weeklyDistanceData)
                    .environmentObject(dashboardViewModel)
                    // 固定为中等高度，禁止向上拉至 large
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showEditSheet) {
                EditDashboardView()
                    .environmentObject(dashboardViewModel) // Inject DashboardViewModel
                    .presentationDetents([.fraction(0.85)])
            }
        }
    }

    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(dashboardViewModel.quickActions) { action in
                    QuickActionButton(
                        title: action.title,
                        subtitle: action.subtitle,
                        icon: action.icon,
                        tint: action.tint,
                        chips: action.chips
                    ) {
                        perform(action.intent)
                    }
                    .frame(width: 220)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // Insights section removed; now shown via Widgets

    // MARK: - Render helpers extracted to reduce type-checking complexity
    @ViewBuilder
    private func renderCards(_ cards: [DashboardCard]) -> some View {
        Group {
            ForEach(cards.filter { $0.isVisible }) { card in
                dashboardContent(card: card)
            }
        }
    }

    @ViewBuilder
    private func bottomActions() -> some View {
        HStack(spacing: 16) {
            Button(action: { showEditSheet = true }) {
                Text("编辑卡片")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(32)
                    .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical)
    }

    private func perform(_ intent: DashboardQuickAction.Intent) {
        switch intent {
        case .startWorkout:
            appState.selectedTab = 1
            // Additional routing could be added later (e.g., notification to open workout)
        case .openPlan:
            appState.selectedTab = 1
        case .logWeight:
            showInputSheet = true
        case .openNutrition:
            appState.selectedTab = 1
        }
    }

    private func refreshAuxiliaryData() {
        dashboardViewModel.refreshAuxiliaryData(
            activePlan: activePlan,
            todaysTask: todaysTask,
            weightMetrics: weightMetrics
        )
    }
}

private extension SummaryDashboardView {
    func shouldRenderHydrationMenstrualRow(for cardType: DashboardCard.CardType) -> Bool {
        guard cardType == .hydration || cardType == .menstrualCycle else { return false }
        return firstVisibleHydrationMenstrualCard == cardType
    }

    var firstVisibleHydrationMenstrualCard: DashboardCard.CardType? {
        dashboardViewModel.cards
            .filter { $0.isVisible && ($0.id == .hydration || $0.id == .menstrualCycle) }
            .first?.id
    }

    func isCardVisible(_ type: DashboardCard.CardType) -> Bool {
        dashboardViewModel.cards.first(where: { $0.id == type })?.isVisible ?? false
    }
}

struct SummaryDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)

        let healthKitManager = HealthKitManager()
        let weightManager = WeightManager(healthKitManager: healthKitManager, modelContainer: container)

        SummaryDashboardView(showInputSheet: .constant(false), healthKitManager: healthKitManager, weightManager: weightManager)
            .modelContainer(container) // Important for @Query
            // .environmentObject(healthKitManager) // No longer needed directly
            // .environmentObject(weightManager) // No longer needed directly
            .environmentObject(ProfileViewModel())
            .environmentObject(RecommendationManager(profileViewModel: ProfileViewModel()))
    }
}
