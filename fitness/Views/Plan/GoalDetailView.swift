import SwiftUI
import SwiftData
import Charts

struct GoalDetailView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    var body: some View {
        let userProfile = profileViewModel.userProfile
        
        let startWeight = weightMetrics.first?.value ?? weightMetrics.last?.value ?? 0
        let targetWeight = userProfile.targetWeight
        let currentWeight = weightMetrics.last?.value ?? 0
        
        let progress = (startWeight > 0 && startWeight != targetWeight) ? (startWeight - currentWeight) / (startWeight - targetWeight) : 0
        let chartData = Array(weightMetrics.suffix(30)) // Last 30 records for the chart

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                Text("目标详情")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                // Goal Summary Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "target")
                            .font(.title)
                            .foregroundColor(.accentColor)
                        Text("减重至 \(targetWeight, specifier: "%.1f") kg")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("从 \(startWeight, specifier: "%.1f") kg 开始，已完成 \(Int(progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)

                // Weight Trend Chart
                if !chartData.isEmpty {
                    VStack(alignment: .leading) {
                        Text("体重趋势")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        Chart(chartData) { record in
                            LineMark(
                                x: .value("日期", record.date),
                                y: .value("体重", record.value)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 200)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }

                // Action Plan
                VStack(alignment: .leading) {
                    Text("行动计划")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("每周锻炼5次，每次至少30分钟", systemImage: "figure.run")
                        Label("每日饮水2升", systemImage: "drop.fill")
                        Label("保持均衡饮食，减少高热量食物摄入", systemImage: "leaf.fill")
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("目标详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GoalDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)
        
        let sampleData = [
            HealthMetric(date: Date().addingTimeInterval(-86400*6), value: 70.5, type: .weight),
            HealthMetric(date: Date().addingTimeInterval(-86400*1), value: 69.9, type: .weight),
            HealthMetric(date: Date(), value: 69.5, type: .weight),
        ]
        sampleData.forEach { container.mainContext.insert($0) }

        return NavigationView {
            GoalDetailView()
                .modelContainer(container)
                .environmentObject(ProfileViewModel())
        }
    }
}