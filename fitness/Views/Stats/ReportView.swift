import SwiftUI
import SwiftData

struct ReportView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Query(sort: \HealthMetric.date, order: .reverse) private var records: [HealthMetric]
    
    let selectedTimeFrame: StatsView.TimeFrame
    let totalCalories: Double
    let workoutDays: Int

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("健身报告")
                .font(.largeTitle)
                .bold()
                .padding(.bottom)

            Text("时间范围: \(selectedTimeFrame.rawValue)")
                .font(.headline)
                .padding(.bottom)

            coreMetricsGrid

            workoutAnalysisSection
            
            smartSuggestionsSection
        }
        .padding()
        .background(Color.white)
        .frame(width: 400) // Set a fixed width for the report
    }

    private var weightChange: Double? {
        guard records.count > 1 else { return nil }
        
        let days = selectedTimeFrame.days
        guard days > 0 else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        
        let latestRecord = records[0]
        
        guard let referenceDate = calendar.date(byAdding: .day, value: -days, to: now) else { return nil }
        
        // Find the closest record from on or before the reference date
        let referenceRecord = records.first { $0.date <= referenceDate }
        
        guard let referenceWeight = referenceRecord?.value else { return nil }
        
        return latestRecord.value - referenceWeight
    }

    private var weightChangeValue: String {
        if let change = weightChange {
            return String(format: "%+.1f", change)
        } else {
            return "--"
        }
    }

    private var weightChangeColor: Color {
        if let change = weightChange {
            return change > 0 ? .red : .green
        } else {
            return .primary
        }
    }
    
    private var goalAchievementPercentage: String {
        let targetWeight = profileViewModel.userProfile.targetWeight
        guard let latestWeight = records.first?.value else {
            return "--"
        }
        
        var progress: Double = 0
        if targetWeight > 0 {
            if latestWeight <= targetWeight {
                progress = 1.0
            } else {
                progress = targetWeight / latestWeight
            }
        }
        
        return String(format: "%.0f", progress * 100)
    }

    private var coreMetricsGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                StatsMetricCard(title: "体重变化", value: weightChangeValue, unit: "kg", icon: "scalemass.fill", color: weightChangeColor)
                StatsMetricCard(title: "目标达成", value: goalAchievementPercentage, unit: "%", icon: "checkmark.circle.fill", color: .blue)
            }
            StatsMetricCard(title: "总卡路里", value: String(format: "%.0f", totalCalories), unit: "kcal", icon: "flame.fill", color: .purple)
            StatsMetricCard(title: "运动天数", value: "\(workoutDays)", unit: "天", icon: "figure.walk", color: .orange)
        }
    }

    private var workoutAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("运动分析").font(.title3).bold()
            VStack(alignment: .leading, spacing: 12) {
                WorkoutProgress(type: "跑步", percentage: 0.67, color: .green)
                WorkoutProgress(type: "游泳", percentage: 0.50, color: .cyan)
                WorkoutProgress(type: "力量", percentage: 0.33, color: .purple)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
        }
    }

    private var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("智能建议").font(.title3).bold()
            VStack(alignment: .leading, spacing: 12) {
                SuggestionCard(text: "本周运动频率提升20%", color: .blue)
                SuggestionCard(text: "建议增加力量训练", color: .yellow)
            }
        }
    }
}

struct StatsMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    public var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .center) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                HStack(alignment: .lastTextBaseline) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .contentTransition(.numericText(countsDown: false))
                    Text(unit)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
        .frame(height: 100)
    }
}

struct WorkoutProgress: View {
    let type: String
    let percentage: Double
    let color: Color

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(type)
                Spacer()
                Text("\(Int(percentage * 100))%")
            }
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
    }
}

public struct SuggestionCard: View {
    let text: String
    let color: Color

    public var body: some View {
        HStack {
            Image(systemName: "lightbulb")
                .foregroundColor(color)
            Text(text)
                .font(.footnote)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}
