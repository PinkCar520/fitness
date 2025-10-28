import SwiftUI

struct WorkoutPlanCardView: View {
    let workout: Workout

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 16) {
                iconBadge

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(workout.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary.opacity(workout.isCompleted ? 0.7 : 1))

                        if workout.isCompleted {
                            completionLabel
                        }
                    }

                    Text(detailLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    infoChips
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)

            if !workout.isCompleted {
                statusPill(text: "未完成", color: Color.accentColor.opacity(0.15), foreground: .accentColor)
                    .padding(16)
            }
        }
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(workout.type.tintColor.opacity(0.15))
                .frame(width: 52, height: 52)

            Image(systemName: workout.type.symbolName)
                .font(.title2)
                .foregroundStyle(workout.type.tintColor)
        }
    }

    private var infoChips: some View {
        HStack(spacing: 8) {
            statusPill(text: workout.type.displayName, color: workout.type.tintColor.opacity(0.12), foreground: workout.type.tintColor)

            if workout.type == .strength,
               let sets = workout.sets,
               !sets.isEmpty {
                statusPill(text: "\(sets.count) 组", color: .orange.opacity(0.12), foreground: .orange)
            }

            if let duration = workout.durationInMinutes, duration > 0 {
                statusPill(text: "\(duration) 分钟", color: .blue.opacity(0.12), foreground: .blue)
            }

            statusPill(text: "≈\(workout.caloriesBurned) 千卡", color: .pink.opacity(0.12), foreground: .pink)
        }
    }

    private var detailLine: String {
        switch workout.type {
        case .strength:
            if let sets = workout.sets, !sets.isEmpty {
                let repsSummary = sets.compactMap { $0.weight != nil ? "\($0.reps)次·\($0.weight!)kg" : "\($0.reps)次" }
                    .prefix(2)
                    .joined(separator: " | ")
                return repsSummary.isEmpty ? "力量训练，专注动作质量" : repsSummary
            }
            return "力量训练，专注动作质量"
        case .cardio:
            if let distance = workout.distance, distance > 0 {
                return String(format: "有氧训练 · %.1f 公里", distance)
            }
            return "有氧训练，保持心率区间"
        case .flexibility:
            return "柔韧训练，放松肌肉"
        case .other:
            return "自定义内容，按计划执行"
        }
    }

    private var completionLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
            Text("已完成")
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.15), in: Capsule())
        .foregroundStyle(Color.green)
    }

    private func statusPill(text: String, color: Color, foreground: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color)
            )
            .foregroundStyle(foreground)
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
