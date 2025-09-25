
import SwiftUI

struct StepsCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    var body: some View {
        NavigationLink(destination: HealthDataDetailView(dataType: .steps)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("步数")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.purple)
                }

                Text("\(Int(healthKitManager.stepCount))")
                    .font(.title)
                    .fontWeight(.bold)

                Text("本周")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                StepBarChart(data: healthKitManager.weeklyStepData).frame(height:60)
                // 柱状图

                HStack(spacing: 4) {
                    Spacer()
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                    Text("来自“Apple健康”")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(PlainButtonStyle()) // To remove default NavigationLink styling
        .onAppear { // onAppear 应该在 VStack 之后
            healthKitManager.readWeeklyStepCounts()
        }
    }
}

struct StepsCard_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Add NavigationView for preview
            StepsCard()
                .environmentObject(HealthKitManager())
        }
    }
}
