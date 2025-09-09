
import SwiftUI

struct StepsCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    var body: some View {
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

        }
        .onAppear { // onAppear 应该在 VStack 之后
            healthKitManager.readWeeklyStepCounts()
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct StepsCard_Previews: PreviewProvider {
    static var previews: some View {
        StepsCard()
            .environmentObject(HealthKitManager())
    }
}
