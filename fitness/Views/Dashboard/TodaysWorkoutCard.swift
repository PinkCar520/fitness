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
                    colors: [
                        Color.accentColor.opacity(0.85),
                        Color.accentColor.opacity(0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
