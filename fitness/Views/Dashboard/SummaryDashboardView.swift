import SwiftUI

struct SummaryDashboardView: View {
    // Environment Objects
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var healthKitManager: HealthKitManager
    
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
