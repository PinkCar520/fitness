import SwiftUI
import SwiftData

struct TodaysWorkoutCard: View {
    let dailyTask: DailyTask
    var isNoActivePlan: Bool = false
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if dailyTask.isCompleted {
                completedContent()
            } else {
                header()

                if isNoActivePlan {
                    noPlanContent()
                } else if dailyTask.workouts.isEmpty {
                    restDayContent()
                } else {
                    nextWorkoutContent(for: dailyTask)
                }
            }
        }
        .padding()
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

private extension TodaysWorkoutCard {
    @ViewBuilder
    func header() -> some View {
        HStack {
            Text("今日计划")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    @ViewBuilder
    func completedContent() -> some View {
        HStack {
            Spacer()
            Image(systemName: "flag.checkered.2.crossed")
                .foregroundStyle(.green)
        }

        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(.green)
            Text("今日训练已完成! 🎉")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.green)
        }

        Text("你真棒！继续保持，期待看到你长期的进步。")
            .font(.body)
            .foregroundStyle(.secondary)
            .padding(.bottom, 10)

        Button {
            appState.workoutSummary = (show: true, workouts: dailyTask.workouts)
        } label: {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                Text("查看总结")
                    .font(.headline)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.green.opacity(0.1), in: Capsule())
            .foregroundStyle(.green)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func noPlanContent() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("暂无活跃计划")
                .font(.headline)
                .fontWeight(.bold)
            Text("请前往“计划”页面创建一个新的训练计划。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                appState.selectedTab = 1
            } label: {
                Label("去计划页面创建", systemImage: "arrow.right.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func restDayContent() -> some View {
        HStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.largeTitle)
                .foregroundColor(.mint)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text("休息日")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("好好休息，积蓄能量！")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.mint.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    func nextWorkoutContent(for task: DailyTask) -> some View {
        if let workout = task.workouts.first {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(6)
                        .background(Color.accentColor.opacity(0.6))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("下一项训练")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(workout.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Text("\(task.workouts.count) 项")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.15), in: Capsule())
                }

                HStack(spacing: 8) {
                    if workout.type == .strength,
                       let sets = workout.sets,
                       !sets.isEmpty {
                        infoCapsule(text: "\(sets.count) 组", icon: "repeat")
                    }

                    if workout.type == .cardio,
                       let duration = workout.durationInMinutes {
                        infoCapsule(text: "\(duration) 分钟", icon: "stopwatch")
                    }

                    if workout.caloriesBurned > 0 {
                        infoCapsule(text: "\(workout.caloriesBurned) 千卡", icon: "flame.fill")
                    }
                }

                Button {
                    appState.selectedTab = 1
                } label: {
                    HStack(spacing: 6) {
                        Text("查看计划")
                            .font(.footnote)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.18), in: Capsule())
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityHint("切换到计划页查看详情")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            restDayContent()
        }
    }
}

private extension TodaysWorkoutCard {
    @ViewBuilder
    func infoCapsule(text: String, icon: String) -> some View {
        Label {
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
        } icon: {
            Image(systemName: icon)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .foregroundStyle(.white)
        .background(Color.white.opacity(0.18), in: Capsule())
    }
}

struct TodaysWorkoutCard_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Workout.self, configurations: config)

        let mockWorkout1 = Workout(name: "哑铃深蹲", durationInMinutes: 5, caloriesBurned: 50, date: Date(), type: .strength, sets: [WorkoutSet(reps: 12, weight: 10)])
        let mockDailyTask = DailyTask(date: Date(), workouts: [mockWorkout1])

        TodaysWorkoutCard(dailyTask: mockDailyTask)
            .padding()
            .previewLayout(.sizeThatFits)
            .modelContainer(container)
    }
}
