
import SwiftUI

@main
struct FastApp: App {
    @StateObject private var weightManager = WeightManager()
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(weightManager)
                .environmentObject(healthKitManager)
        }
    }
}
