import SwiftUI

struct DistanceCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    var body: some View {
        NavigationLink(destination: HealthDataDetailView(dataType: .distance)) {
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
        .onAppear {
            healthKitManager.readWeeklyDistance()
        }
    }
}

struct DistanceCard_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Add NavigationView for preview
            DistanceCard()
                .environmentObject(HealthKitManager())
        }
    }
}
