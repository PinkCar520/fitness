import Foundation
import SwiftUI

final class StatsViewModel: ObservableObject {
    struct ExecutionSummary {
        let completedDays: Int
        let skippedDays: Int
        let streakDays: Int
        var completionRate: Double {
            let total = completedDays + skippedDays
            return total > 0 ? Double(completedDays) / Double(total) : 0
        }
    }

    @Published var totalCalories: Double = 0
    @Published var workoutDays: Int = 0
    @Published var execution: ExecutionSummary = .init(completedDays: 0, skippedDays: 0, streakDays: 0)
    @Published var vo2MaxTrend: [DateValuePoint] = []
    @Published var weightTrend: [DateValuePoint] = []
    @Published var bodyFatTrend: [DateValuePoint] = []

    func buildTrend(from metrics: [HealthMetric], type: MetricType, last days: Int) -> [DateValuePoint] {
        let now = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -days, to: now) else { return [] }
        return metrics
            .filter { $0.type == type && $0.date >= start && $0.date <= now }
            .sorted(by: { $0.date < $1.date })
            .map { DateValuePoint(date: $0.date, value: $0.value) }
    }
}

