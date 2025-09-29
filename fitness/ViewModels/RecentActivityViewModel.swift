import Foundation
import HealthKit
import Combine

class RecentActivityViewModel: ObservableObject {
    @Published var activityName: String = ""
    @Published var distance: String = "--"
    @Published var duration: String = "--"
    @Published var date: String = "无记录"
    @Published var isLoading: Bool = true
    @Published var workoutFound: Bool = false

    private let healthKitManager: HealthKitManager

    init() {
        self.healthKitManager = HealthKitManager()
    }

    func fetchRecentActivity() {
        isLoading = true
        healthKitManager.requestAuthorization { [weak self] success in
            guard let self = self else { return } // Safely unwrap self
            guard success else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            Task { @MainActor in
                if let workout = await self.healthKitManager.fetchMostRecentWorkout() {
                    self.activityName = workout.workoutActivityType.name
                    self.duration = String(format: "%.0f min", workout.duration / 60)
                    self.date = self.formatDate(workout.endDate)
                    
                    if let distanceQuantity = workout.totalDistance {
                        let km = distanceQuantity.doubleValue(for: .meter()) / 1000
                        self.distance = String(format: "%.2f km", km)
                    } else {
                        self.distance = "--"
                    }
                    self.workoutFound = true
                } else {
                    self.workoutFound = false
                }
                self.isLoading = false
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }
    }
}

// Helper to get a user-friendly name from HKWorkoutActivityType
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "跑步"
        case .walking: return "步行"
        case .cycling: return "自行车"
        case .swimming: return "游泳"
        case .functionalStrengthTraining: return "力量训练" // Corrected case name
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "瑜伽"
        case .pilates: return "普拉提"
        // Add more cases as needed
        default: return "运动" // Generic fallback
        }
    }
}