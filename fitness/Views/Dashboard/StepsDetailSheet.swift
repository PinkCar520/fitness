import SwiftUI
import Combine

struct StepsDetailSheet: View {
    enum Range: String, CaseIterable, Identifiable { case week = "周", month = "月", quarter = "季", year = "年"; var id: String { rawValue } }

    let stepCount: Int
    let weeklyData: [DailyStepData]
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel

    @State private var range: Range = .week

    // Placeholder datasets for month/quarter/year. Replace with real sources when available.
    private var monthData: [DailyStepData] {
        // Expand weekly data to 30 days by repeating/averaging as a placeholder
        if weeklyData.isEmpty { return [] }
        let base = weeklyData
        var out: [DailyStepData] = []
        for i in 0..<30 {
            let src = base[i % base.count]
            let date = Calendar.current.date(byAdding: .day, value: i - 29, to: Date()) ?? Date()
            out.append(DailyStepData(date: date, steps: src.steps))
        }
        return out
    }

    private var quarterData: [DailyStepData] {
        // 90 天占位
        synthesize(from: weeklyData, days: 90)
    }

    private var yearData: [DailyStepData] {
        // 365 天占位
        synthesize(from: weeklyData, days: 365)
    }

    private func synthesize(from seed: [DailyStepData], days: Int) -> [DailyStepData] {
        guard !seed.isEmpty else { return [] }
        var out: [DailyStepData] = []
        for i in 0..<days {
            let src = seed[i % seed.count]
            let date = Calendar.current.date(byAdding: .day, value: i - (days - 1), to: Date()) ?? Date()
            out.append(DailyStepData(date: date, steps: src.steps))
        }
        return out
    }

    private var dataForRange: [DailyStepData] {
        switch range {
        case .week:
            return weeklyData
        case .month:
            let raw = dashboardViewModel.monthlyStepData.isEmpty ? monthData : dashboardViewModel.monthlyStepData
            return groupStepsByWeeksInMonth(raw)
        case .quarter:
            let raw = dashboardViewModel.quarterStepData.isEmpty ? quarterData : dashboardViewModel.quarterStepData
            let monthly = groupStepsByMonth(raw)
            return ensureQuarterMonthsSteps(monthly)
        case .year:
            let raw = dashboardViewModel.yearStepData.isEmpty ? yearData : dashboardViewModel.yearStepData
            let monthly = groupStepsByMonth(raw)
            return ensureFullYearMonthsSteps(monthly)
        }
    }

    private var periodSummaryText: (total: String, average: String) {
        let data = dataForRange
        guard !data.isEmpty else { return ("总计 0 步", "日均/周均/月均 0") }
        let total = Int(data.map { $0.steps }.reduce(0, +))
        switch range {
        case .week:
            let avg = Int(Double(total) / Double(data.count))
            return ("总计 \(total) 步", "日均 \(avg) 步/天")
        case .month:
            let avg = Int(Double(total) / Double(data.count))
            return ("总计 \(total) 步", "周均 \(avg) 步/周")
        case .quarter, .year:
            let avg = Int(Double(total) / Double(data.count))
            return ("总计 \(total) 步", "月均 \(avg) 步/月")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            // Right-aligned today summary
            HStack {
                Spacer()
                Text("今日 \(stepCount) 步")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Period summary
            HStack {
                Text(periodSummaryText.total)
                    .font(.subheadline)
                Spacer()
                Text(periodSummaryText.average)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            chartWithLabels(dataForRange)
                .frame(height: 200)
                .overlay {
                    if dataForRange.isEmpty { Text("暂无数据").foregroundStyle(.secondary) }
                }
                // 切换范围时添加平滑动画
                .animation(.easeInOut(duration: 0.28), value: range)

            Spacer()

            // iOS 16+ segmented picker for range selection
            Picker("范围", selection: $range) {
                ForEach(Range.allCases) { r in
                    Text(r.rawValue).tag(r)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 12)
            .onChange(of: range) { newRange in
                Task { await loadIfNeeded(newRange) }
            }

            HStack {
                Spacer();
            HStack {
                Spacer()
                Text("数据来源：Apple健康")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        }
        .padding()
        .presentationDragIndicator(.visible)
        .task { await loadIfNeeded(range) }
    }
}

private extension StepsDetailSheet {
    @ViewBuilder
    func chartWithLabels(_ data: [DailyStepData]) -> some View {
        VStack(spacing: 6) {
            StepBarChart(data: data)
            HStack(spacing: 5) {
                let count = data.count
                if range == .quarter || range == .year {
                    ForEach(data) { d in
                        Text(shortLabel(for: d.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    let step: Int = {
                        if count <= 10 { return 1 }
                        if count <= 30 { return 3 }
                        return 7
                    }()
                    ForEach(0..<count, id: \.self) { idx in
                        let d = data[idx]
                        if idx % step == 0 || idx == count - 1 {
                            Text(shortLabel(for: d.date))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        } else {
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .frame(height: 16)

            // 统计卡片：显示最高/最低（所有范围均显示）
            weeklyStatCards(data)
        }
    }

    func shortLabel(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_CN")
        if range == .quarter || range == .year {
            // 显示“3月/4月”风格
            fmt.dateFormat = "M月"
        } else {
            fmt.dateFormat = "M/d"
        }
        return fmt.string(from: date)
    }
    func bucketSteps(_ data: [DailyStepData], daysPerBucket: Int) -> [DailyStepData] {
        guard !data.isEmpty, daysPerBucket > 1 else { return data }
        let sorted = data.sorted { $0.date < $1.date }
        var buckets: [DailyStepData] = []
        var i = 0
        while i < sorted.count {
            let end = min(i + daysPerBucket, sorted.count)
            let slice = sorted[i..<end]
            let sum = slice.map { $0.steps }.reduce(0, +)
            let date = slice.last?.date ?? Date()
            buckets.append(DailyStepData(date: date, steps: sum))
            i = end
        }
        return buckets
    }

    // 按自然月聚合
    func groupStepsByMonth(_ data: [DailyStepData]) -> [DailyStepData] {
        guard !data.isEmpty else { return [] }
        let cal = Calendar.current
        let grouped = Dictionary(grouping: data) { item -> Date in
            let comp = cal.dateComponents([.year, .month], from: item.date)
            return cal.date(from: comp) ?? item.date
        }
        let monthly = grouped.map { (monthStart, values) -> DailyStepData in
            let sum = values.map { $0.steps }.reduce(0, +)
            let endOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? monthStart
            return DailyStepData(date: endOfMonth, steps: sum)
        }
        return monthly.sorted { $0.date < $1.date }
    }

    // 选出当前季度三个月的数据
    func pickQuarterMonths(from monthly: [DailyStepData]) -> [DailyStepData] {
        guard !monthly.isEmpty else { return [] }
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let year = comps.year, let month = comps.month else { return [] }
        let q = (month - 1) / 3
        let startMonth = q * 3 + 1
        let set = Set([startMonth, startMonth + 1, startMonth + 2])
        return monthly.filter { item in
            let c = cal.dateComponents([.year, .month], from: item.date)
            return c.year == year && (c.month.map { set.contains($0) } ?? false)
        }
    }

    // 确保年范围恒为最近12个月（缺失补0）
    func ensureFullYearMonthsSteps(_ monthly: [DailyStepData]) -> [DailyStepData] {
        let cal = Calendar.current
        let now = Date()
        // 构造最近12个月的起始月（从当前月往前11个月）
        var months: [Date] = []
        if let currentMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) {
            for i in (0..<12).reversed() { // 升序
                if let m = cal.date(byAdding: .month, value: -i, to: currentMonthStart) {
                    months.append(m)
                }
            }
        }

        // 建立映射：year-month -> 步数总和
        var map: [String: Double] = [:]
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        for item in monthly {
            let key = fmt.string(from: cal.date(from: cal.dateComponents([.year, .month], from: item.date)) ?? item.date)
            map[key, default: 0] += item.steps
        }

        // 生成完整12个月序列，缺失补0，日期用该月末
        let result: [DailyStepData] = months.map { monthStart in
            let key = fmt.string(from: monthStart)
            let endOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? monthStart
            return DailyStepData(date: endOfMonth, steps: map[key] ?? 0)
        }
        return result
    }

    // 确保该季度 3 个月都存在（缺失补0）
    func ensureQuarterMonthsSteps(_ monthly: [DailyStepData]) -> [DailyStepData] {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let year = comps.year, let month = comps.month else { return [] }
        let q = (month - 1) / 3
        let startMonth = q * 3 + 1
        let months = [startMonth, startMonth + 1, startMonth + 2]

        // 建立 map
        var map: [Int: Double] = [:]
        for item in monthly {
            let c = cal.dateComponents([.year, .month], from: item.date)
            if c.year == year, let m = c.month { map[m, default: 0] += item.steps }
        }

        // 生成 3 根柱，缺失补0
        return months.compactMap { m in
            var comps = DateComponents(year: year, month: m)
            guard let monthStart = cal.date(from: comps) else { return nil }
            let endOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? monthStart
            return DailyStepData(date: endOfMonth, steps: map[m] ?? 0)
        }
    }

    // 将一个月内的数据按周聚合（每周一根柱）
    func groupStepsByWeeksInMonth(_ data: [DailyStepData]) -> [DailyStepData] {
        guard !data.isEmpty else { return [] }
        let cal = Calendar.current
        let sorted = data.sorted { $0.date < $1.date }
        var buckets: [DailyStepData] = []
        var currentWeekStart: Date? = nil
        var acc: Double = 0

        func startOfWeek(_ date: Date) -> Date {
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return cal.date(from: comps) ?? date
        }

        for item in sorted {
            let sow = startOfWeek(item.date)
            if let cw = currentWeekStart, cw == sow {
                acc += item.steps
            } else {
                if let cw = currentWeekStart {
                    buckets.append(DailyStepData(date: cw, steps: acc))
                }
                currentWeekStart = sow
                acc = item.steps
            }
        }
        if let cw = currentWeekStart {
            buckets.append(DailyStepData(date: cw, steps: acc))
        }
        return buckets
    }

    @ViewBuilder
    func weeklyStatCards(_ data: [DailyStepData]) -> some View {
        let maxItem = data.max(by: { $0.steps < $1.steps })
        let minItem = data.min(by: { $0.steps < $1.steps })

        HStack(spacing: 12) {
            statCard(title: "最高", value: maxItem.map { "\(Int($0.steps)) 步 (\(shortLabel(for: $0.date)))" } ?? "-")
            statCard(title: "最低", value: minItem.map { "\(Int($0.steps)) 步 (\(shortLabel(for: $0.date)))" } ?? "-")
        }
    }

    @ViewBuilder
    func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote)
                .fontWeight(.semibold)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    func loadIfNeeded(_ r: Range) async {
        switch r {
        case .week:
            await dashboardViewModel.loadStepsSeriesIfNeeded(.week)
        case .month:
            await dashboardViewModel.loadStepsSeriesIfNeeded(.month)
        case .quarter:
            await dashboardViewModel.loadStepsSeriesIfNeeded(.quarter)
        case .year:
            await dashboardViewModel.loadStepsSeriesIfNeeded(.year)
        }
    }
}
