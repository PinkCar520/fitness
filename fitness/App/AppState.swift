import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var workoutSummary: (show: Bool, workouts: [Workout]) = (false, [])
}
