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
    @State private var overviewImage: UIImage?
    @State private var showShareSheet = false

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
        case .todaysWorkout:
            // Logic for Today's Workout Card
            if let activePlan = activePlans.first {
                let today = Calendar.current.startOfDay(for: Date())
                // Try to find today's task
                if let todayTask = activePlan.dailyTasks.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                    TodaysWorkoutCard(dailyTask: todayTask, isNoActivePlan: false)
                } else {
                    // If no specific task for today, create a dummy DailyTask for a rest day
                    let restDayTask = DailyTask(date: today, workouts: [])
                    TodaysWorkoutCard(dailyTask: restDayTask, isNoActivePlan: false)
                }
            } else {
                // If no active plan at all, create a dummy DailyTask to indicate no plan
                let noPlanTask = DailyTask(date: Date(), workouts: [])
                TodaysWorkoutCard(dailyTask: noPlanTask, isNoActivePlan: true)
            }
        case .fitnessRings:
            FitnessRingCard(activitySummary: dashboardViewModel.activitySummary)
        case .goalProgress:
            GoalProgressCard(showInputSheet: $showInputSheet)
        case .stepsAndDistance:
            HStack(spacing: 16) {
                StepsCard(stepCount: dashboardViewModel.stepCount, weeklyStepData: dashboardViewModel.weeklyStepData)
                DistanceCard(distance: dashboardViewModel.distance, weeklyDistanceData: dashboardViewModel.weeklyDistanceData)
            }
        case .monthlyChallenge:
            MonthlyChallengeCard(monthlyChallengeCompletion: dashboardViewModel.monthlyChallengeCompletion)
        case .recentActivity:
            RecentActivityCard(mostRecentWorkout: dashboardViewModel.mostRecentWorkout)
        case .historyList:
            HistoryListView() // HistoryListView uses @Query directly, no change needed here for now
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {

                        if !dashboardViewModel.quickActions.isEmpty {
                            quickActionsSection
                        }

                        if !dashboardViewModel.insights.isEmpty {
                            insightsSection
                        }

                        // Dynamically generate cards
                        ForEach(dashboardViewModel.cards) { card in
                            if card.isVisible {
                                dashboardContent(card: card)
                            }
                        }

                        // Bottom Action Buttons
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

                            Button(action: {
                                // Create a view to snapshot with environment objects
                                let viewToSnapshot = VStack(spacing: 16) {
                                    ForEach(dashboardViewModel.cards) { card in
                                        if card.isVisible {
                                            dashboardContent(card: card)
                                        }
                                    }
                                }
                                .padding()
                                .environmentObject(weightManager)
                                .environmentObject(profileViewModel)
                                .environmentObject(healthKitManager)

                                self.overviewImage = viewToSnapshot.snapshot()
                                self.showShareSheet = true
                            }) {
                                Text("分享今日成就")
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
                    .padding()
                }
            }
            .navigationTitle("概览")
            .task { // Add .task here
                await dashboardViewModel.loadNonReactiveData()
            }
            .onAppear(perform: refreshAuxiliaryData)
            .onChange(of: activePlans.map(\.id)) { _ in
                refreshAuxiliaryData()
            }
            .onChange(of: allMetrics.map(\.date)) { _ in
                refreshAuxiliaryData()
            }
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
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = overviewImage {
                    ShareSheet(items: [image])
                }
            }
                            .sheet(isPresented: $showEditSheet) {
                                EditDashboardView()
                                    .environmentObject(dashboardViewModel) // Inject DashboardViewModel
                                    .presentationDetents([.fraction(0.85), .large])
                            }        }
    }

    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(dashboardViewModel.quickActions) { action in
                    QuickActionButton(
                        title: action.title,
                        subtitle: action.subtitle,
                        icon: action.icon,
                        tint: action.tint
                    ) {
                        perform(action.intent)
                    }
                    .frame(width: 220)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var insightsSection: some View {
        VStack(spacing: 12) {
            ForEach(dashboardViewModel.insights) { item in
                InsightCard(
                    title: item.title,
                    description: item.message,
                    tone: item.tone,
                    action: actionForInsight(item.intent)
                )
            }
        }
    }

    private func actionForInsight(_ intent: DashboardInsightItem.Intent) -> InsightCard.Action? {
        switch intent {
        case .startWorkout:
            return InsightCard.Action(title: "开始训练", icon: "play.fill") { perform(.startWorkout) }
        case .logWeight:
            return InsightCard.Action(title: "记录体重", icon: "scalemass.fill") { perform(.logWeight) }
        case .openPlan:
            return InsightCard.Action(title: "查看计划", icon: "target") { perform(.openPlan) }
        case .openBodyProfileWeight:
            return InsightCard.Action(title: "查看体重趋势", icon: "chart.xyaxis.line") {
                appState.selectedTab = 2
                NotificationCenter.default.post(name: .navigateToBodyProfileMetric, object: nil, userInfo: ["metric": "weight"])
            }
        case .openStats:
            return InsightCard.Action(title: "查看分析", icon: "chart.pie") {
                appState.selectedTab = 3
            }
        case .none:
            return nil
        }
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
