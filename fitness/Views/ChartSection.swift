import SwiftUI
import SwiftData
#if canImport(Charts)
import Charts
#endif

struct ChartSection: View {
    var selectedTimeFrame: StatsView.TimeFrame
    var targetWeight: Double?
    
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]

    @State private var selectedMetric: HealthMetric? // Persisted via tap
    @State private var currentMetric: HealthMetric?  // Live while scrubbing
    @State private var isDragging: Bool = false

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter
    }()
    
    private func findClosestMetric(for date: Date) -> HealthMetric? {
        let calendar = Calendar.current
        return filteredMetrics.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    private var filteredMetrics: [HealthMetric] {
        let range = xAixsRange
        let metricsInRange = weightMetrics.filter { range.contains($0.date) }

        switch selectedTimeFrame {
        case .thirtyDays:
            let groupedByWeek = Dictionary(grouping: metricsInRange) { metric -> Date in
                let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: metric.date)
                return Calendar.current.date(from: components)!
            }

            let aggregatedMetrics = groupedByWeek.map { (weekStartDate, metricsInWeek) -> HealthMetric in
                let avgValue = metricsInWeek.map(\.value).reduce(0, +) / Double(metricsInWeek.count)
                return HealthMetric(date: weekStartDate, value: avgValue, type: .weight)
            }
            return aggregatedMetrics.sorted(by: { $0.date < $1.date })
        case .oneYear:
            let groupedByMonth = Dictionary(grouping: metricsInRange) { record in
                Calendar.current.dateComponents([.year, .month], from: record.date)
            }
            
            let aggregatedMetrics = groupedByMonth.compactMap { (components, records) -> HealthMetric? in
                guard let date = Calendar.current.date(from: components) else { return nil }
                let totalWeight = records.reduce(0) { $0 + $1.value }
                let averageWeight = totalWeight / Double(records.count)
                return HealthMetric(date: date, value: averageWeight, type: .weight)
            }
            return aggregatedMetrics.sorted(by: { $0.date < $1.date })

            
        default:
            return metricsInRange
        }
    }

    private var chartUnit: Calendar.Component {
        switch selectedTimeFrame {
        case .oneYear:
            return .month
        default:
            return .day
        }
    }

    private var minMetric: HealthMetric? {
        filteredMetrics.min(by: { $0.value < $1.value })
    }

    private var maxMetric: HealthMetric? {
        filteredMetrics.max(by: { $0.value < $1.value })
    }

    private var dateRangeString: String {
        let range = xAixsRange
        let start = range.lowerBound
        let end = range.upperBound

        let yearFormatter = DateFormatter()
        yearFormatter.locale = Locale(identifier: "zh_CN")
        yearFormatter.dateFormat = "yyyy年"

        let monthDayFormatter = DateFormatter()
        monthDayFormatter.locale = Locale(identifier: "zh_CN")
        monthDayFormatter.dateFormat = "M月d日"

        let fullFormatter = DateFormatter()
        fullFormatter.locale = Locale(identifier: "zh_CN")
        fullFormatter.dateFormat = "yyyy年M月d日"

        if Calendar.current.isDate(start, equalTo: end, toGranularity: .year) {
            return "\(yearFormatter.string(from: start))\(monthDayFormatter.string(from: start))至\(monthDayFormatter.string(from: end))"
        } else {
            return "\(fullFormatter.string(from: start))至\(fullFormatter.string(from: end))"
        }
    }

    private func pointColor(for rec: HealthMetric) -> Color {
        if rec == minMetric {
            return .orange
        }
        if rec == maxMetric {
            return .red
        }
        return .blue
    }

    private func annotationAlignment(for date: Date) -> Alignment {
        let range = xAixsRange
        let totalDuration = range.upperBound.timeIntervalSince(range.lowerBound)
        
        guard totalDuration > 0 else { return .center }

        let selectedDuration = date.timeIntervalSince(range.lowerBound)
        let position = selectedDuration / totalDuration

        if position < 0.2 {
            return .leading
        } else if position > 0.8 {
            return .trailing
        } else {
            return .center
        }
    }

    private var yAxisStride: Double {
        switch selectedTimeFrame {
        case .sevenDays, .thirtyDays:
            return 0.5
        case .threeMonths, .halfYear, .oneYear:
            return 2.0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("体重趋势").font(.title3).bold()

            HStack {
                Text(dateRangeString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.bottom, 8)

            #if canImport(Charts)
            Chart {
                ForEach(filteredMetrics) { rec in
                    LineMark(
                        x: .value("Date", rec.date, unit: chartUnit),
                        y: .value("Weight", rec.value)
                    )
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("Date", rec.date, unit: chartUnit),
                        y: .value("Weight", rec.value)
                    )
                    .foregroundStyle(pointColor(for: rec))
                    .opacity(rec == (currentMetric ?? selectedMetric) || rec == minMetric || rec == maxMetric ? 1.0 : 0.0)
                    .annotation(position: .bottom, alignment: .center) {
                        if rec == minMetric {
                            Text(String(format: "最低: %.1f", rec.value))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(4)
                                .background(in: RoundedRectangle(cornerRadius: 4))
                                .backgroundStyle(Color.white.opacity(0.8))
                        }
                    }
                    .annotation(position: .top, alignment: .center) {
                        if rec == maxMetric {
                            Text(String(format: "最高: %.1f", rec.value))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(4)
                                .background(in: RoundedRectangle(cornerRadius: 4))
                                .backgroundStyle(Color.white.opacity(0.8))
                        }
                    }
                }
                
                let metricToShow = currentMetric ?? selectedMetric
                if let metricToShow {
                    RuleMark(x: .value("Selected", metricToShow.date, unit: chartUnit))
                        .foregroundStyle(Color.gray.opacity(0.2))
                        .annotation(position: .top, alignment: annotationAlignment(for: metricToShow.date)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(metricToShow.date, formatter: Self.dateFormatter)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f kg", metricToShow.value))
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                            )
                        }
                }

                if let targetWeight {
                    RuleMark(y: .value("目标", targetWeight))
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("目标")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 4)
                                .background(Color.white.opacity(0.5))
                        }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    if abs(value.translation.width) > 10 {
                                        isDragging = true
                                    }
                                    
                                    if let date: Date = proxy.value(atX: location.x),
                                       let closestMetric = findClosestMetric(for: date) {
                                        self.currentMetric = closestMetric
                                    }
                                }
                                .onEnded { value in
                                    if isDragging {
                                        // Drag ended, clear live metric
                                        self.currentMetric = nil
                                    } else {
                                        // Tap ended
                                        if selectedMetric == currentMetric {
                                            selectedMetric = nil
                                        } else {
                                            selectedMetric = currentMetric
                                        }
                                        self.currentMetric = nil
                                    }
                                    // Reset drag state
                                    isDragging = false
                                }
                        )
                }
            }
            .chartXAxis {
                switch selectedTimeFrame {
                case .sevenDays:
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(formatChineseWeekday(date))
                        }
                    }
                case .thirtyDays:
                    AxisMarks(values: .stride(by: .weekOfYear)) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(self.formatChineseDate(date))
                        }
                    }
                case .threeMonths, .halfYear, .oneYear:
                    AxisMarks(values: .stride(by: .month)) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(formatChineseMonth(date))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: yAxisStride))
            }
            .chartXScale(domain: xAixsRange)
            .chartLegend(.hidden)
            .chartYScale(domain: yAxisDomain)
            .frame(height: 200)
            #else
            Text("Charts framework not available.")
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            #endif
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func formatChineseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func formatChineseWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func formatChineseMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }



    private var yAxisDomain: ClosedRange<Double> {
        let (base, padding): (Double, Double)
        switch selectedTimeFrame {
        case .sevenDays, .thirtyDays:
            (base, padding) = (0.5, 0.5)
        case .threeMonths, .halfYear, .oneYear:
            (base, padding) = (2.0, 2.0)
        }

        let recordsToConsider = filteredMetrics.isEmpty ? weightMetrics : filteredMetrics
        guard !recordsToConsider.isEmpty else {
            return 60...75 // Default range if no records
        }

        let minWeight = recordsToConsider.min(by: { $0.value < $1.value })?.value ?? 60
        let maxWeight = recordsToConsider.max(by: { $0.value < $1.value })?.value ?? 75

        let lowerBound = floor(minWeight / base) * base - padding
        let upperBound = ceil(maxWeight / base) * base + padding

        return lowerBound...upperBound
    }

    private var xAixsRange: ClosedRange<Date> {
        let now = Date()
        let startDate: Date
        
        switch selectedTimeFrame {
        case .sevenDays:
            startDate = now.startOfWeek()
            let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startDate)!
            let endDate = Calendar.current.date(byAdding: .second, value: -1, to: nextWeek)!
            return startDate...endDate
        default:
            startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeFrame.days, to: now)!
            return startDate...now
        }
    }
}

// Updated Preview to support SwiftData
struct ChartSection_Previews: PreviewProvider {
    static var previews: some View {
        // Create an in-memory container for the preview
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)
        
        // Add sample data
        let sampleData = [
            HealthMetric(date: Date().addingTimeInterval(-86400*6), value: 70.5, type: .weight),
            HealthMetric(date: Date().addingTimeInterval(-86400*5), value: 70.2, type: .weight),
            HealthMetric(date: Date().addingTimeInterval(-86400*4), value: 70.8, type: .weight),
            HealthMetric(date: Date().addingTimeInterval(-86400*3), value: 70.1, type: .weight),
            HealthMetric(date: Date().addingTimeInterval(-86400*2), value: 69.8, type: .weight),
            HealthMetric(date: Date().addingTimeInterval(-86400*1), value: 69.9, type: .weight),
            HealthMetric(date: Date(), value: 69.5, type: .weight),
        ]
        sampleData.forEach { container.mainContext.insert($0) }

        return ChartSection(selectedTimeFrame: .sevenDays)
            .modelContainer(container)
    }
}