import SwiftUI
import SwiftData
import Charts

private enum TrajectoryTheme {
    static let primaryText = Color(red: 0.15, green: 0.18, blue: 0.28)
    static let secondaryText = Color(red: 0.15, green: 0.18, blue: 0.28).opacity(0.65)
    static let tertiaryText = Color(red: 0.15, green: 0.18, blue: 0.28).opacity(0.45)
    static let backgroundGradient: [Color] = [
        Color(red: 0.99, green: 0.99, blue: 0.97),
        Color(red: 0.97, green: 0.99, blue: 1.0),
        Color(red: 0.94, green: 0.97, blue: 1.0)
    ]
    static let primaryCard = Color.white
    static let secondaryCard = Color(red: 0.96, green: 0.98, blue: 1.0)
    static let frostedCard = Color(red: 0.97, green: 0.99, blue: 1.0).opacity(0.85)
    static let badgeFill = Color(red: 0.9, green: 0.95, blue: 1.0)
    static let border = Color.black.opacity(0.05)
    static let divider = Color.black.opacity(0.08)
    static let shadow = Color.black.opacity(0.08)
    static let indicatorActive = Color(red: 0.23, green: 0.44, blue: 0.86)
    static let indicatorInactive = Color.black.opacity(0.2)
}

// MARK: - Main View: Transformation Journey
struct HistoryListView: View {
    @EnvironmentObject var weightManager: WeightManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentPageIndex = 0
    @State private var selectedRange: BodyProfileViewModel.TimeRange = .month
    
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]
    @Query(sort: \Workout.date, order: .forward) private var allWorkouts: [Workout]

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    private var recentMetrics: [HealthMetric] {
        Array(weightMetrics.suffix(10))
    }

    private var latestMetric: HealthMetric? {
        weightMetrics.last
    }

    private var previousMetric: HealthMetric? {
        guard weightMetrics.count > 1 else { return nil }
        return weightMetrics.dropLast().last
    }

    private var workoutsByDay: [Date: [Workout]] {
        Dictionary(grouping: allWorkouts) { $0.date.startOfDay }
    }

    private var weightDelta: Double? {
        guard let latest = latestMetric, let previous = previousMetric else { return nil }
        return latest.value - previous.value
    }

    private var weeklyCheckIns: Int {
        guard let windowStart = Calendar.current.date(byAdding: .day, value: -6, to: Date()) else { return 0 }
        return weightMetrics.filter { $0.date >= windowStart }.count
    }

    private var consistencyProgress: Double {
        min(max(Double(weeklyCheckIns) / 7.0, 0), 1)
    }

    private var journeyPhase: (title: String, icon: String) {
        guard let delta = weightDelta else {
            return ("调频蓄力期", "bolt.heart.fill")
        }
        if delta < -0.5 {
            return ("减脂冲刺期", "flame.fill")
        } else if delta > 0.5 {
            return ("增肌加载期", "figure.strengthtraining.traditional")
        } else {
            return ("稳态巩固期", "waveform.path.ecg")
        }
    }

    private var consistencyDescription: String {
        switch consistencyProgress {
        case 0.8...:
            return "记录火力全开"
        case 0.4..<0.8:
            return "节奏渐入佳境"
        default:
            return "从今天开始积累"
        }
    }

    // Group records by selected time range start to create "pages"
    private var pages: [(periodStart: Date, records: [HealthMetric])] {
        let grouped: [Date: [HealthMetric]] = Dictionary(grouping: weightMetrics) { metric in
            switch selectedRange {
            case .week:
                return metric.date.startOfWeek
            case .month:
                return metric.date.startOfMonth
            case .quarter:
                return metric.date.startOfQuarter
            case .year:
                return metric.date.startOfYear
            }
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { ($0.key, $0.value.sorted(by: { $0.date > $1.date })) }
    }

    private var safeCurrentIndex: Int {
        guard !pages.isEmpty else { return 0 }
        return min(currentPageIndex, max(pages.count - 1, 0))
    }

    private var selectedPeriodLabel: String {
        guard !pages.isEmpty else {
            return "等待你的首条记录"
        }
        let start = pages[safeCurrentIndex].periodStart
        switch selectedRange {
        case .week:
            let cal = Calendar.current
            let end = cal.date(byAdding: .day, value: 6, to: start) ?? start
            let startStr = start.formatted(.dateTime.year().month().day())
            let endStr = min(end, Date()).formatted(.dateTime.year().month().day())
            return "\(startStr) - \(endStr)"
        case .month:
            return start.formatted(.dateTime.year().month())
        case .quarter:
            let quarter = ((Calendar.current.component(.month, from: start) - 1) / 3) + 1
            let year = Calendar.current.component(.year, from: start)
            return "\(year)年第\(quarter)季度"
        case .year:
            return start.formatted(.dateTime.year())
        }
    }

    private var pageSelection: Binding<Int> {
        Binding(
            get: { safeCurrentIndex },
            set: { newValue in currentPageIndex = newValue }
        )
    }

    private var trendRangeLabel: String {
        guard let first = recentMetrics.first?.date,
              let last = recentMetrics.last?.date else {
            return "暂无波动数据"
        }
        return "\(first.formatted(.dateTime.month().day())) → \(last.formatted(.dateTime.month().day()))"
    }

    private var trendStats: (min: Double, max: Double)? {
        guard let min = recentMetrics.map(\.value).min(),
              let max = recentMetrics.map(\.value).max() else {
            return nil
        }
        return (min, max)
    }

    private var latestWorkoutSummary: WorkoutDaySummary? {
        guard let latestMetric else { return nil }
        return workoutSummary(for: latestMetric.date)
    }

    private func workoutSummary(for date: Date) -> WorkoutDaySummary? {
        let day = date.startOfDay
        guard let workouts = workoutsByDay[day], !workouts.isEmpty else { return nil }

        let totalMinutes = workouts.reduce(0) { $0 + workoutDurationMinutes(for: $1) }
        let totalCalories = workouts.reduce(0) { $0 + $1.caloriesBurned }
        let dominantType = workouts.reduce(into: [WorkoutType: Int]()) { counts, workout in
            counts[workout.type, default: 0] += 1
        }
        .max(by: { $0.value < $1.value })?.key ?? workouts[0].type

        let highlightNames = Array(workouts.prefix(2).map(\.name))

        return WorkoutDaySummary(
            date: day,
            dominantType: dominantType,
            workoutCount: workouts.count,
            totalDurationInMinutes: totalMinutes,
            totalCalories: totalCalories,
            highlightNames: highlightNames
        )
    }

    private func workoutDurationMinutes(for workout: Workout) -> Int {
        if let minutes = workout.durationInMinutes {
            return max(minutes, 0)
        }
        if let duration = workout.duration {
            return max(Int(duration / 60), 0)
        }
        return 0
    }

    var body: some View {
        NavigationStack {
            journeyContent
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .toolbar {
                    ToolbarItem() {
                        Button(action: { dismiss() }) {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.black)
                        }
                    }
                }
                .toolbar(removing: .title)
        }
        .overlay(alignment: .bottomTrailing) {
            bottomControls
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .onChange(of: selectedRange) { _ in
            currentPageIndex = 0
        }
    }

    private var journeyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                summaryHero

                if !recentMetrics.isEmpty {
                    trendView
                }

                Divider()
                    .overlay(TrajectoryTheme.divider)
                    .padding(.vertical, 4)

                timelineSection
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .foregroundStyle(TrajectoryTheme.primaryText)
        }
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("蜕变轨迹")
                    .font(.title3)
                    .fontWeight(.bold)
                Text(selectedPeriodLabel)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(TrajectoryTheme.secondaryText)
            }
            Spacer()
            phaseBadge
        }
    }

    private var phaseBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: journeyPhase.icon)
                .font(.caption)
            Text(journeyPhase.title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(TrajectoryTheme.badgeFill)
        .clipShape(Capsule())
        .glassEffect()
    }

    private var summaryHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("当前体重")
                        .font(.caption)
                        .foregroundStyle(TrajectoryTheme.secondaryText)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(latestMetric?.value.formatted(.number.precision(.fractionLength(1))) ?? "--")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("kg")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(TrajectoryTheme.secondaryText)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Label(consistencyDescription, systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(TrajectoryTheme.primaryText)
                    ProgressView(value: consistencyProgress) {
                        Text("近 7 天记录 \(weeklyCheckIns)/7 天")
                            .font(.caption2)
                            .foregroundStyle(TrajectoryTheme.secondaryText)
                    }
                    .tint(Color(red: 0.43, green: 0.93, blue: 0.71))
                    .frame(maxWidth: 150)
                }
            }

            if let delta = weightDelta {
                HStack(spacing: 8) {
                    Image(systemName: delta >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.caption)
                        .foregroundStyle(delta >= 0 ? Color.orange : Color.green)
                    Text(deltaDescription(delta))
                        .font(.footnote)
                        .fontWeight(.medium)
                    Spacer()
                    Text(stageTag(for: delta))
                        .font(.caption2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(TrajectoryTheme.badgeFill)
                        .clipShape(Capsule())
                }
            } else {
                Text("添加第一条记录，解锁你的蜕变曲线。")
                    .font(.footnote)
                    .foregroundStyle(TrajectoryTheme.secondaryText)
            }

            if let workoutSummary = latestWorkoutSummary {
                TrajectoryWorkoutSummaryView(summary: workoutSummary, isCompact: false)
                    .padding(.top, 6)
            }
        }
        .padding(16)
        .background(TrajectoryTheme.primaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TrajectoryTheme.border)
        )
        .shadow(color: TrajectoryTheme.shadow.opacity(0.4), radius: 12, x: 0, y: 6)
    }

    private func deltaDescription(_ delta: Double) -> String {
        let symbol = delta >= 0 ? "+" : ""
        return "相较上次 \(symbol)\(String(format: "%.1f", delta)) kg"
    }

    private func stageTag(for delta: Double) -> String {
        if delta < -0.5 {
            return "减脂控碳"
        } else if delta > 0.5 {
            return "增肌加餐"
        } else {
            return "专注稳定"
        }
    }

    private var trendView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("最近 10 次波动")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(trendRangeLabel)
                    .font(.caption)
                    .foregroundStyle(TrajectoryTheme.tertiaryText)
            }

            Chart {
                ForEach(recentMetrics) { metric in
                    LineMark(
                        x: .value("Date", metric.date),
                        y: .value("Weight", metric.value)
                    )
                    .foregroundStyle(Color(red: 0.43, green: 0.93, blue: 0.71))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", metric.date),
                        y: .value("Weight", metric.value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                Color(red: 0.43, green: 0.93, blue: 0.71).opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text(String(format: "%.0f", weight))
                                .foregroundStyle(TrajectoryTheme.secondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(.dateTime.day()))
                                .foregroundStyle(TrajectoryTheme.secondaryText)
                        }
                    }
                }
            }
            .frame(height: 120)

            if let stats = trendStats {
                HStack {
                    trendStatColumn(label: "最低", value: stats.min)
                    Spacer()
                    trendStatColumn(label: "最高", value: stats.max)
                    Spacer()
                    if let delta = weightDelta {
                        trendStatColumn(label: "最新变化", value: delta, showSign: true)
                    }
                }
                .font(.caption)
                .foregroundStyle(TrajectoryTheme.primaryText)
            }
        }
        .padding(16)
        .background(TrajectoryTheme.secondaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func trendStatColumn(label: String, value: Double, showSign: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(TrajectoryTheme.tertiaryText)
            Text("\(showSign && value >= 0 ? "+" : "")\(String(format: "%.1f", value)) kg")
                .font(.callout)
                .fontWeight(.semibold)
        }
    }

    @ViewBuilder
    private var timelineSection: some View {
        if pages.isEmpty {
            emptyStateView
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("训练日记")
                        .font(.headline)
                    Spacer()
                    Text("向内复盘 向外蜕变")
                        .font(.caption)
                        .foregroundStyle(TrajectoryTheme.tertiaryText)
                }

                TabView(selection: pageSelection) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, pageData in
                        MonthlyPageView(
                            records: pageData.records,
                            workoutSummaryProvider: { workoutSummary(for: $0) }
                        )
                            .tag(index)
                    }
                }
                .frame(height: 220)
                .tabViewStyle(.page(indexDisplayMode: .never))

                PageIndicator(currentIndex: safeCurrentIndex, total: pages.count)
            }
        }
    }

    // MARK: - Bottom Controls (Range + Navigation)
    private struct LeftBadgesLabel: View {
        var body: some View {
            Label("Left Badges",
                systemImage: "chevron.left")
            .foregroundStyle(Color.black)
            .labelStyle(.iconOnly)
            .font(.system(size: 17))
            .fontWeight(.bold)
            .imageScale(.large)
        }
    }
    
    private struct RightBadgesLabel: View {
        var body: some View {
            Label("Right Badges",
                systemImage: "chevron.right")
            .foregroundStyle(Color.black)
            .labelStyle(.iconOnly)
            .font(.system(size: 17))
            .fontWeight(.bold)
            .imageScale(.large)
        }
    }
    
    private var bottomControls: some View {
        let canGoPrev = safeCurrentIndex + 1 < pages.count
        let canGoNext = safeCurrentIndex > 0
        return  GlassEffectContainer(spacing: 10) {
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Button {
                        withAnimation {
                            if canGoPrev { currentPageIndex += 1 }
                        }
                    } label: {
                        LeftBadgesLabel()
                    }
                    .frame(width: 48, height: 48)
                    .contentShape(Circle())
                    .glassEffect(.clear.interactive())
                    .clipShape(Circle())
                }
                .padding(.horizontal, 8)
                
                Picker("Range", selection: $selectedRange) {
                    ForEach(BodyProfileViewModel.TimeRange.allCases) { range in
                        Text(range.title).tag(range)
                        
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.extraLarge)
                .glassEffect(.clear.interactive())
                VStack(spacing: 4) {
                    Button {
                        withAnimation {
                            if canGoNext { currentPageIndex -= 1 }
                        }
                    } label: {
                        RightBadgesLabel()
                    }
                    .frame(width: 48, height: 48)
                    .contentShape(Circle())
                    .glassEffect(.clear.interactive())
                    .clipShape(Circle())
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "line.3.crossed.swirl.circle")
                .font(.largeTitle)
                .foregroundStyle(TrajectoryTheme.tertiaryText)
            Text("还没有蜕变脚印")
                .font(.headline)
            Text("记录第一次体重，让故事从此展开。")
                .font(.caption)
                .foregroundStyle(TrajectoryTheme.tertiaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding(16)
        .background(TrajectoryTheme.secondaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Monthly Page
struct MonthlyPageView: View {
    let records: [HealthMetric]
    let workoutSummaryProvider: (Date) -> WorkoutDaySummary?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(records.indices, id: \.self) { index in
                    let record = records[index]
                    let previousValue = index + 1 < records.count ? records[index + 1].value : nil
                    HistoryRowView(
                        record: record,
                        previousValue: previousValue,
                        workoutSummary: workoutSummaryProvider(record.date)
                    )
                }
            }
            .padding(.vertical, 6)
        }
        .padding(16)
        .background(TrajectoryTheme.frostedCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TrajectoryTheme.border)
        )
        .padding(.horizontal, 8)
    }
}

// MARK: - Single Entry Row
struct HistoryRowView: View {
    @EnvironmentObject var weightManager: WeightManager
    let record: HealthMetric
    let previousValue: Double?
    let workoutSummary: WorkoutDaySummary?
    @State private var isDeleteAlertPresented = false

    private var deltaText: (string: String, color: Color)? {
        guard let previousValue else { return nil }
        let delta = record.value - previousValue
        let color: Color = delta >= 0 ? .orange : .green
        let sign = delta >= 0 ? "+" : ""
        return ("\(sign)\(String(format: "%.1f", delta)) kg", color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.date.formatted(.dateTime.day().weekday(.wide)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(record.date.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(TrajectoryTheme.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(record.value.formatted(.number.precision(.fractionLength(1)))) kg")
                        .font(.title3)
                        .fontWeight(.semibold)
                    if let deltaText {
                        Text(deltaText.string)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(deltaText.color.opacity(0.15))
                            .foregroundStyle(deltaText.color)
                            .clipShape(Capsule())
                    }
                }
            }

                if let workoutSummary {
                    TrajectoryWorkoutSummaryView(summary: workoutSummary, isCompact: true)
                }
        }
        .padding(14)
        .background(TrajectoryTheme.primaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(TrajectoryTheme.border)
        )
        .contextMenu {
            Button(role: .destructive) {
                isDeleteAlertPresented = true
            } label: {
                Label("删除记录", systemImage: "trash")
            }
        }
        .alert("删除记录?", isPresented: $isDeleteAlertPresented) {
            Button("删除", role: .destructive) {
                weightManager.delete(record)
            }
            Button("取消", role: .cancel) {}
        }
    }
}

// MARK: - Supporting Views
private struct TrajectoryWorkoutSummaryView: View {
    let summary: WorkoutDaySummary
    let isCompact: Bool

    private var headlineText: String {
        let durationPart = summary.totalDurationInMinutes > 0
            ? "\(summary.totalDurationInMinutes)min"
            : "\(summary.workoutCount)次"
        return "\(durationPart) · \(summary.workoutCount)次 · \(summary.totalCalories)kcal"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 4 : 6) {
            HStack(alignment: .center, spacing: 8) {
                Label(summary.dominantType.displayName, systemImage: summary.dominantType.symbolName)
                    .font(isCompact ? .caption : .footnote)
                    .fontWeight(.semibold)
                    .padding(.horizontal, isCompact ? 10 : 12)
                    .padding(.vertical, 6)
                    .background(summary.dominantType.tintColor.opacity(0.18))
                    .foregroundStyle(summary.dominantType.tintColor)
                    .clipShape(Capsule())
                Spacer(minLength: 8)
                Text(headlineText)
                    .font(.caption2)
                    .foregroundStyle(TrajectoryTheme.secondaryText)
            }

            if !summary.highlightNames.isEmpty {
                Text(summary.highlightNames.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(TrajectoryTheme.tertiaryText)
                    .lineLimit(1)
            }
        }
    }
}

private struct PageIndicator: View {
    let currentIndex: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? TrajectoryTheme.indicatorActive : TrajectoryTheme.indicatorInactive)
                    .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

// MARK: - Data Helpers
struct WorkoutDaySummary {
    let date: Date
    let dominantType: WorkoutType
    let workoutCount: Int
    let totalDurationInMinutes: Int
    let totalCalories: Int
    let highlightNames: [String]
}

// MARK: - Date Extension for Grouping
extension Date {
    var startOfWeek: Date {
        let cal = Calendar.current
        if let interval = cal.dateInterval(of: .weekOfYear, for: self) {
            return cal.startOfDay(for: interval.start)
        }
        return startOfDay
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfQuarter: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: self)
        guard let year = comps.year, let month = comps.month else { return startOfMonth }
        let quarterStartMonth = ((month - 1) / 3) * 3 + 1 // 1,4,7,10
        let date = cal.date(from: DateComponents(year: year, month: quarterStartMonth, day: 1)) ?? self
        return date.startOfDay
    }

    var startOfYear: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year], from: self)
        let date = cal.date(from: DateComponents(year: comps.year, month: 1, day: 1)) ?? self
        return date.startOfDay
    }
}
