import SwiftUI
import HealthKit // Needed for HKWorkout

struct RecentActivityCard: View {
    let mostRecentWorkout: HKWorkout?

    private var workoutFound: Bool {
        mostRecentWorkout != nil
    }

    private var activityName: String {
        guard let workout = mostRecentWorkout else { return "未知活动" }
        return workout.workoutActivityType.name
    }

    private var distanceValue: Double {
        guard let workout = mostRecentWorkout,
              let distanceQuantity = workout.totalDistance else { return 0 }
        return distanceQuantity.doubleValue(for: .meter())
    }

    private var duration: String {
        guard let workout = mostRecentWorkout else { return "--" }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: workout.duration) ?? "--"
    }

    private var date: String {
        guard let workout = mostRecentWorkout else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.startDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("最近活动")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "figure.run")
                    .foregroundStyle(.orange)
            }

            if workoutFound {
                // Content for when a workout is found
                Text(activityName)
                    .font(.title)
                    .fontWeight(.bold)

                HStack {
                    VStack(alignment: .leading) {
                        Text("距离")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Text(distanceValue, format: .number.precision(.fractionLength(0)))
                                .contentTransition(.numericText(countsDown: false))
                            Text("m")
                        }
                        .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("时长")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(duration)
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("日期")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(date)
                            .font(.headline)
                    }
                }
            } else {
                // Content for when no workout is found
                HStack {
                    Spacer()
                    Text("无最近活动记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 80)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .animation(.easeInOut, value: distanceValue)
    }
}
