import SwiftUI
import Charts

struct HealthDataDetailView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    let dataType: HealthDataType

    var body: some View {
        VStack {
            if dataType == .steps {
                Text("步数历史趋势")
                    .font(.title2)
                    .padding(.bottom, 5)
                
                if healthKitManager.weeklyStepData.isEmpty {
                    Text("暂无步数数据")
                        .foregroundStyle(.secondary)
                } else {
                    Chart {
                        ForEach(healthKitManager.weeklyStepData) { data in
                            BarMark(x: .value("日期", data.date, unit: .day),
                                    y: .value("步数", data.steps))
                            .foregroundStyle(.purple)
                        }
                    }
                    .chartXAxis { // Customizing X-axis to show day of the week
                        AxisMarks(values: .stride(by: .day)) {
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .frame(height: 200)
                    .padding()
                }
            } else if dataType == .distance {
                Text("步行距离历史趋势")
                    .font(.title2)
                    .padding(.bottom, 5)
                
                if healthKitManager.weeklyDistanceData.isEmpty {
                    Text("暂无距离数据")
                        .foregroundStyle(.secondary)
                } else {
                    Chart {
                        ForEach(healthKitManager.weeklyDistanceData) {
                            data in
                            BarMark(x: .value("日期", data.date, unit: .day),
                                    y: .value("距离 (公里)", data.distance / 1000))
                            .foregroundStyle(.cyan)
                        }
                    }
                    .chartXAxis { // Customizing X-axis to show day of the week
                        AxisMarks(values: .stride(by: .day)) {
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .frame(height: 200)
                    .padding()
                }
            }
            Spacer()
        }
        .navigationTitle(dataType == .steps ? "步数详情" : "距离详情")
        .onAppear {
            Task { @MainActor in
                if dataType == .steps {
                    healthKitManager.weeklyStepData = await healthKitManager.readWeeklyStepCounts()
                } else {
                    healthKitManager.weeklyDistanceData = await healthKitManager.readWeeklyDistance()
                }
            }
        }
    }
}

struct HealthDataDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HealthDataDetailView(dataType: .steps)
                .environmentObject(HealthKitManager())
        }
        NavigationView {
            HealthDataDetailView(dataType: .distance)
                .environmentObject(HealthKitManager())
        }
    }
}
