
import SwiftUI

struct CurrentCardView: View {
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Binding var showInputSheet: Bool
    @State private var showingBodyMetricsSheet = false

    var body: some View {
        Button(action: {
            showingBodyMetricsSheet = true
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("最新体重")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: { showInputSheet = true }) {
                        Image(systemName: "plus")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue.gradient)
                            .clipShape(Circle())
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(latestWeightValue)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("公斤")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(weeklyChange.change)
                            .font(.headline)
                            .foregroundStyle(weeklyChange.color)
                        
                        Text(weeklyChange.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 4)
                }

                Text(latestDateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(PlainButtonStyle()) // To remove default button styling
        .sheet(isPresented: $showingBodyMetricsSheet) {
            BodyMetricsView()
        }
    }

    private var latestWeightSource: (weight: Double, date: Date)? {
        if let sample = healthKitManager.lastWeightSample {
            return (weight: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)), date: sample.endDate)
        }
        if let record = weightManager.latestRecord {
            return (weight: record.weight, date: record.date)
        }
        return nil
    }

    private var latestWeightValue: String {
        if let source = latestWeightSource {
            return String(format: "%.1f", source.weight)
        }
        return "--"
    }

    private var latestDateText: String {
        if let source = latestWeightSource {
            return source.date.yyyyMMddHHmm
        }
        return "暂无记录"
    }

    private var weeklyChange: (change: String, color: Color, description: String) {
        // 1. Get all records, sorted newest first
        let records = weightManager.records.sorted(by: { $0.date > $1.date })
        
        // 2. Get the latest record
        guard let latestRecord = records.first else {
            return ("--", .primary, "") // No records, no change, no description
        }

        // 3. Define the target date for comparison: 7 days before the latest record's date
        let targetDate = Calendar.current.date(byAdding: .day, value: -7, to: latestRecord.date)!

        // 4. Find the "base" record. This is the record with the date closest to our targetDate.
        // We should exclude the latestRecord itself from the search.
        let otherRecords = records.dropFirst()
        
        // Find the record with the minimum time difference from the target date.
        var closestRecord: WeightRecord? = nil
        var smallestTimeDifference = Double.greatestFiniteMagnitude

        for record in otherRecords {
            let timeDifference = abs(record.date.timeIntervalSince(targetDate))
            if timeDifference < smallestTimeDifference {
                smallestTimeDifference = timeDifference
                closestRecord = record
            }
        }

        // 5. Now we have the 'closestRecord'. Let's calculate the change and description.
        guard let baseRecord = closestRecord else {
            // If no other record exists to compare with.
            return ("--", .primary, "无历史数据对比") 
        }

        let change = latestRecord.weight - baseRecord.weight
        
        // 6. Calculate the number of days between latestRecord and baseRecord for the description.
        let dayDifference = Calendar.current.dateComponents([.day], from: baseRecord.date, to: latestRecord.date).day ?? 0

        let description: String
        if dayDifference <= 1 {
            description = "对比昨天"
        } else {
            description = "对比\(dayDifference)天前"
        }
        
        // 7. Format the output string and color
        if change > 0 {
            return (String(format: "+%.1f kg", change), .red, description)
        } else if change < 0 {
            return (String(format: "%.1f kg", change), .green, description)
        } else {
            return ("0.0 kg", .primary, description)
        }
    }
}
