import SwiftUI
import SwiftData

struct TodaysWorkoutCard: View {
    let dailyTask: DailyTask
    var isNoActivePlan: Bool = false
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if dailyTask.isCompleted {
            completedContent()
        } else {
            if isNoActivePlan {
                noPlanContent()
            } else if dailyTask.workouts.isEmpty {
                restDayContent()
            } else {
                nextWorkoutContent(for: dailyTask)
            }
        }
    }
}

private extension TodaysWorkoutCard {    
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
            Button {
                appState.selectedTab = 1
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    // Icon (match QuickActionButton style)
                    Image(systemName: "flame.fill")
                        .font(.title3.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(Color.accentColor.opacity(0.15), in: Circle())
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("下一项训练")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text(workout.name)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Inline info chips
                        HStack(spacing: 8) {
                            if let sets = workout.sets, !sets.isEmpty {
                                InfoChip(icon: "repeat", text: "\(sets.count) 组", tint: .secondary, backgroundColor: Color.primary.opacity(0.06))
                            }
                            if let duration = workout.durationInMinutes {
                                InfoChip(icon: "stopwatch", text: "\(duration) 分钟", tint: .secondary, backgroundColor: Color.primary.opacity(0.06))
                            }
                            if workout.caloriesBurned > 0 {
                                InfoChip(icon: "flame.fill", text: "\(workout.caloriesBurned) 千卡", tint: .secondary, backgroundColor: Color.primary.opacity(0.06))
                            }
                        }
                    }

                    Spacer()

                    // Count + chevron
                    VStack(alignment: .trailing, spacing: 6) {
                        InfoChip(icon: nil, text: "\(task.workouts.count) 项", tint: .secondary, backgroundColor: Color.primary.opacity(0.06))
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)
        } else {
            restDayContent()
        }
    }
    @ViewBuilder
    func completedContent() -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 4) {
                Text("今日训练已完成！")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                Text("恭喜你坚持到最后，继续保持节奏。")
                    .font(.footnote)
                    .foregroundStyle(.green.opacity(0.75))
            }
            Spacer()
            summaryIconButton()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.25),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
    
    @ViewBuilder
    func summaryIconButton() -> some View {
        Button {
            appState.workoutSummary = (show: true, workouts: dailyTask.workouts)
        } label: {
            Image(systemName: "list.bullet.clipboard")
                .font(.body.weight(.semibold))
                .padding(10)
                .background(Color.green.opacity(0.18), in: Circle())
                .foregroundStyle(.green)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("查看总结")
    }
    
    @ViewBuilder
    func infoCapsule(text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .foregroundStyle(.white)
    }
}
