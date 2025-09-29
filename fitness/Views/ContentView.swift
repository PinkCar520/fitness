import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var weightManager: WeightManager // Add this
    @EnvironmentObject var appearanceViewModel: AppearanceViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var achievementManager: AchievementManager
    
    @State private var selectedIndex = 0 // Default to the first tab
    @State private var showInputSheet = false
    @State private var showOnboarding: Bool

    init() {
        // Initialize showOnboarding based on the profile view model
        // We need to access the wrappedValue of the EnvironmentObject to initialize a @State property in `init`.
        // This is a common pattern for setting initial @State based on an EnvironmentObject.
        _showOnboarding = State(initialValue: !ProfileViewModel().userProfile.hasCompletedOnboarding)
    }

    var body: some View {
        ZStack {
            if !showOnboarding {
                TabView(selection: $selectedIndex) {
                    // Tab 1: Overview
                    SummaryDashboardView(showInputSheet: $showInputSheet, healthKitManager: healthKitManager, weightManager: weightManager)
                        .tabItem {
                            Image(systemName: "square.grid.2x2.fill")
                        }
                        .tag(0)

                    // Tab 2: Plan
                    PlanView(profileViewModel: profileViewModel)
                        .tabItem {
                            Image(systemName: "checklist")
                        }
                        .tag(1)

                    // Tab 3: Stats
                    StatsView()
                        .tabItem {
                            Image(systemName: "chart.pie.fill")
                        }
                        .tag(2)
                }
                .id(appearanceViewModel.theme) // Add this line
                .accentColor(appearanceViewModel.accentColor.color)
                .onReceive(NotificationCenter.default.publisher(for: .showInputSheet)) { _ in
                    // Show the input sheet when the notification is received from the widget
                    showInputSheet = true
                }
                .sheet(isPresented: $showInputSheet) { 
                    InputSheetView()
                }
                .overlay(alignment: .top) {
                    if achievementManager.showAchievementPopup, let achievement = achievementManager.unlockedAchievement {
                        AchievementPopupView(message: achievement) {
                            achievementManager.dismissAchievementPopup()
                        }
                        .padding(.top)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(), value: achievementManager.showAchievementPopup)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(showOnboarding: $showOnboarding)
                .environmentObject(profileViewModel)
        }
    }
}

struct AchievementPopupView: View {
    let message: String
    let dismissAction: () -> Void

    @State private var show = false

    var body: some View {
        VStack {
            Text("🎉 成就解锁！")
                .font(.headline)
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.green.opacity(0.9))
        .cornerRadius(15)
        .shadow(radius: 10)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    dismissAction()
                }
            }
        }
        .onTapGesture {
            withAnimation {
                dismissAction()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)
        
        let healthKitManager = HealthKitManager()
        let weightManager = WeightManager(healthKitManager: healthKitManager, modelContainer: container)

        let profileViewModel = ProfileViewModel()

        ContentView()
            .modelContainer(container) // Important for @Query
            .environmentObject(healthKitManager)
            .environmentObject(weightManager)
            .environmentObject(profileViewModel)
            .environmentObject(AppearanceViewModel())
            .environmentObject(AchievementManager(profileViewModel: profileViewModel))
    }
}
