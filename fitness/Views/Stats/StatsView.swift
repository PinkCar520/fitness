import SwiftUI
import SwiftData
import Charts
import HealthKit

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
    @State private var showDayInfo: Bool = false
    @State private var dayInfoText: String = ""

    // Environment & Data Sources
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var appState: AppState
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]
    @Query(filter: #Predicate<Plan> { $0.status == "active" }) private var activePlans: [Plan]

    // Correlation metric selection
    enum CorrelationMetric: String, CaseIterable, Identifiable { case weight = "体重", bodyFat = "体脂率"; var id: String { rawValue } }
    @State private var selectedCorrelation: CorrelationMetric = .weight

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
                    permissionBanner
                    emptyStateBanner
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

                    // Daily Execution Heatmap
                    DailyHeatmapView(days: dailyStatuses, onTap: { date in
                        appState.selectedTab = 1
                        NotificationCenter.default.post(name: .navigateToPlanDate, object: nil, userInfo: ["date": date])
                    }, onLongPress: { status in
                        dayInfoText = heatmapInfoText(for: status)
                        showDayInfo = true
                    })

                    // Workout Frequency Chart
                    WorkoutFrequencyChartView(data: workoutFrequencyData)
                    
                    // Workout Type Distribution
                    WorkoutTypePieChartView(data: workoutTypeDistributionData)
                    
                    // Type Efficiency Card
                    typeEfficiencySection

                    // VO2max Trend
                    if !healthKitManager.isVO2MaxAvailableOnThisDevice() {
                        infoBanner(text: "VO2max 需要支持的设备（通常为 Apple Watch）")
                    } else if healthKitManager.getPublishedAuthorizationStatus(for: .vo2Max) != .sharingAuthorized {
                        infoBanner(text: "未授权读取 VO2max，请在健康 App 中授权")
                    } else if viewModel.vo2MaxTrend.isEmpty {
                        infoBanner(text: "暂无 VO2max 数据，佩戴 Apple Watch 进行户外步行/跑步以生成测量")
                    }
                    GenericLineChartView(
                        title: "VO2max 趋势",
                        data: viewModel.vo2MaxTrend,
                        color: .teal,
                        unit: "ml/kg/min"
                    )

                    // Weight and Body Fat Trends
                    // Weight trend with average and goal line
                    Group {
                        let weightAvg: Double? = {
                            let vals = viewModel.weightTrend.map { $0.value }
                            guard !vals.isEmpty else { return nil }
                            return vals.reduce(0,+) / Double(vals.count)
                        }()
                        let goal: Double? = activePlans.first?.planGoal.targetWeight
                        GenericLineChartView(
                            title: "体重趋势",
                            data: viewModel.weightTrend,
                            color: .blue,
                            unit: "kg",
                            averageValue: weightAvg,
                            goalValue: goal
                        )
                    }
                    // BodyFat with average line
                    Group {
                        let fatAvg: Double? = {
                            let vals = viewModel.bodyFatTrend.map { $0.value }
                            guard !vals.isEmpty else { return nil }
                            return vals.reduce(0,+) / Double(vals.count)
                        }()
                        GenericLineChartView(
                            title: "体脂率趋势",
                            data: viewModel.bodyFatTrend,
                            color: .orange,
                            unit: "%",
                            averageValue: fatAvg,
                            goalValue: nil
                        )
                    }

                    // Weight vs Calories (stacked)
                    GenericLineChartView(
                        title: "每日消耗（卡路里）",
                        data: dailyCaloriesSeries,
                        color: .pink,
                        unit: "kcal"
                    )

                    // Correlation: Weight/BodyFat vs Calories
                    correlationSection

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
            .onAppear { healthKitManager.updateAuthorizationStatuses() }
            .onChange(of: selectedTimeFrame) { _ in
                refreshAll()
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = reportImage {
                    ShareSheet(items: [image])
                }
            }
            .alert("当天执行详情", isPresented: $showDayInfo) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(dayInfoText)
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
        // Prefer HealthKit VO2max series when available and authorized; fallback to local metrics
        if healthKitManager.getPublishedAuthorizationStatus(for: .vo2Max) == .sharingAuthorized,
           healthKitManager.isVO2MaxAvailableOnThisDevice() {
            Task { @MainActor in
                let samples = await healthKitManager.fetchVO2MaxSeries(for: selectedTimeFrame.days)
                let unit = HKUnit(from: "mL/kg/min")
                self.viewModel.vo2MaxTrend = samples.map { sample in
                    DateValuePoint(date: sample.endDate, value: sample.quantity.doubleValue(for: unit))
                }
            }
        } else {
            self.viewModel.vo2MaxTrend = viewModel.buildTrend(from: allMetrics, type: .vo2Max, last: selectedTimeFrame.days)
        }
        self.viewModel.weightTrend = viewModel.buildTrend(from: allMetrics, type: .weight, last: selectedTimeFrame.days)
        self.viewModel.bodyFatTrend = viewModel.buildTrend(from: allMetrics, type: .bodyFatPercentage, last: selectedTimeFrame.days)
    }

    // MARK: - Correlation Section (Weight vs Calories)
    private var correlationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("相关性（消耗 vs ")
                Picker("Correlation", selection: $selectedCorrelation) {
                    ForEach(CorrelationMetric.allCases) { m in Text(m.rawValue).tag(m) }
                }
                .pickerStyle(.segmented)
                Text(")").opacity(0.6)
                Spacer()
            }
            .font(.title3.bold())
            
            Chart(correlationPoints) { pt in
                PointMark(
                    x: .value("体重", pt.weight),
                    y: .value("消耗", pt.calories)
                )
                .foregroundStyle(Color.purple)
                // Trendline
                if let line = correlationTrendline {
                    LineMark(
                        x: .value("x", line.0.x), y: .value("y", line.0.y)
                    )
                    .foregroundStyle(Color.purple.opacity(0.5))
                    LineMark(
                        x: .value("x", line.1.x), y: .value("y", line.1.y)
                    )
                    .foregroundStyle(Color.purple.opacity(0.5))
                }
            }
            .frame(height: 220)
            Text(correlationSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private struct CorrelationPoint: Identifiable { let id = UUID(); let weight: Double; let calories: Double }

    private var correlationPoints: [CorrelationPoint] {
        // Build daily series for selected metric (latest on/before day)
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -selectedTimeFrame.days + 1, to: now) ?? now
        // Pre-sort metrics ascending by selected type
        let metricType: MetricType = (selectedCorrelation == .weight) ? .weight : .bodyFatPercentage
        let metricSeries = allMetrics.filter { $0.type == metricType }.sorted { $0.date < $1.date }
        let days = dateRange(from: start, to: now)
        var idx = 0
        var lastWeight: Double? = nil
        var weightsByDay: [Date: Double] = [:]
        for d in days {
            // advance idx to last metric <= d
            while idx < metricSeries.count && metricSeries[idx].date <= d { lastWeight = metricSeries[idx].value; idx += 1 }
            if let w = lastWeight { weightsByDay[d] = w }
        }
        // Calories by day from existing series
        let caloriesByDay = Dictionary(uniqueKeysWithValues: dailyCaloriesSeries.map { ($0.date, $0.value) })
        // Merge
        return days.compactMap { d in
            if let w = weightsByDay[d], let c = caloriesByDay[d], w > 0, c >= 0 {
                return CorrelationPoint(weight: w, calories: c)
            }
            return nil
        }
    }

    private var correlationSubtitle: String {
        let points = correlationPoints
        guard points.count >= 3, let r = pearsonR(points: points) else {
            return "提示：相关性仅供参考，饮食与训练强度等因素也会影响体重/体脂变化。"
        }
        return String(format: "相关系数 r = %.2f（仅供参考）", r)
    }

    // Simple Pearson correlation
    private func pearsonR(points: [CorrelationPoint]) -> Double? {
        let n = Double(points.count)
        guard n >= 2 else { return nil }
        let xs = points.map { $0.weight }
        let ys = points.map { $0.calories }
        let meanX = xs.reduce(0,+) / n
        let meanY = ys.reduce(0,+) / n
        let cov = zip(xs, ys).reduce(0.0) { $0 + (($1.0 - meanX) * ($1.1 - meanY)) }
        let varX = xs.reduce(0) { $0 + pow($1 - meanX, 2) }
        let varY = ys.reduce(0) { $0 + pow($1 - meanY, 2) }
        let denom = sqrt(varX * varY)
        guard denom > 0 else { return nil }
        return cov / denom
    }

    // Regression line endpoints for scatter chart
    private var correlationTrendline: ((x: Double, y: Double), (x: Double, y: Double))? {
        let pts = correlationPoints
        guard pts.count >= 2 else { return nil }
        let xs = pts.map { $0.weight }
        let ys = pts.map { $0.calories }
        let n = Double(pts.count)
        let meanX = xs.reduce(0,+) / n
        let meanY = ys.reduce(0,+) / n
        let sxy = zip(xs, ys).reduce(0.0) { $0 + (($1.0 - meanX) * ($1.1 - meanY)) }
        let sxx = xs.reduce(0) { $0 + pow($1 - meanX, 2) }
        guard sxx > 0 else { return nil }
        let b = sxy / sxx
        let a = meanY - b * meanX
        guard let minX = xs.min(), let maxX = xs.max() else { return nil }
        return ((x: minX, y: a + b * minX), (x: maxX, y: a + b * maxX))
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

    // MARK: - Permission & Empties
    private var permissionBanner: some View {
        let required: [HealthKitDataTypeOption] = [.activeEnergyBurned, .workout]
        let unauthorized = required.filter { healthKitManager.getPublishedAuthorizationStatus(for: $0) != .sharingAuthorized }
        return Group {
            if !unauthorized.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text("未授权读取运动与能量数据").font(.headline)
                    }
                    Text("请在健康 App 中授权“体能训练、活动能量”，以便生成完整的分析与报告。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Button(action: openHealthApp) { Label("前往健康 App 授权", systemImage: "heart.fill") }.buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }

    private var emptyStateBanner: some View {
        Group {
            if relevantWorkouts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("暂无训练记录")
                        .font(.headline)
                    Text("开始一次训练或从计划页选择今日任务，完成后这里会展示分析数据。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        appState.selectedTab = 1
                    } label: { Label("前往计划页", systemImage: "figure.run") }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }

    private func openHealthApp() {
        if let url = URL(string: "x-apple-health://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    @ViewBuilder private func infoBanner(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
            Text(text).font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private func heatmapInfoText(for status: DailyStatus) -> String {
        let dateText = status.date.formatted(date: .abbreviated, time: .omitted)
        let stateText: String
        switch status.state {
        case .completed: stateText = "已完成"
        case .skipped: stateText = "已跳过"
        case .none: stateText = "无记录"
        }
        return "\(dateText)：\(stateText)"
    }

    // MARK: - Heatmap Data
    private var dailyStatuses: [DailyStatus] {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -selectedTimeFrame.days + 1, to: now) ?? now
        guard let plan = activePlans.first else {
            return dateRange(from: start, to: now).map { DailyStatus(date: $0, state: .none) }
        }
        let index = Dictionary(grouping: plan.dailyTasks, by: { calendar.startOfDay(for: $0.date) })
        return dateRange(from: start, to: now).map { day in
            if let task = index[day]?.first {
                return DailyStatus(date: day, state: task.isCompleted ? .completed : (task.isSkipped ? .skipped : .none))
            } else {
                return DailyStatus(date: day, state: .none)
            }
        }
    }

    private func dateRange(from start: Date, to end: Date) -> [Date] {
        var days: [Date] = []
        var d = start
        let cal = Calendar.current
        while d <= end {
            days.append(d)
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        return days
    }

    // MARK: - Type Efficiency
    private var typeEfficiencySection: some View {
        let window = selectedTimeFrame.days
        let current = efficiencyMetrics(inLastDays: window)
        let previous = efficiencyMetrics(inLastDays: window, offset: window)
        let rows = current.map { (type, cur) -> (WorkoutType, (sessions: Int, minutes: Double, calories: Double), delta: Int) in
            let prev = previous[type]
            let delta = cur.sessions - (prev?.sessions ?? 0)
            return (type, cur, delta)
        }.sorted { $0.1.calories > $1.1.calories }

        return VStack(alignment: .leading, spacing: 8) {
            Text("类型效率").font(.title3).bold()
            ForEach(rows.prefix(3), id: \.0) { row in
                HStack {
                    Text(row.0.rawValue).font(.subheadline)
                    Spacer()
                    Text("\(Int(row.1.minutes)) 分 / \(Int(row.1.calories)) 千卡").font(.caption)
                    deltaBadge(row.delta)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func deltaBadge(_ delta: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
            Text("\(delta)")
        }
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((delta >= 0 ? Color.green : Color.red).opacity(0.15))
        .foregroundStyle(delta >= 0 ? Color.green : Color.red)
        .cornerRadius(8)
    }

    private func efficiencyMetrics(inLastDays days: Int, offset: Int = 0) -> [WorkoutType: (sessions: Int, minutes: Double, calories: Double)] {
        let cal = Calendar.current
        let end = cal.startOfDay(for: Date()).addingTimeInterval(TimeInterval(-offset * 86400))
        let start = cal.date(byAdding: .day, value: -days + 1, to: end) ?? end
        let windowWorkouts = workouts.filter { $0.date >= start && $0.date <= end }
        var dict: [WorkoutType: (sessions: Int, minutes: Double, calories: Double)] = [:]
        for w in windowWorkouts {
            let m = Double(w.durationInMinutes ?? 0)
            let c = Double(w.caloriesBurned)
            let cur = dict[w.type] ?? (sessions: 0, minutes: 0, calories: 0)
            dict[w.type] = (sessions: cur.sessions + 1, minutes: cur.minutes + m, calories: cur.calories + c)
        }
        return dict
    }

    // MARK: - Calories series by day (from workouts)
    private var dailyCaloriesSeries: [DateValuePoint] {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -selectedTimeFrame.days + 1, to: now) ?? now
        let relevant = workouts.filter { $0.date >= start && $0.date <= now }
        let grouped = Dictionary(grouping: relevant, by: { cal.startOfDay(for: $0.date) })
        let days = dateRange(from: start, to: now)
        return days.map { day in
            let sum = (grouped[day] ?? []).reduce(0) { $0 + $1.caloriesBurned }
            return DateValuePoint(date: day, value: Double(sum))
        }
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
