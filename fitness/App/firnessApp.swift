
import SwiftUI

@main
struct FastApp: App {
    @StateObject private var weightManager = WeightManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var profileViewModel = ProfileViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(weightManager)
                .environmentObject(healthKitManager)
                .environmentObject(profileViewModel)
                .onAppear {
                    healthKitManager.setupHealthKitData(weightManager: weightManager) // Call the new method
                    NotificationManager.requestAuthorization()
                    NotificationManager.scheduleDailyWeighIn(hour: 8, minute: 0)
                }
        }
    }
}
