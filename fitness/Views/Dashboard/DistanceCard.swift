import SwiftUI

struct DistanceCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("步行距离")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "figure.walk")
                    .foregroundStyle(.cyan)
            }

            Text(String(format: "%.2f", healthKitManager.distance / 1000))
                .font(.title)
                .fontWeight(.bold)

            Text("公里")
                .font(.caption)
                .foregroundStyle(.secondary)

            DistanceBarChart(data: healthKitManager.weeklyDistanceData)
                .frame(height: 60)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .onAppear {
            healthKitManager.readWeeklyDistance()
        }
    }
}

struct DistanceCard_Previews: PreviewProvider {
    static var previews: some View {
        DistanceCard()
            .environmentObject(HealthKitManager())
    }
}
