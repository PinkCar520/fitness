import SwiftUI
#if canImport(Charts)
import Charts
#endif

struct ChartSection: View {
    @EnvironmentObject var weightManager: WeightManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("体重趋势").font(.title3).bold()
            #if canImport(Charts)
            Chart(weightManager.records.suffix(7)) { rec in
                LineMark(
                    x: .value("Date", rec.date, unit: .day),
                    y: .value("Weight", rec.weight)
                )
                PointMark(
                    x: .value("Date", rec.date, unit: .day),
                    y: .value("Weight", rec.weight)
                )
                .foregroundStyle(by: .value("Date", rec.date.formatted(date: .abbreviated, time: .omitted)))
            }
            .chartLegend(.hidden)
//            .chartXAxis(.hidden)
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
        guard let latestWeight = weightManager.records.last?.weight else {
            return 60...75 // Default range if no records
        }

        let lowerBound = floor(latestWeight / 10) * 10
        let upperBound = lowerBound + 15

        return lowerBound...upperBound
    }
}
