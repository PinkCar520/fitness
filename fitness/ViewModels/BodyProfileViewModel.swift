import Foundation
import SwiftUI

final class BodyProfileViewModel: ObservableObject {
    enum TimeRange: Int, CaseIterable, Identifiable {
        case seven = 7, thirty = 30, ninety = 90
        var id: Int { rawValue }
        var days: Int { rawValue }
        var title: String {
            switch self {
            case .seven: return "7天"
            case .thirty: return "30天"
            case .ninety: return "90天"
            }
        }
    }

    @Published var selectedMetric: ChartableMetric = .weight
    @Published var timeRange: TimeRange = .thirty
    @Published var chartData: [DateValuePoint] = []

    // Latest snapshot
    @Published var latestWeight: Double?
    @Published var latestBodyFat: Double?
    @Published var latestHeartRate: Double?
    @Published var latestWaist: Double?
    @Published var latestVO2Max: Double?

    // Derived
    @Published var bmi: Double = 0
    @Published var bmiCategory: HealthStandards.BMICategory = .normal

    func refresh(metrics: [HealthMetric], profile: UserProfile) {
        // latest values
        latestWeight = metrics.first(where: { $0.type == .weight })?.value
        latestBodyFat = metrics.first(where: { $0.type == .bodyFatPercentage })?.value
        latestHeartRate = metrics.first(where: { $0.type == .heartRate })?.value
        latestWaist = metrics.first(where: { $0.type == .waistCircumference })?.value
        latestVO2Max = metrics.first(where: { $0.type == .vo2Max })?.value

        // bmi
        if let w = latestWeight { bmi = HealthStandards.bmi(w, heightCm: profile.height) } else { bmi = 0 }
        bmiCategory = HealthStandards.bmiCategoryWHO(bmi)

        // chart
        chartData = series(for: selectedMetric, metrics: metrics, days: timeRange.days)
    }

    func series(for metric: ChartableMetric, metrics: [HealthMetric], days: Int) -> [DateValuePoint] {
        let now = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -days, to: now) else { return [] }
        let type: MetricType
        switch metric {
        case .weight: type = .weight
        case .bodyFat: type = .bodyFatPercentage
        case .waist: type = .waistCircumference
        case .heartRate: type = .heartRate
        case .vo2Max: type = .vo2Max
        }
        return metrics
            .filter { $0.type == type && $0.date >= start && $0.date <= now }
            .sorted(by: { $0.date < $1.date })
            .map { DateValuePoint(date: $0.date, value: $0.value) }
    }
}

