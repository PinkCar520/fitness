import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var appearanceViewModel: AppearanceViewModel
    @State private var selectedIndex = 0 // Default to the first tab
    @State private var showInputSheet = false

    var body: some View {
        TabView(selection: $selectedIndex) {
            // Tab 1: Overview
            SummaryDashboardView(showInputSheet: $showInputSheet)
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                }
                .tag(0)

            // Tab 2: Plan
            PlanView()
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
        .accentColor(appearanceViewModel.accentColor.color)
        .onReceive(NotificationCenter.default.publisher(for: .showInputSheet)) { _ in
            // Show the input sheet when the notification is received from the widget
            showInputSheet = true
        }
        .sheet(isPresented: $showInputSheet) { 
            InputSheetView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)
        
        let healthKitManager = HealthKitManager()
        let weightManager = WeightManager(healthKitManager: healthKitManager, modelContainer: container)

        ContentView()
            .modelContainer(container) // Important for @Query
            .environmentObject(healthKitManager)
            .environmentObject(weightManager)
            .environmentObject(ProfileViewModel())
            .environmentObject(AppearanceViewModel())
    }
}
