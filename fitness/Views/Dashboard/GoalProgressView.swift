//import SwiftUI
//import SwiftData
//
//struct GoalProgressView: View {
//    @Query(sort: \HealthMetric.date, order: .reverse) private var records: [HealthMetric]
//    @AppStorage("targetWeight") private var targetWeight: Double = 68.0
//
//    var body: some View {
//        HStack(spacing: 16) {
//            VStack(alignment: .leading, spacing: 8) {
//                Text("本周变化").font(.headline).foregroundStyle(.secondary)
//                Text(weekChangeText)
//                    .font(.system(size: 28, weight: .bold))
//                    .foregroundStyle(weekChangeValue > 0 ? .red : (weekChangeValue < 0 ? .green : .primary))
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//
//            VStack(alignment: .leading, spacing: 8) {
//                Text("目标进度").font(.headline).foregroundStyle(.secondary)
//                if let latest = records.first?.value {
//                    Text(String(format: "%.1f/%.1fkg", latest, targetWeight))
//                        .font(.system(size: 22, weight: .bold))
//                    ProgressView(value: latest, total: max(targetWeight, latest))
//                        .progressViewStyle(.linear)
//                        .tint(.orange)
//                } else {
//                    Text("--/\(String(format: "%.1f", targetWeight))kg")
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .padding()
//        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
//    }
//
//    private var weekChangeValue: Double {
//        guard records.count > 1 else { return 0 }
//        
//        let calendar = Calendar.current
//        let now = Date()
//        
//        // Find the most recent record
//        let latestRecord = records[0]
//        
//        // Find the date 7 days ago
//        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return 0 }
//        
//        // Find the closest record from on or before 7 days ago
//        let referenceRecord = records.first { $0.date <= sevenDaysAgo }
//        
//        guard let referenceWeight = referenceRecord?.value else { return 0 }
//        
//        return latestRecord.value - referenceWeight
//    }
//
//    private var weekChangeText: String {
//        let change = weekChangeValue
//        if change == 0 && records.count <= 1 {
//            return "-- kg"
//        }
//        return String(format: "%+.1fkg", change)
//    }
//}
