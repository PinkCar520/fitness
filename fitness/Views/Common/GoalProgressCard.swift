import SwiftUI
import SwiftData
import HealthKit // Add HealthKit import

struct GoalProgressCard: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel // Still needed for targetWeight

    @Binding var showInputSheet: Bool
    @State private var showingBodyMetricsSheet = false

    let latestWeightSample: HKQuantitySample? // New property

    // Query to fetch weight metrics directly from SwiftData, sorted by date.
    // Still keep this for historical data and comparison, but current value comes from latestWeightSample
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    private var latestWeightValueDouble: Double {
        latestWeightSample?.quantity.doubleValue(for: .gramUnit(with: .kilo)) ?? weightMetrics.last?.value ?? 0.0
    }

    var body: some View {
        NavigationLink(destination: GoalDetailView()) {
            VStack(spacing: 16) {
                // 上半部分 HStack
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    // 左侧 HStack：当前体重 + 单位（上下结构） + 体重对比信息（紧靠当前体重右侧，垂直排列）
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            let weightParts = latestWeightValue.split(separator: ".")
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .firstTextBaseline, spacing: 0) {
                                    Text(weightParts.first ?? "")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundStyle(Color.primary.opacity(0.8))
                                    if weightParts.count > 1 {
                                        Text(".\(weightParts[1])")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(Color.primary.opacity(0.8))
                                    }
                                }
                                .contentTransition(.numericText(countsDown: false))
                                Text("kg")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(comparisonChange.change)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(comparisonChange.color)
                            Text(comparisonChange.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onTapGesture {
                        showingBodyMetricsSheet = true
                    }
                    Spacer()
                    // 右侧：+按钮
                    Button(action: { showInputSheet = true }) {
                        Image(systemName: "plus")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue.gradient)
                            .clipShape(Circle())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)

                // 下半部分 VStack
                VStack(spacing: 8) {
                    ZStack {
                        // 底层：灰色波点半圆
                        SemicircleShape()
                            .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, dash: [0, 12]))
                            .foregroundStyle(Color.gray.opacity(0.3))
                            .frame(height: 100)
                        
                        // 前景：完成部分
                        SemicircleShape(progress: progressValue)
                            .trim(from: 0, to: progressValue)
                            .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, dash: [0, 12]))
                            .foregroundStyle(progressValue >= 1.0 ? Color.orange : Color.green)
                            .frame(height: 100)
                        
                        // 中间垂直结构
                        if progressValue >= 1.0 {
                            VStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.orange)
                                    .font(.title2)
                                Text("目标已达成")
                                    .font(.system(size: 20))
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.clear)
                        } else if progressValue > 0 {
                            // 进度未达 100%，显示百分比
                            Text("\(Int(progressValue * 100))%")
                                .font(.system(size: 28))
                                .fontWeight(.bold)
                                .contentTransition(.numericText(countsDown: false))
                                .foregroundColor(.accentColor)
                                .frame(width: 100, height: 100)
                        } else {
                            // 进度为 0%，显示“继续加油”+火焰图标
                            VStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                                Text("继续加油")
                                    .font(.system(size: 18))
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            .frame(width: 100, height: 100)
                        }
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text("\(startWeight, specifier: "%.1f") kg")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                            .offset(x: 20)
                        Spacer()
                        Text(latestDateText)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(targetWeight, specifier: "%.1f") kg")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                            .offset(x: -20)
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 80)
            }
            .padding(.vertical, 16)
            .padding(20)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .animation(.easeInOut, value: latestWeightValueDouble)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingBodyMetricsSheet) {
            BodyMetricsView()
        }
    }

    // MARK: - Computed Properties for UI (Refactored for SwiftData)

    private var latestWeightValue: String {
        if let weight = latestWeightSample?.quantity.doubleValue(for: .gramUnit(with: .kilo)) {
            return weight.formatted(.number.precision(.fractionLength(1)))
        }
        return weightMetrics.last?.value.formatted(.number.precision(.fractionLength(1))) ?? "--"
    }

    private var startWeight: Double {
        weightMetrics.first?.value ?? weightMetrics.last?.value ?? 0
    }

    private var targetWeight: Double {
        profileViewModel.userProfile.targetWeight
    }

    private var latestDateText: String {
        if let record = weightMetrics.last {
            return "\(record.date.MMddHHmm)"
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

    private var comparisonChange: (change: String, color: Color, description: String) {
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

struct GoalProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)

        // Create a mock HKQuantitySample for preview
        let mockWeightSample = HKQuantitySample(
            type: HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            quantity: HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: 70.5),
            start: Date(),
            end: Date()
        )

        GoalProgressCard(showInputSheet: .constant(false), latestWeightSample: mockWeightSample)
            .modelContainer(container)
            .environmentObject(ProfileViewModel()) // ProfileViewModel is still needed
    }
}