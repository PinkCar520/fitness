import SwiftUI

struct WorkoutSummaryView: View {
    let completedWorkouts: [Workout]
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    private var totalDuration: Int {
        var sum = 0
        for workout in completedWorkouts {
            sum += workout.durationInMinutes ?? 0
        }
        return sum
    }

    private var totalCalories: Int {
        var sum = 0
        for workout in completedWorkouts {
            sum += workout.caloriesBurned
        }
        return sum
    }

    private var totalWorkouts: Int {
        completedWorkouts.count
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Key Metrics Section
                    HStack(spacing: 16) {
                        SummaryMetricCard(icon: "timer", value: "\(totalDuration)", unit: "分钟", label: "总时长", color: .blue)
                        SummaryMetricCard(icon: "flame.fill", value: "\(totalCalories)", unit: "千卡", label: "总热量", color: .orange)
                        SummaryMetricCard(icon: "dumbbell.fill", value: "\(totalWorkouts)", unit: "个动作", label: "完成项", color: .purple)
                    }

                    // Completed Workouts List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("训练详情")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        ForEach(completedWorkouts) { workout in
                            WorkoutSummaryRowView(workout: workout)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("训练总结")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Helper Views

private struct SummaryMetricCard: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

private struct WorkoutSummaryRowView: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: workout.type == .strength ? "dumbbell.fill" : "figure.run")
                .font(.title2)
                .foregroundColor(workout.type == .strength ? .purple : .teal) // Dynamic color
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(workout.name)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(workoutDetails)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background((workout.type == .strength ? Color.purple : Color.teal).opacity(0.1))
        .cornerRadius(12)
    }

    private var workoutDetails: String {
        if workout.type == .strength, let sets = workout.sets, !sets.isEmpty {
            let reps = sets.first?.reps ?? 0
            return "\(sets.count) 组 x \(reps) 次"
        } else if workout.type == .cardio, let duration = workout.durationInMinutes {
            return "\(duration) 分钟"
        } else {
            return "\(workout.durationInMinutes ?? 0) 分钟"
        }
    }
}

// MARK: - Previews

struct WorkoutSummaryView_Previews: PreviewProvider {
    static var sampleWorkouts: [Workout] = [
        Workout(
            name: "卧推",
            durationInMinutes: 20,
            caloriesBurned: 150,
            date: Date(),
            type: .strength,
            sets: [
                WorkoutSet(reps: 10, weight: 60, isCompleted: true),
                WorkoutSet(reps: 8, weight: 70, isCompleted: true)
            ]
        ),
        Workout(
            name: "跑步",
            durationInMinutes: 30,
            caloriesBurned: 250,
            date: Date(),
            type: .cardio,
            distance: 5.0,
            duration: 1800
        )
    ]

    static var previews: some View {
        WorkoutSummaryView(completedWorkouts: sampleWorkouts)

        VStack {
            WorkoutSummaryRowView(workout: sampleWorkouts[0])
            WorkoutSummaryRowView(workout: sampleWorkouts[1])
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}