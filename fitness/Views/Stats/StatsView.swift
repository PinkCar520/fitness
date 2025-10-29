import SwiftUI
import SwiftData
import Charts

// Data structure for the pie chart
struct WorkoutTypeDistribution: Identifiable {
    var id: WorkoutType { type }
    let type: WorkoutType
    let count: Int
}

// Data structure for PRs
struct PersonalRecords {
    let heaviestLift: (workoutName: String, weight: Double)?
    let longestRun: (distance: Double, duration: TimeInterval)?
}

struct StatsView: View {
    // Time Frame Selection
    enum TimeFrame: String, CaseIterable, Identifiable {
        case sevenDays = "周"
        case thirtyDays = "月"
        case ninetyDays = "季"
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            }
        }
    }
    @State private var selectedTimeFrame: TimeFrame = .thirtyDays
    @StateObject private var viewModel = StatsViewModel()
    @State private var reportImage: UIImage? = nil
    @State private var showShareSheet = false

    // Environment & Data Sources
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]
    @Query(filter: #Predicate<Plan> { $0.status == "active" }) private var activePlans: [Plan]

    // State for fetched data
    @State private var totalCalories: Double = 0
    @State private var workoutDays: Int = 0

    // Computed property for workout frequency chart
    private var relevantWorkouts: [Workout] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -selectedTimeFrame.days, to: endDate) else {
            return []
        }
        return workouts.filter { $0.date >= startDate && $0.date <= endDate }
    }

    private var workoutFrequencyData: [WeeklyWorkoutActivity] {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: relevantWorkouts) { workout -> Date in
            calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.date))!
        }

        return groupedByWeek.map { (weekStartDate, workoutsInWeek) -> WeeklyWorkoutActivity in
            return WeeklyWorkoutActivity(weekOf: weekStartDate, count: workoutsInWeek.count)
        }.sorted(by: { $0.weekOf < $1.weekOf })
    }
    
    private var workoutTypeDistributionData: [WorkoutTypeDistribution] {
        let groupedByType = Dictionary(grouping: relevantWorkouts, by: { $0.type })
        
        return groupedByType.map { (type, workouts) in
            WorkoutTypeDistribution(type: type, count: workouts.count)
        }.sorted { $0.count > $1.count }
    }
    
    private var personalRecords: PersonalRecords {
        var heaviestLift: (workoutName: String, weight: Double)? = nil
        var longestRun: (distance: Double, duration: TimeInterval)? = nil
        
        let strengthWorkouts = relevantWorkouts.filter { $0.type == .strength }
        var maxWeight: Double = 0
        
        for workout in strengthWorkouts {
            for set in workout.sets ?? [] {
                if let weight = set.weight { // Safely unwrap set.weight
                    if weight > maxWeight {
                        maxWeight = weight
                        heaviestLift = (workout.name, maxWeight)
                    }
                }
            }
        }
        
        let cardioWorkouts = relevantWorkouts.filter { $0.type == .cardio }
        var maxDistance: Double = 0
        
        for workout in cardioWorkouts {
            if let distance = workout.distance, distance > maxDistance {
                maxDistance = distance
                longestRun = (maxDistance, workout.duration ?? 0)
            }
        }
        
        return PersonalRecords(heaviestLift: heaviestLift, longestRun: longestRun)
    }


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Time Frame Picker
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases) { timeFrame in
                            Text(timeFrame.rawValue).tag(timeFrame)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Core Metrics Grid
                    VStack(alignment: .leading) {
                        Text("核心指标")
                            .font(.title3).bold()
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            MetricCard(title: "运动天数", value: "\(viewModel.workoutDays)", unit: "天", icon: "figure.walk", color: .orange)
                            MetricCard(title: "总消耗", value: String(format: "%.0f", viewModel.totalCalories), unit: "千卡", icon: "flame.fill", color: .red)
                        }
                    }

                    executionSummarySection

                    // Workout Frequency Chart
                    WorkoutFrequencyChartView(data: workoutFrequencyData)
                    
                    // Workout Type Distribution
                    WorkoutTypePieChartView(data: workoutTypeDistributionData)
                    
                    // VO2max Trend
                    GenericLineChartView(
                        title: "VO2max 趋势",
                        data: viewModel.vo2MaxTrend,
                        color: .teal,
                        unit: "ml/kg/min"
                    )

                    // Weight and Body Fat Trends
                    GenericLineChartView(
                        title: "体重趋势",
                        data: viewModel.weightTrend,
                        color: .blue,
                        unit: "kg"
                    )
                    GenericLineChartView(
                        title: "体脂率趋势",
                        data: viewModel.bodyFatTrend,
                        color: .orange,
                        unit: "%"
                    )

                    Button {
                        let reportStack = VStack(alignment: .leading, spacing: 16) {
                            Text("分析报告（\(selectedTimeFrame.rawValue)）").font(.headline)
                            executionSummarySection
                            WorkoutFrequencyChartView(data: workoutFrequencyData)
                            WorkoutTypePieChartView(data: workoutTypeDistributionData)
                        }
                        .padding()
                        self.reportImage = reportStack.snapshot()
                        self.showShareSheet = true
                    } label: {
                        Label("分享分析报告", systemImage: "square.and.arrow.up")
                            .font(.footnote.weight(.bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    // Personal Records
                    PersonalRecordsView(records: personalRecords)


                }
                .padding()
            }
            .navigationTitle("统计")
            .onAppear(perform: refreshAll)
            .onChange(of: selectedTimeFrame) { _ in
                refreshAll()
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = reportImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    private var executionSummarySection: some View {
        let ex = viewModel.execution
        return VStack(alignment: .leading, spacing: 8) {
            Text("计划执行度").font(.title3).bold()
            HStack(spacing: 12) {
                badge("完成", value: "\(ex.completedDays)", color: .green)
                badge("跳过", value: "\(ex.skippedDays)", color: .orange)
                badge("连续", value: "\(ex.streakDays) 天", color: .blue)
                Spacer()
                Text("完成率 \(Int(ex.completionRate * 100))%")
                    .font(.headline).foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func badge(_ title: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(title) \(value)").font(.caption).fontWeight(.semibold)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(color.opacity(0.12))
        .cornerRadius(8)
    }

    private func refreshAll() {
        healthKitManager.fetchTotalActiveEnergy(for: selectedTimeFrame.days) { calories in
            self.viewModel.totalCalories = calories
        }
        healthKitManager.fetchWorkoutDays(for: selectedTimeFrame.days) { days in
            self.viewModel.workoutDays = days
        }
        self.viewModel.execution = buildExecutionSummary(days: selectedTimeFrame.days)
        self.viewModel.vo2MaxTrend = viewModel.buildTrend(from: allMetrics, type: .vo2Max, last: selectedTimeFrame.days)
        self.viewModel.weightTrend = viewModel.buildTrend(from: allMetrics, type: .weight, last: selectedTimeFrame.days)
        self.viewModel.bodyFatTrend = viewModel.buildTrend(from: allMetrics, type: .bodyFatPercentage, last: selectedTimeFrame.days)
    }

    private func buildExecutionSummary(days: Int) -> StatsViewModel.ExecutionSummary {
        guard let plan = activePlans.first else { return .init(completedDays: 0, skippedDays: 0, streakDays: 0) }
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        let tasks = plan.dailyTasks.filter { $0.date >= start && $0.date <= now }.sorted { $0.date < $1.date }
        let completed = tasks.filter { $0.isCompleted }.count
        let skipped = tasks.filter { $0.isSkipped }.count
        var streak = 0
        var dateCursor = calendar.startOfDay(for: now)
        let index = Dictionary(grouping: tasks, by: { calendar.startOfDay(for: $0.date) })
        while let task = index[dateCursor]?.first, task.isCompleted {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: dateCursor) else { break }
            dateCursor = prev
        }
        return .init(completedDays: completed, skippedDays: skipped, streakDays: streak)
    }
}


// Bar chart view for workout frequency
struct WorkoutFrequencyChartView: View {
    let data: [WeeklyWorkoutActivity]

    var body: some View {
        VStack(alignment: .leading) {
            Text("每周锻炼频率")
                .font(.title3).bold()
            
            Chart(data) { item in
                BarMark(
                    x: .value("Week", item.weekOf, unit: .weekOfYear),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Color.green.gradient)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.week(.defaultDigits))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Workout.self, configurations: config)
        
        // Add sample workout data
        for i in 0..<90 {
            if i % 3 == 0 { // Add a workout every 3 days
                let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                let workout = Workout(name: "Sample Workout", durationInMinutes: 30, caloriesBurned: 200, date: date, type: .other)
                container.mainContext.insert(workout)
            }
        }

        return StatsView()
            .modelContainer(container)
    }
}

// Pie chart for workout type distribution
struct WorkoutTypePieChartView: View {
    let data: [WorkoutTypeDistribution]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("运动类型分布")
                .font(.title3).bold()
            
            Chart(data) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.618),
                    angularInset: 2.0
                )
                .foregroundStyle(by: .value("Type", item.type.rawValue))
                .cornerRadius(8)
            }
            .chartLegend(position: .bottom, alignment: .center)
            .frame(height: 220)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// View for Personal Records
struct PersonalRecordsView: View {
    let records: PersonalRecords
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("个人最佳记录 (PR)")
                .font(.title3).bold()
            
            if records.heaviestLift == nil && records.longestRun == nil {
                ContentUnavailableView("无记录", systemImage: "trophy.slash", description: Text("完成一些训练来解锁您的个人记录。"))
                    .frame(height: 150)
            } else {
                VStack(spacing: 10) {
                    if let lift = records.heaviestLift {
                        HStack {
                            Image(systemName: "dumbbell.fill").foregroundColor(.blue)
                            Text("最重举重 ('\(lift.workoutName)')")
                            Spacer()
                            Text("\(lift.weight, specifier: "%.1f") kg").bold()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if let run = records.longestRun {
                        HStack {
                            Image(systemName: "figure.run").foregroundColor(.green)
                            Text("最长跑步距离")
                            Spacer()
                            Text("\(run.distance, specifier: "%.2f") km").bold()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
