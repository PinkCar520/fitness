import SwiftUI
import SwiftData

struct SummaryDashboardView: View {
    // Environment Objects
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var recommendationManager: RecommendationManager

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

    init(showInputSheet: Binding<Bool>, healthKitManager: HealthKitManager, weightManager: WeightManager) {
        self._showInputSheet = showInputSheet
        self.healthKitManager = healthKitManager
        self.weightManager = weightManager
        self._dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(healthKitManager: healthKitManager, weightManager: weightManager))
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
            GoalProgressCard(showInputSheet: $showInputSheet, latestWeightSample: dashboardViewModel.lastWeightSample)
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
