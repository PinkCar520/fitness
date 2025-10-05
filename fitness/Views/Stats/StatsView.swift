import SwiftUI
import SwiftData

struct StatsView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @Query(sort: \HealthMetric.date, order: .reverse) private var records: [HealthMetric]
    
    @State private var selectedTimeFrame: TimeFrame = .sevenDays
    @State private var totalCalories: Double = 0
    @State private var workoutDays: Int = 0
    @State private var reportImage: UIImage?
    @State private var showShareSheet = false

    enum TimeFrame: String, CaseIterable {
        case sevenDays = "周"
        case thirtyDays = "月"
        case threeMonths = "季"
        case halfYear = "半年"
        case oneYear = "年"
        
        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .threeMonths: return 90
            case .halfYear: return 180
            case .oneYear: return 365
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    timeFrameSwitcher
                    coreMetricsGrid
                    ChartSection(selectedTimeFrame: selectedTimeFrame, targetWeight: profileViewModel.userProfile.targetWeight)
                    workoutAnalysisSection
                    smartSuggestionsSection
                }
                .padding()
            }
            .navigationTitle("统计")
            .onAppear(perform: fetchStats)
            .onChange(of: selectedTimeFrame) {
                fetchStats()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let reportImage = self.reportImage {
                ShareSheet(items: [reportImage])
            }
        }
    }

    private var timeFrameSwitcher: some View {
        Picker("Time Frame", selection: $selectedTimeFrame) {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                Text(timeFrame.rawValue).tag(timeFrame)
            }
        }
        .pickerStyle(.segmented)
    }

    private var weightChange: Double? {
        guard records.count > 1 else { return nil }
        
        let days = selectedTimeFrame.days
        guard days > 0 else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        
        let latestRecord = records[0]
        
        guard let referenceDate = calendar.date(byAdding: .day, value: -days, to: now) else { return nil }
        
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
        guard let currentWeight = records.first?.value else {
            return "--"
        }
        guard let startWeight = records.last?.value else {
            return "--"
        }
        
        let progress = (startWeight > 0 && startWeight != targetWeight) ? (startWeight - currentWeight) / (startWeight - targetWeight) : 0
        
        let clampedProgress = max(0, min(progress, 1))

        return String(format: "%.0f", clampedProgress * 100)
    }

    private var coreMetricsGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                StatsMetricCard(title: "体重变化", value: weightChangeValue, unit: "kg", icon: "scalemass.fill", color: weightChangeColor)
                    .animation(.easeInOut, value: weightChangeValue)
                StatsMetricCard(title: "目标达成", value: goalAchievementPercentage, unit: "%", icon: "checkmark.circle.fill", color: .blue)
                    .animation(.easeInOut, value: goalAchievementPercentage)
            }
            StatsMetricCard(title: "总卡路里", value: String(format: "%.0f", totalCalories), unit: "kcal", icon: "flame.fill", color: .purple)
                .animation(.easeInOut, value: totalCalories)
            StatsMetricCard(title: "运动天数", value: "\(workoutDays)", unit: "天", icon: "figure.walk", color: .orange)
                .animation(.easeInOut, value: workoutDays)
        }
    }

    private var workoutAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("运动分析").font(.title3).bold()
            VStack(alignment: .leading, spacing: 12) {
                if let pushups = profileViewModel.userProfile.benchmarks?.pushups {
                    WorkoutProgress(type: "俯卧撑基准", percentage: Double(pushups) / 100.0, color: .red) // Assuming 100 is a max benchmark for visualization
                }
                WorkoutProgress(type: "跑步", percentage: 0.67, color: .green)
                WorkoutProgress(type: "游泳", percentage: 0.50, color: .cyan)
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
                if let bodyType = profileViewModel.userProfile.bodyType?.current {
                    switch bodyType {
                    case .slim:
                        SuggestionCard(text: "建议增加健康卡路里摄入", color: .blue)
                    case .heavy:
                        SuggestionCard(text: "建议关注减脂和有氧训练", color: .orange)
                    default:
                        SuggestionCard(text: "保持均衡训练，持续进步", color: .green)
                    }
                } else {
                    SuggestionCard(text: "本周运动频率提升20%", color: .blue)
                    SuggestionCard(text: "建议增加力量训练", color: .yellow)
                }
            }
        }
    }

    private var actionButtonsSection: some View {
        Button(action: {
            let reportView = ReportView(
                profileViewModel: profileViewModel,
                selectedTimeFrame: selectedTimeFrame,
                totalCalories: totalCalories,
                workoutDays: workoutDays
            )
            self.reportImage = reportView.snapshot()
            self.showShareSheet = true
        }) { 
            Label("分享报告", systemImage: "square.and.arrow.up")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
    
    private func fetchStats() {
        healthKitManager.fetchTotalActiveEnergy(for: selectedTimeFrame.days) { calories in
            self.totalCalories = calories
        }
        healthKitManager.fetchWorkoutDays(for: selectedTimeFrame.days) { days in
            self.workoutDays = days
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        // This preview will need a model container to work correctly.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)
        
        return StatsView()
            .modelContainer(container)
            .environmentObject(ProfileViewModel())
            .environmentObject(HealthKitManager())
    }
}