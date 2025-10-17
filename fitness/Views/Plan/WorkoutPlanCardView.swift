import SwiftUI

struct WorkoutPlanCardView: View {
    let workout: Workout

    var body: some View {
        HStack {
            // Left side: Workout Info
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("\(workout.durationInMinutes) 分钟 - 约 \(workout.caloriesBurned) 千卡")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct WorkoutPlanCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleWorkout = Workout(
            name: "胸部推举训练",
            durationInMinutes: 45,
            caloriesBurned: 350,
            date: Date(),
            type: .strength
        )
        
        WorkoutPlanCardView(workout: sampleWorkout)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
