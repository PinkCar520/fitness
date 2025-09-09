import SwiftUI

struct StatsView: View {
    @State private var selectedTimeFrame: TimeFrame = .sevenDays

    enum TimeFrame: String, CaseIterable {
        case sevenDays = "7天"
        case thirtyDays = "30天"
        case threeMonths = "3月"
        case oneYear = "1年"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Time Frame Switcher
                    timeFrameSwitcher

                    // Core Metrics Grid
                    coreMetricsGrid

                    // Weight Trend Chart
                    ChartSection()

                    // Workout Analysis (Placeholder)
                    workoutAnalysisSection

                    // Smart Suggestions (Placeholder)
                    smartSuggestionsSection

                    // Action Buttons (Placeholder)
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle("统计")
        }
    }

    private var timeFrameSwitcher: some View {
        HStack {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                Button(action: {
                    selectedTimeFrame = timeFrame
                }) {
                    Text(timeFrame.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(selectedTimeFrame == timeFrame ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedTimeFrame == timeFrame ? .white : .primary)
                        .cornerRadius(10)
                }
            }
        }
    }

    private var coreMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            StatsMetricCard(title: "体重变化", value: "-1.2", unit: "kg", icon: "scalemass.fill", color: .green)
            StatsMetricCard(title: "目标达成", value: "85", unit: "%", icon: "checkmark.circle.fill", color: .blue)
            StatsMetricCard(title: "总卡路里", value: "2,30", unit: "kcal", icon: "flame.fill", color: .purple)
            StatsMetricCard(title: "运动天数", value: "5", unit: "天", icon: "figure.walk", color: .orange)
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
            .background(Color.gray.opacity(0.1))
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

    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button(action: {}) {
                Label("导出数据", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            Button(action: {}) {
                Label("分享报告", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
}

private struct StatsMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
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
                    Text(unit)
                        .font(.headline)
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

    var body: some View {
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

struct SuggestionCard: View {
    let text: String
    let color: Color

    var body: some View {
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
