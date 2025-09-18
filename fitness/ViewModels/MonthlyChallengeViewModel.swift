import Foundation
import Combine

class MonthlyChallengeViewModel: ObservableObject {
    @Published var completionStatus: [Int: Bool] = [:]
    @Published var monthName: String = ""
    
    private let healthKitManager: HealthKitManager
    private var cancellables: Set<AnyCancellable> = []

    var numberOfDaysInMonth: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        return range.count
    }

    var completedDays: Int {
        completionStatus.values.filter { $0 }.count
    }

    // Default initializer creates its own HealthKitManager
    init() {
        self.healthKitManager = HealthKitManager()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        self.monthName = formatter.string(from: Date())
        
        fetchChallengeData()
    }

    func fetchChallengeData() {
        // Ensure authorization before fetching
        healthKitManager.requestAuthorization { [weak self] success in
            guard let self = self, success else { return }
            self.healthKitManager.fetchMonthlyActivitySummaries { results in
                DispatchQueue.main.async {
                    self.completionStatus = results
                }
            }
        }
    }
}