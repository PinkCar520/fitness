import SwiftUI
import HealthKit // Needed for DailyDistanceData

struct DistanceCard: View {
    let distance: Double
    let weeklyDistanceData: [DailyDistanceData] // New property for chart data

    var body: some View {
        // Tap handled by parent via Button/onTapGesture
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(distance / 1000, format: .number.precision(.fractionLength(2)))
                        .font(.title)
                        .contentTransition(.numericText(countsDown: false))
//                        .fontWeight(.bold)
                        .foregroundStyle(Color.primary.opacity(0.8))
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 24, height: 24)
                        Image(systemName: "figure.walk")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }



                Text("公里")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                DistanceBarChart(data: weeklyDistanceData) // Use new property
                    .frame(height: 60)

                HStack(spacing: 4) {
                    Spacer()
                    Text("数据来源：Apple健康")
                        .font(.system(size: 9))
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            .animation(.easeInOut, value: distance)
            
    }
}

struct DistanceCard_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Add NavigationView for preview
            DistanceCard(distance: 5500, weeklyDistanceData: [
                DailyDistanceData(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, distance: 2000),
                DailyDistanceData(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, distance: 3500),
                DailyDistanceData(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, distance: 1500),
                DailyDistanceData(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, distance: 6000),
                DailyDistanceData(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, distance: 4500),
                DailyDistanceData(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, distance: 7000),
                DailyDistanceData(date: Date(), distance: 5500)
            ])
        }
    }
}
