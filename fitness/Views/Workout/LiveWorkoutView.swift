import SwiftUI
import SwiftData

struct LiveWorkoutView: View {
    @StateObject private var sessionManager: WorkoutSessionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState // Add AppState
    
    @State private var showEndWorkoutAlert: Bool = false
    
    let resumableState: WorkoutSessionState?
    
    init(dailyTask: DailyTask, modelContext: ModelContext, resumableState: WorkoutSessionState? = nil) {
        _sessionManager = StateObject(wrappedValue: WorkoutSessionManager(dailyTask: dailyTask, modelContext: modelContext))
        self.resumableState = resumableState
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                topBar

                if let workout = sessionManager.currentWorkout {
                    heroSection(for: workout)

                    timerSection

                    if sessionManager.restTimeRemaining > 0 {
                        restOverlay
                    }

                    content(for: workout)

                    primaryButton
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 30)
        }
        .onAppear {
            sessionManager.startWorkout()
        }
        .alert("结束训练?", isPresented: $showEndWorkoutAlert) {
            Button("确认结束", role: .destructive) {
                finishWorkout()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要退出沉浸式训练？当前进度会被保存。")
        }
    }

    private var totalExercises: Int {
        max(1, sessionManager.dailyTask.workouts.count)
    }

    private var workoutProgress: Double {
        Double(sessionManager.currentExerciseIndex) / Double(totalExercises)
    }

    private var actionTitle: String {
        sessionManager.currentExerciseIndex < totalExercises - 1 ? "下一个动作" : "完成训练"
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.11, blue: 0.2),
                Color(red: 0.03, green: 0.04, blue: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var topBar: some View {
        HStack {
            Button {
                showEndWorkoutAlert = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("第 \(sessionManager.currentExerciseIndex + 1)/\(totalExercises) 个动作")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                ProgressView(value: workoutProgress)
                    .tint(.white)
                    .frame(width: 140)
            }
        }
    }

    private func heroSection(for workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Text(workout.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Text(workout.durationInMinutes != nil ? "\(workout.durationInMinutes ?? 0)min" : workout.type == .strength ? "力量" : "训练")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.15), in: Capsule())
            }
            Text(workout.notes ?? "专注节奏与呼吸，保持稳定输出。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.05))
        )
    }

    private var timerSection: some View {
        VStack(spacing: 8) {
            Text(formatTime(sessionManager.elapsedTime))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("已用时")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private var restOverlay: some View {
        HStack {
            Image(systemName: "timer")
                .font(.headline)
            VStack(alignment: .leading, spacing: 2) {
                Text("休息中")
                    .font(.footnote.weight(.semibold))
                Text(formatTime(sessionManager.restTimeRemaining))
                    .font(.callout.monospacedDigit())
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding()
        .background(.orange.opacity(0.2), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func content(for workout: Workout) -> some View {
        Group {
            switch workout.type {
            case .strength:
                strengthSection
            case .cardio:
                cardioSection
            default:
                freestyleSection
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.25), value: sessionManager.currentExerciseIndex)
    }

    private var strengthSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach($sessionManager.actualSets.indices, id: \.self) { index in
                    let setBinding = $sessionManager.actualSets[index]
                    Button {
                        Haptics.simpleSuccess()
                        sessionManager.completeSet(at: index)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("第 \(index + 1) 组")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                Text("\(setBinding.wrappedValue.reps) 次 · \(setBinding.wrappedValue.weight ?? 0, specifier: "%.0f") kg")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            let completed = setBinding.wrappedValue.isCompleted ?? false
                            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(completed ? .green : .white.opacity(0.4))
                        }
                        .padding()
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var cardioSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                metricCard(title: "距离 (km)", value: sessionManager.currentDistance, step: 0.1) { delta in
                    sessionManager.currentDistance = max(0, sessionManager.currentDistance + delta)
                }
                metricCard(title: "时长 (min)", value: sessionManager.currentDuration, step: 1) { delta in
                    sessionManager.currentDuration = max(0, sessionManager.currentDuration + delta)
                }
            }
            .frame(maxWidth: .infinity)

            Text("左右滑动即可调节，无需键盘")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func metricCard(title: String, value: Double, step: Double, onChange: @escaping (Double) -> Void) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text("\(value, specifier: step == 1 ? "%.0f" : "%.1f")")
                .font(.title.bold())
                .foregroundStyle(.white)
            HStack(spacing: 20) {
                Button {
                    onChange(-step)
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.12), in: Circle())
                }
                Button {
                    onChange(step)
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(.white, in: Circle())
                        .foregroundStyle(.black)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var freestyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("记录感受")
                .font(.headline)
                .foregroundStyle(.white)
            TextEditor(text: $sessionManager.currentNotes)
                .frame(height: 140)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var primaryButton: some View {
        Button {
            Haptics.simpleTap()
            if sessionManager.currentExerciseIndex < totalExercises - 1 {
                sessionManager.nextExercise()
            } else {
                finishWorkout()
            }
        } label: {
            Text(actionTitle)
                .font(.headline.weight(.bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .padding(.top, 10)
    }

    private func finishWorkout() {
        let completed = sessionManager.endWorkout()
        appState.workoutSummary = (show: true, workouts: completed)
        dismiss()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}

struct LiveWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Workout.self, configurations: config)
        
        let workout1 = Workout(
            name: "胸部推举训练",
            durationInMinutes: 45,
            caloriesBurned: 350,
            date: Date(),
            type: .strength,
            sets: [
                WorkoutSet(reps: 12, weight: 50),
                WorkoutSet(reps: 10, weight: 60),
                WorkoutSet(reps: 8, weight: 70)
            ]
        )
        
        let workout2 = Workout(
            name: "跑步机有氧",
            durationInMinutes: 30,
            caloriesBurned: 200,
            date: Date(),
            type: .cardio
        )
        
        let dailyTask = DailyTask(date: Date(), workouts: [workout1, workout2])
        
        LiveWorkoutView(dailyTask: dailyTask, modelContext: container.mainContext)
    }
}
