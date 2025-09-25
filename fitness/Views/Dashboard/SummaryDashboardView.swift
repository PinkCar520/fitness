import SwiftUI
import SwiftData

struct SummaryDashboardView: View {
    // Environment Objects
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var recommendationManager: RecommendationManager
    
    // State
    @Binding var showInputSheet: Bool
    @State private var showProfileSheet = false
    @State private var showEditSheet = false // For the new edit sheet
    @State private var overviewImage: UIImage?
    @State private var showShareSheet = false
    
    // View Models
    @StateObject private var dashboardViewModel = DashboardViewModel()

    // The dynamic content of the dashboard
    @ViewBuilder
    private func dashboardContent(card: DashboardCard) -> some View {
        switch card.id {
        case .fitnessRings:
            FitnessRingCard()
        case .goalProgress:
            GoalProgressCard(showInputSheet: $showInputSheet)
        case .stepsAndDistance:
            HStack(spacing: 16) {
                StepsCard()
                DistanceCard()
            }
        case .monthlyChallenge:
            MonthlyChallengeCard()
        case .recentActivity:
            RecentActivityCard()
        case .historyList:
            HistoryListView()
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Recommendation Section
                        if !recommendationManager.recommendedContent.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("为你推荐")
                                    .font(.headline)
                                    .padding(.horizontal)
                                ForEach(recommendationManager.recommendedContent, id: \.self) {
                                    recommendation in
                                    Text(recommendation)
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.bottom, 8)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showProfileSheet = true }) {
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
            .sheet(isPresented: $showProfileSheet) {
                ProfilePopupView()
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = overviewImage {
                    ShareSheet(items: [image])
                }
            }
            .sheet(isPresented: $showEditSheet) { // Sheet for editing cards
                EditDashboardView()
                    .environmentObject(dashboardViewModel)
            }
        }
    }
}

struct SummaryDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)
        
        let healthKitManager = HealthKitManager()
        let weightManager = WeightManager(healthKitManager: healthKitManager, modelContainer: container)

        SummaryDashboardView(showInputSheet: .constant(false))
            .modelContainer(container) // Important for @Query
            .environmentObject(healthKitManager)
            .environmentObject(weightManager)
            .environmentObject(ProfileViewModel())
            .environmentObject(RecommendationManager(profileViewModel: ProfileViewModel()))
    }
}