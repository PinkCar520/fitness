import SwiftUI

struct WorkoutSummaryView: View {
    let completedWorkouts: [Workout]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.green)
                
                Text("训练完成！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("您已成功完成本次训练会话。")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Display a simple list of completed workouts for now
                List(completedWorkouts) { workout in
                    VStack(alignment: .leading) {
                        Text(workout.name)
                            .font(.headline)
                        Text("时长: \(workout.durationInMinutes) 分钟")
                            .font(.subheadline)
                        if let sets = workout.sets, !sets.isEmpty {
                            Text("组数: \(sets.count)")
                                .font(.subheadline)
                        }
                        if let distance = workout.distance {
                            Text("距离: \(distance, specifier: "%.2f") km")
                                .font(.subheadline)
                        }
                    }
                }
                .listStyle(.plain)
                
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("训练总结")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct WorkoutSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleWorkouts = [
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
        WorkoutSummaryView(completedWorkouts: sampleWorkouts)
    }
}
