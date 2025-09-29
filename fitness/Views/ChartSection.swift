import SwiftUI
import SwiftData
#if canImport(Charts)
import Charts
#endif

struct ChartSection: View {
    var selectedTimeFrame: StatsView.TimeFrame
    
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    private var filteredMetrics: [HealthMetric] {
        if selectedTimeFrame == .thirtyDays {
            // Special logic for month view
            let range = xAixsRange
            let allMetricsInRange = weightMetrics.filter { range.contains($0.date) }
            
            let start = range.lowerBound
            let mid1 = Calendar.current.date(byAdding: .day, value: 10, to: start)!
            let mid2 = Calendar.current.date(byAdding: .day, value: 20, to: start)!
            
            let earlyMetrics = allMetricsInRange.filter { $0.date < mid1 }
            let midMetrics = allMetricsInRange.filter { $0.date >= mid1 && $0.date < mid2 }
            let lateMetrics = allMetricsInRange.filter { $0.date >= mid2 }
            
            var aggregatedMetrics: [HealthMetric] = []
            
            if !earlyMetrics.isEmpty {
                let avgValue = earlyMetrics.map(\.value).reduce(0, +) / Double(earlyMetrics.count)
                let avgDate = Calendar.current.date(byAdding: .day, value: 5, to: start)!
                aggregatedMetrics.append(HealthMetric(date: avgDate, value: avgValue, type: .weight))
            }
            
            if !midMetrics.isEmpty {
                let avgValue = midMetrics.map(\.value).reduce(0, +) / Double(midMetrics.count)
                let avgDate = Calendar.current.date(byAdding: .day, value: 15, to: start)!
                aggregatedMetrics.append(HealthMetric(date: avgDate, value: avgValue, type: .weight))
            }
            
            if !lateMetrics.isEmpty {
                let avgValue = lateMetrics.map(\.value).reduce(0, +) / Double(lateMetrics.count)
                let avgDate = Calendar.current.date(byAdding: .day, value: 25, to: start)!
                aggregatedMetrics.append(HealthMetric(date: avgDate, value: avgValue, type: .weight))
            }
            
            return aggregatedMetrics
            
        } else {
            let range = xAixsRange
            return weightMetrics.filter { range.contains($0.date) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("体重趋势").font(.title3).bold()
            #if canImport(Charts)
            Chart(filteredMetrics) { rec in
                LineMark(
                    x: .value("Date", rec.date, unit: .day),
                    y: .value("Weight", rec.value)
                )
                PointMark(
                    x: .value("Date", rec.date, unit: .day),
                    y: .value("Weight", rec.value)
                )
                .foregroundStyle(by: .value("Date", formatChineseDate(rec.date)))
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
                    let now = Date()
                    let start = Calendar.current.date(byAdding: .day, value: -29, to: now)!
                    let positions = [
                        Calendar.current.date(byAdding: .day, value: 5, to: start)!,
                        Calendar.current.date(byAdding: .day, value: 15, to: start)!,
                        Calendar.current.date(byAdding: .day, value: 25, to: start)!
                    ]
                    let labels = ["上旬", "中旬", "下旬"]
                    AxisMarks(values: positions) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisTick()
                            if let index = positions.firstIndex(of: date) {
                                AxisValueLabel(labels[index])
                            }
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
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }



    private var yAxisDomain: ClosedRange<Double> {
        let recordsToConsider = filteredMetrics.isEmpty ? weightMetrics : filteredMetrics
        guard !recordsToConsider.isEmpty else {
            return 60...75 // Default range if no records
        }

        let minWeight = recordsToConsider.min(by: { $0.value < $1.value })?.value ?? 60
        let maxWeight = recordsToConsider.max(by: { $0.value < $1.value })?.value ?? 75

        let lowerBound = floor(minWeight / 5) * 5 - 5
        let upperBound = ceil(maxWeight / 5) * 5 + 5

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
