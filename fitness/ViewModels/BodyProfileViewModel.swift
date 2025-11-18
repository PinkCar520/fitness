import Foundation
import SwiftUI

final class BodyProfileViewModel: ObservableObject {
    enum TimeRange: Int, CaseIterable, Identifiable {
        case week = 7, month = 30, quarter = 90, year = 365
        var id: Int { rawValue }
        var days: Int { rawValue }
        var title: String {
            switch self {
            case .week: return "周"
            case .month: return "月"
            case .quarter: return "季"
            case .year: return "年"
            }
        }
    }

    @Published var selectedMetric: ChartableMetric = .weight
    @Published var timeRange: TimeRange = .month
    @Published var chartData: [DateValuePoint] = []
    @Published var averageValue: Double?
    @Published var goalValue: Double?
    @Published var insights: [String] = []

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
        averageValue = average(of: chartData)

        // optional goal: use user targetWeight when metric is weight
        if selectedMetric == .weight, profile.targetWeight > 0 {
            goalValue = profile.targetWeight
        } else {
            goalValue = nil
        }

        // insights
        insights = buildInsights(profile: profile)
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
        let series = metrics
            .filter { $0.type == type && $0.date >= start && $0.date <= now }
            .sorted(by: { $0.date < $1.date })
            .map { DateValuePoint(date: $0.date, value: $0.value) }
        return downsample(series, maxPoints: 200)
    }

    private func downsample(_ points: [DateValuePoint], maxPoints: Int) -> [DateValuePoint] {
        guard points.count > maxPoints && maxPoints > 0 else { return points }
        let step = max(1, points.count / maxPoints)
        return points.enumerated().compactMap { idx, p in idx % step == 0 ? p : nil }
    }

    private func average(of series: [DateValuePoint]) -> Double? {
        guard !series.isEmpty else { return nil }
        let sum = series.reduce(0) { $0 + $1.value }
        return sum / Double(series.count)
    }

    private func buildInsights(profile: UserProfile) -> [String] {
        var lines: [String] = []
        // BMI
        if bmi > 0 {
            switch HealthStandards.bmiCategoryWHO(bmi) {
            case .underweight: lines.append("BMI 偏低：增加优质蛋白与力量训练")
            case .normal: lines.append("BMI 正常：保持当前节奏")
            case .overweight: lines.append("BMI 超重：控制热量并增加活动量")
            case .obese: lines.append("BMI 肥胖：建议循序渐进并关注膝踝负担")
            }
        }
        // Body fat
        if let gender = Gender(rawValue: profile.gender.rawValue), let value = latestBodyFat, value > 0 {
            let band = HealthStandards.bodyFatBand(gender: gender, value: value)
            switch band {
            case .athletic: lines.append("体脂优秀：注意恢复与营养平衡")
            case .fit: lines.append("体脂良好：维持训练频率与强度")
            case .average: lines.append("体脂一般：可适度增加有氧+力量")
            case .high: lines.append("体脂偏高：优先饮食管理与低冲击有氧")
            }
        }
        // VO2max
        if let vo2 = latestVO2Max, vo2 > 0 {
            let age = Calendar.current.dateComponents([.year], from: profile.dateOfBirth, to: Date()).year ?? 30
            let cat = HealthStandards.vo2MaxCategoryWHO(gender: profile.gender, age: age, vo2max: vo2)
            switch cat {
            case .veryLow: lines.append("VO2max 很低：从轻量有氧开始，逐步提升")
            case .low: lines.append("VO2max 较低：加入间歇训练提升心肺")
            case .fair: lines.append("VO2max 中等：保持每周 3–4 次有氧")
            case .good: lines.append("VO2max 良好：可尝试更高强度间歇")
            case .excellent: lines.append("VO2max 优秀：注意恢复与周期化训练")
            }
        }
        return lines
    }
}
