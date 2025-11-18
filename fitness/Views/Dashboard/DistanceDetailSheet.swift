import SwiftUI

struct DistanceDetailSheet: View {
    enum Range: String, CaseIterable, Identifiable { case week = "周", month = "月", quarter = "季", year = "年"; var id: String { rawValue } }

    let distanceKM: Double
    let weeklyData: [DailyDistanceData]
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel

    @State private var range: Range = .week

    // MARK: - Range navigation helpers
    private var orderedRanges: [Range] { Range.allCases }
    private var currentIndex: Int { orderedRanges.firstIndex(of: range) ?? 0 }
    private var canGoLeft: Bool { currentIndex > 0 }
    private var canGoRight: Bool { currentIndex < orderedRanges.count - 1 }
    private func prevRange() -> Range { orderedRanges[max(0, currentIndex - 1)] }
    private func nextRange() -> Range { orderedRanges[min(orderedRanges.count - 1, currentIndex + 1)] }

    private var monthData: [DailyDistanceData] { synthesize(from: weeklyData, days: 30) }
    private var quarterData: [DailyDistanceData] { synthesize(from: weeklyData, days: 90) }
    private var yearData: [DailyDistanceData] { synthesize(from: weeklyData, days: 365) }

    private func synthesize(from seed: [DailyDistanceData], days: Int) -> [DailyDistanceData] {
        guard !seed.isEmpty else { return [] }
        var out: [DailyDistanceData] = []
        for i in 0..<days {
            let src = seed[i % seed.count]
            let date = Calendar.current.date(byAdding: .day, value: i - (days - 1), to: Date()) ?? Date()
            out.append(DailyDistanceData(date: date, distance: src.distance))
        }
        return out
    }

    private var dataForRange: [DailyDistanceData] {
        switch range {
        case .week:
            return weeklyData
        case .month:
            let raw = dashboardViewModel.monthlyDistanceData.isEmpty ? monthData : dashboardViewModel.monthlyDistanceData
            return groupDistanceByWeeksInMonth(raw)
        case .quarter:
            let raw = dashboardViewModel.quarterDistanceData.isEmpty ? quarterData : dashboardViewModel.quarterDistanceData
            let monthly = groupDistanceByMonth(raw)
            return ensureQuarterMonthsDistance(monthly)
        case .year:
            let raw = dashboardViewModel.yearDistanceData.isEmpty ? yearData : dashboardViewModel.yearDistanceData
            let monthly = groupDistanceByMonth(raw)
            return ensureFullYearMonthsDistance(monthly)
        }
    }

    private var periodSummaryText: (total: String, average: String) {
        let data = dataForRange
        guard !data.isEmpty else { return ("总计 0.00 km", "日均/周均/月均 0.00") }
        let totalKM = data.map { $0.distance }.reduce(0, +) / 1000
        switch range {
        case .week:
            let avg = totalKM / Double(data.count)
            return (String(format: "总计 %.2f km", totalKM), String(format: "日均 %.2f km/天", avg))
        case .month:
            let avg = totalKM / Double(data.count)
            return (String(format: "总计 %.2f km", totalKM), String(format: "周均 %.2f km/周", avg))
        case .quarter, .year:
            let avg = totalKM / Double(data.count)
            return (String(format: "总计 %.2f km", totalKM), String(format: "月均 %.2f km/月", avg))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            // Right-aligned today summary
            HStack { Spacer(); Text(String(format: "今日 %.2f km", distanceKM)).font(.subheadline).foregroundStyle(.secondary) }

            // Period summary
            HStack {
                Text(periodSummaryText.total).font(.subheadline)
                Spacer()
                Text(periodSummaryText.average).font(.subheadline).foregroundStyle(.secondary)
            }

            chartWithLabels(dataForRange)
                .frame(height: 200)
                .overlay {
                    if dataForRange.isEmpty { Text("暂无数据").foregroundStyle(.secondary) }
                }
                // 切换范围时添加平滑动画
                .animation(.easeInOut(duration: 0.28), value: range)

            Spacer()

            HStack(spacing: 12) {
                // 左按钮（向前切换范围）
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        if canGoLeft { range = prevRange() }
                    }
                } label: {
                    DistanceLeftButtonLabel()
                        .frame(width: 24, height: 32)
                }
                .buttonStyle(.glass)
                .disabled(!canGoLeft)
                // 范围选择器
                Picker("范围", selection: $range) {
                    ForEach(Range.allCases) { r in Text(r.rawValue).tag(r) }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .glassEffect(.regular,in: .rect(cornerRadius: 24.0))
                .onChange(of: range) { _, newRange in
                    Task { await loadIfNeeded(newRange) }
                }

                // 右按钮（向后切换范围）
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        if canGoRight { range = nextRange() }
                    }
                } label: {
                    DistanceRightButtonLabel()
                        .frame(width: 24, height: 32)
                }
                .buttonStyle(.glass)
                .disabled(!canGoRight)
            }

            HStack { Spacer(); Text("数据来源：Apple健康").font(.footnote).foregroundStyle(.secondary) }
        }
        .padding()
        .presentationDragIndicator(.visible)
        .task { await loadIfNeeded(range) }
    }
}

private struct DistanceLeftButtonLabel: View {
    var body: some View {
        Label("Left", systemImage: "chevron.left")
            .foregroundStyle(Color.black)
            .labelStyle(.iconOnly)
            .font(.system(size: 17))
            .fontWeight(.bold)
            .imageScale(.large)
    }
}

private struct DistanceRightButtonLabel: View {
    var body: some View {
        Label("Right", systemImage: "chevron.right")
            .foregroundStyle(Color.black)
            .labelStyle(.iconOnly)
            .font(.system(size: 17))
            .fontWeight(.bold)
            .imageScale(.large)
    }
}

private extension DistanceDetailSheet {
    func shortLabel(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_CN")
        if range == .quarter || range == .year {
            fmt.dateFormat = "M月"
        } else {
            fmt.dateFormat = "M/d"
        }
        return fmt.string(from: date)
    }
    @ViewBuilder
    func chartWithLabels(_ data: [DailyDistanceData]) -> some View {
        VStack(spacing: 6) {
            DistanceBarChart(data: data)
            HStack(spacing: 5) {
                let count = data.count
                if range == .year {
                    ForEach(data) { d in
                        Text(shortLabel(for: d.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                } else if range == .quarter {
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
            .frame(height: 18)

            // 统计卡片：显示最高/最低（所有范围均显示）
            weeklyStatCards(data)
        }
    }

    func bucketDistance(_ data: [DailyDistanceData], daysPerBucket: Int) -> [DailyDistanceData] {
        guard !data.isEmpty, daysPerBucket > 1 else { return data }
        let sorted = data.sorted { $0.date < $1.date }
        var buckets: [DailyDistanceData] = []
        var i = 0
        while i < sorted.count {
            let end = min(i + daysPerBucket, sorted.count)
            let slice = sorted[i..<end]
            let sum = slice.map { $0.distance }.reduce(0, +)
            let date = slice.last?.date ?? Date()
            buckets.append(DailyDistanceData(date: date, distance: sum))
            i = end
        }
        return buckets
    }
    // 按自然月聚合
    func groupDistanceByMonth(_ data: [DailyDistanceData]) -> [DailyDistanceData] {
        guard !data.isEmpty else { return [] }
        let cal = Calendar.current
        let grouped = Dictionary(grouping: data) { item -> Date in
            let comp = cal.dateComponents([.year, .month], from: item.date)
            return cal.date(from: comp) ?? item.date
        }
        let monthly = grouped.map { (monthStart, values) -> DailyDistanceData in
            let sum = values.map { $0.distance }.reduce(0, +)
            let endOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? monthStart
            return DailyDistanceData(date: endOfMonth, distance: sum)
        }
        return monthly.sorted { $0.date < $1.date }
    }

    func pickQuarterMonths(from monthly: [DailyDistanceData]) -> [DailyDistanceData] {
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

    // 将最近三个月（含本月）的数据聚合成 3 根柱，缺失补0
    func ensureQuarterMonthsDistance(_ monthly: [DailyDistanceData]) -> [DailyDistanceData] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"

        guard let currentMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date())) else { return [] }

        let monthStarts: [Date] = (0..<3)
            .compactMap { cal.date(byAdding: .month, value: -$0, to: currentMonthStart) }
            .sorted()

        var map: [String: Double] = [:]
        for item in monthly {
            let key = fmt.string(from: cal.date(from: cal.dateComponents([.year, .month], from: item.date)) ?? item.date)
            map[key, default: 0] += item.distance
        }

        return monthStarts.compactMap { start in
            let key = fmt.string(from: start)
            let endOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
            return DailyDistanceData(date: endOfMonth, distance: map[key] ?? 0)
        }
    }

    // 将一个月内的数据按周聚合（每周一根柱）
    func groupDistanceByWeeksInMonth(_ data: [DailyDistanceData]) -> [DailyDistanceData] {
        guard !data.isEmpty else { return [] }
        let cal = Calendar.current
        let sorted = data.sorted { $0.date < $1.date }
        var buckets: [DailyDistanceData] = []
        var currentWeekStart: Date? = nil
        var acc: Double = 0

        func startOfWeek(_ date: Date) -> Date {
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return cal.date(from: comps) ?? date
        }

        for item in sorted {
            let sow = startOfWeek(item.date)
            if let cw = currentWeekStart, cw == sow {
                acc += item.distance
            } else {
                if let cw = currentWeekStart {
                    buckets.append(DailyDistanceData(date: cw, distance: acc))
                }
                currentWeekStart = sow
                acc = item.distance
            }
        }
        if let cw = currentWeekStart {
            buckets.append(DailyDistanceData(date: cw, distance: acc))
        }
        return buckets
    }

    // 确保年范围恒为最近12个月（缺失补0）
    func ensureFullYearMonthsDistance(_ monthly: [DailyDistanceData]) -> [DailyDistanceData] {
        let cal = Calendar.current
        let now = Date()
        // 构造最近12个月的起始月（从当前月往前11个月）
        var months: [Date] = []
        for i in (0..<12).reversed() { // 升序
            if let m = cal.date(byAdding: .month, value: -i, to: cal.date(from: cal.dateComponents([.year, .month], from: now))!) {
                months.append(m)
            }
        }

        // 建立映射：year-month -> 距离总和
        var map: [String: Double] = [:]
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        for item in monthly {
            let key = fmt.string(from: cal.date(from: cal.dateComponents([.year, .month], from: item.date)) ?? item.date)
            map[key, default: 0] += item.distance
        }

        // 生成完整12个月序列，缺失补0，日期用该月末
        let result: [DailyDistanceData] = months.map { monthStart in
            let key = fmt.string(from: monthStart)
            let endOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? monthStart
            return DailyDistanceData(date: endOfMonth, distance: map[key] ?? 0)
        }
        return result
    }

    @ViewBuilder
    func weeklyStatCards(_ data: [DailyDistanceData]) -> some View {
        let maxItem = data.max(by: { $0.distance < $1.distance })
        let minItem = data.min(by: { $0.distance < $1.distance })

        HStack(spacing: 12) {
            statCard(title: "最高", value: maxItem.map { String(format: "%.2f km (%@)", $0.distance/1000, shortLabel(for: $0.date)) } ?? "-")
            statCard(title: "最低", value: minItem.map { String(format: "%.2f km (%@)", $0.distance/1000, shortLabel(for: $0.date)) } ?? "-")
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
            await dashboardViewModel.loadDistanceSeriesIfNeeded(.week)
        case .month:
            await dashboardViewModel.loadDistanceSeriesIfNeeded(.month)
        case .quarter:
            await dashboardViewModel.loadDistanceSeriesIfNeeded(.quarter)
        case .year:
            await dashboardViewModel.loadDistanceSeriesIfNeeded(.year)
        }
    }
}
