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
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeFrame.days, to: endDate)!
        return weightMetrics.filter { $0.date >= startDate && $0.date <= endDate }
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
                .foregroundStyle(by: .value("Date", rec.date.formatted(date: .abbreviated, time: .omitted)))
            }
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
