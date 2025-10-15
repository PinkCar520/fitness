import SwiftUI
import Charts

// A generic data point structure for the chart
struct DateValuePoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct GenericLineChartView: View {
    let title: String
    let data: [DateValuePoint]
    let color: Color
    let unit: String

    @State private var selectedPoint: DateValuePoint? // For tap gesture
    @State private var currentPoint: DateValuePoint?  // For drag gesture

    private var yAxisDomain: ClosedRange<Double> {
        let values = data.map { $0.value }
        guard let min = values.min(), let max = values.max() else {
            return 0...100 // Default range
        }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title3).bold()
                .padding(.horizontal)

            if data.isEmpty {
                VStack {
                    Spacer()
                    Text("暂无数据")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(color)

                        if let currentPoint = self.currentPoint, currentPoint.id == point.id {
                            PointMark(
                                x: .value("Date", currentPoint.date),
                                y: .value("Value", currentPoint.value)
                            )
                            .foregroundStyle(color.brighter())
                        }
                    }
                    
                    // RuleMark for drag/tap interaction
                    if let currentPoint = self.currentPoint {
                        RuleMark(x: .value("Selected", currentPoint.date))
                            .foregroundStyle(Color.gray.opacity(0.3))
                            .annotation(position: .top, alignment: .center) {
                                annotationView(for: currentPoint)
                            }
                    }
                }
                .chartYScale(domain: yAxisDomain)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let location = value.location
                                        if let date: Date = proxy.value(atX: location.x) {
                                            // Find the closest data point to the drag location
                                            let closestPoint = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
                                            if self.currentPoint?.id != closestPoint?.id {
                                                self.currentPoint = closestPoint
                                            }
                                        }
                                    }
                                    .onEnded { value in
                                        self.currentPoint = nil // Hide annotation on drag end
                                    }
                            )
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func annotationView(for point: DateValuePoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(point.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(point.value, specifier: "%.1f") \(unit)")
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.background)
                .shadow(radius: 3)
        )
    }
}

extension Color {
    func brighter(by percentage: Double = 30.0) -> Color {
        // This is a simplified implementation. A real implementation would use UIColor or NSColor.
        return self // Placeholder
    }
}
