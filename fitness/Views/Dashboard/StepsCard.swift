
import SwiftUI
import HealthKit // Needed for DailyStepData

struct StepsCard: View {
    let stepCount: Double
    let weeklyStepData: [DailyStepData] // New property for chart data

    var body: some View {
        NavigationLink(destination: HealthDataDetailView(dataType: .steps)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                Text("\(Int(stepCount))")
                    .font(.title)
                    .contentTransition(.numericText(countsDown: false))
//                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary.opacity(0.8))
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 24, height: 24)
                        Image(systemName: "shoeprints.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }



                Text("步数")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                StepBarChart(data: weeklyStepData).frame(height:60) // Use new property
                // 柱状图

                HStack(spacing: 4) {
                    Spacer()
                    Text("数据来源：Apple健康")
                        .font(.system(size: 9))
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            .animation(.easeInOut, value: stepCount)
            
        }
        .buttonStyle(PlainButtonStyle()) // To remove default NavigationLink styling
    }
}

struct StepsCard_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Add NavigationView for preview
            StepsCard(stepCount: 7500, weeklyStepData: [
                DailyStepData(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, steps: 3000),
                DailyStepData(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, steps: 5000),
                DailyStepData(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, steps: 2000),
                DailyStepData(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, steps: 8000),
                DailyStepData(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, steps: 6000),
                DailyStepData(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, steps: 9000),
                DailyStepData(date: Date(), steps: 7500)
            ])
        }
    }
}
