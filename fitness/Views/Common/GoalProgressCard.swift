import SwiftUI
import SwiftData

struct GoalProgressCard: View {
    // The WeightManager is still needed for actions, but not for data display.
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var profileViewModel: ProfileViewModel

    // Query to fetch weight metrics directly from SwiftData, sorted by date.
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]

    @Binding var showInputSheet: Bool
    @State private var showingBodyMetricsSheet = false

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Top Row: Main Info and Actions
            HStack(alignment: .top) {
                // Weight Button with Overlay for Comparison Text
                Button(action: { showingBodyMetricsSheet = true }) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(latestWeightValue)
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.primary)
                        Text("kg")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    // Add padding to create space for the overlay to sit in
                    .padding(.trailing, 65)
                }
                .buttonStyle(PlainButtonStyle())
                .overlay(alignment: .bottomTrailing) { // Align overlay to the button's frame
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(weeklyChange.change)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(weeklyChange.color)
                        Text(weeklyChange.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 4)
                }

                Spacer()

                // Add Button
                Button(action: { showInputSheet = true }) {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue.gradient)
                        .clipShape(Circle())
                }
            }

            // Navigation Link for the rest of the content
            NavigationLink(destination: GoalDetailView()) {
                VStack(spacing: 8) {
                    // Progress Section
                    ProgressView(value: progressValue)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .scaleEffect(x: 1, y: 2.5, anchor: .center)

                    HStack {
                        Text("起点: \(startWeight, specifier: "%.1f") kg")
                        Spacer()
                        Text("目标: \(targetWeight, specifier: "%.1f") kg")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Last Record Date and Percentage
                    HStack(spacing: 6) {
                        Text(latestDateText)
                        Spacer()
                        Text("已完成 \(Int(progressValue * 100))%")
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .sheet(isPresented: $showingBodyMetricsSheet) {
            BodyMetricsView()
        }
    }

    // MARK: - Computed Properties for UI (Refactored for SwiftData)

    private var latestWeightValue: String {
        weightMetrics.last?.value.formatted(.number.precision(.fractionLength(1))) ?? "--"
    }

    private var startWeight: Double {
        weightMetrics.first?.value ?? weightMetrics.last?.value ?? 0
    }

    private var targetWeight: Double {
        profileViewModel.userProfile.targetWeight
    }

    private var latestDateText: String {
        if let record = weightMetrics.last {
            return "上次记录: \(record.date.MMddHHmm)"
        }
        return "暂无记录"
    }

    private var progressValue: Double {
        let current = weightMetrics.last?.value ?? 0
        if startWeight == targetWeight { return current == targetWeight ? 1.0 : 0.0 }
        guard startWeight > 0 else { return 0.0 } // Avoid division by zero if startWeight is 0
        let progress = (startWeight - current) / (startWeight - targetWeight)
        return max(0, min(1, progress))
    }

    private var weeklyChange: (change: String, color: Color, description: String) {
        guard weightMetrics.count >= 2 else { return ("--", .primary, "无历史数据对比") }

        let latest = weightMetrics.last!
        let previous = weightMetrics[weightMetrics.count - 2]
        let change = latest.value - previous.value
        
        let dayDifference = Calendar.current.dateComponents([.day], from: previous.date, to: latest.date).day ?? 0
        let description = dayDifference <= 1 ? "对比上次" : "对比\(dayDifference)天前"
        
        if abs(change) < 0.01 {
            return ("0.0 kg", .primary, description)
        } else if change > 0 {
            return (String(format: "+%.1f kg", change), .red, description)
        } else {
            return (String(format: "%.1f kg", change), .green, description)
        }
    }
}