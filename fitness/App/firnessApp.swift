
import SwiftUI
import SwiftData

@main
struct firnessApp: App {
    @StateObject private var healthKitManager: HealthKitManager
    @StateObject private var weightManager: WeightManager
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var appearanceViewModel = AppearanceViewModel()
    @StateObject private var recommendationManager: RecommendationManager
    @StateObject private var achievementManager: AchievementManager
    
    let modelContainer: ModelContainer

    init() {
        // 1. Create the ModelContainer first, as other services may depend on it.
        let container: ModelContainer
        do {
            let schema = Schema([HealthMetric.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        self.modelContainer = container

        // 2. Create services that depend on the container.
        let healthKitManager = HealthKitManager()
        let weightManager = WeightManager(healthKitManager: healthKitManager, modelContainer: container)
        
        // 3. Assign to StateObjects.
        _healthKitManager = StateObject(wrappedValue: healthKitManager)
        _weightManager = StateObject(wrappedValue: weightManager)
        
        let initialProfileViewModel = ProfileViewModel()
        _profileViewModel = StateObject(wrappedValue: initialProfileViewModel)
        _recommendationManager = StateObject(wrappedValue: RecommendationManager(profileViewModel: initialProfileViewModel))
        _achievementManager = StateObject(wrappedValue: AchievementManager(profileViewModel: initialProfileViewModel))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitManager)
                .environmentObject(profileViewModel)
                .environmentObject(appearanceViewModel)
                .environmentObject(weightManager)
                .onAppear {
                    healthKitManager.setupHealthKitData(weightManager: weightManager)
                }
                .environmentObject(recommendationManager)
                .environmentObject(achievementManager)
                .onOpenURL { url in
                    // Handle the deep link from the widget
                    if url.scheme == "fitness" && url.host == "add-weight" {
                        NotificationCenter.default.post(name: .showInputSheet, object: nil)
                    }
                }
        }
                    .modelContainer(modelContainer) // Apply the SwiftData container to the whole app
    }
}

// Define a custom notification name
extension Notification.Name {
    static let showInputSheet = Notification.Name("showInputSheet")
}
