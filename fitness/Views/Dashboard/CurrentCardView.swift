import SwiftUI
import SwiftData

struct CurrentCardView: View {
    @EnvironmentObject var weightManager: WeightManager // Still needed for the 'add' action via showInputSheet
    @Binding var showInputSheet: Bool
    @State private var showingBodyMetricsSheet = false

    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    var body: some View {
        Button(action: {
            showingBodyMetricsSheet = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(latestWeightValue)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            Text("公斤")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(latestDateText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Button(action: { showInputSheet = true }) {
                            Image(systemName: "plus")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue.gradient)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(weeklyChange.change)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(weeklyChange.color)
                            
                            Text(weeklyChange.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle()) // To remove default button styling
        .sheet(isPresented: $showingBodyMetricsSheet) {
            BodyMetricsView()
        }
    }

    private var latestWeightValue: String {
        if let record = weightMetrics.last {
            return String(format: "%.1f", record.value)
        }
        return "--"
    }

    private var latestDateText: String {
        if let record = weightMetrics.last {
            return record.date.yyyyMMddHHmm
        }
        return "暂无记录"
    }

    private var weeklyChange: (change: String, color: Color, description: String) {
        let records = weightMetrics // Use the new SwiftData-backed array
        
        guard let latestRecord = records.last else {
            return ("--", .primary, "")
        }

        let targetDate = Calendar.current.date(byAdding: .day, value: -7, to: latestRecord.date)!
        let otherRecords = records.dropLast()
        
        var closestRecord: HealthMetric? = nil
        var smallestTimeDifference = Double.greatestFiniteMagnitude

        for record in otherRecords {
            let timeDifference = abs(record.date.timeIntervalSince(targetDate))
            if timeDifference < smallestTimeDifference {
                smallestTimeDifference = timeDifference
                closestRecord = record
            }
        }

        guard let baseRecord = closestRecord else {
            return ("--", .primary, "无历史数据对比")
        }

        let change = latestRecord.value - baseRecord.value
        
        let dayDifference = Calendar.current.dateComponents([.day], from: baseRecord.date, to: latestRecord.date).day ?? 0

        let description: String
        if dayDifference <= 1 {
            description = "对比昨天"
        } else {
            description = "对比\(dayDifference)天前"
        }
        
        if change > 0 {
            return (String(format: "+%.1f kg", change), .red, description)
        } else if change < 0 {
            return (String(format: "%.1f kg", change), .green, description)
        } else {
            return ("0.0 kg", .primary, description)
        }
    }
}