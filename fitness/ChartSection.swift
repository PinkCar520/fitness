import SwiftUI
#if canImport(Charts)
import Charts
#endif

struct ChartSection: View {
    @EnvironmentObject var weightManager: WeightManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight Trend").font(.title3).bold()
            #if canImport(Charts)
            Chart(weightManager.records) { rec in
                LineMark(
                    x: .value("Date", rec.date),
                    y: .value("Weight", rec.weight)
                )
            }
            .frame(height: 200)
            #else
            Text("Charts framework not available.")
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            #endif
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
