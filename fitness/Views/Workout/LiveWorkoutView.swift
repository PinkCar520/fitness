import SwiftUI
import SwiftData

struct LiveWorkoutView: View {
    @StateObject private var sessionManager: WorkoutSessionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState // Add AppState
    
    @State private var showEndWorkoutAlert: Bool = false
    
    @State private var showingDistancePicker = false
    @State private var showingDurationPicker = false
    
    let resumableState: WorkoutSessionState?
    
    init(dailyTask: DailyTask, modelContext: ModelContext, resumableState: WorkoutSessionState? = nil) {
        _sessionManager = StateObject(wrappedValue: WorkoutSessionManager(dailyTask: dailyTask, modelContext: modelContext))
        self.resumableState = resumableState
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let workout = sessionManager.currentWorkout {
                    // Header: Exercise Name and Progress
                    VStack {
                        Text(workout.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("动作 \(sessionManager.currentExerciseIndex + 1) / \(sessionManager.dailyTask.workouts.count)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }.padding()

                    Text(formatTime(sessionManager.elapsedTime))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .padding()
                    
                    if sessionManager.restTimeRemaining > 0 {
                        Text("休息: \(formatTime(sessionManager.restTimeRemaining))")
                            .font(.system(size: 30, weight: .semibold, design: .monospaced))
                            .foregroundColor(.orange)
                            .padding(.bottom, 10)
                    }
                    
                    // Display sets for strength workouts
                    if workout.type == .strength {
                        ScrollView {
                            ForEach($sessionManager.actualSets.indices, id: \.self) { index in
                                WorkoutSetRowView(set: $sessionManager.actualSets[index], setIndex: index) {
                                    Haptics.simpleSuccess()
                                    sessionManager.completeSet(at: index)
                                }
                            }
                        }
                    } else if workout.type == .cardio {
                        VStack(spacing: 20) {
                            VStack {
                                Text("距离 (km)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Button(action: {
                                        if sessionManager.currentDistance > 0 { sessionManager.currentDistance -= 0.1 }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                    }
                                    Text("\(sessionManager.currentDistance, specifier: "%.1f")")
                                        .font(.title2)
                                        .frame(minWidth: 60)
                                        .onTapGesture { showingDistancePicker = true }
                                    Button(action: {
                                        sessionManager.currentDistance += 0.1
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            VStack {
                                Text("时长 (min)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Button(action: {
                                        if sessionManager.currentDuration > 0 { sessionManager.currentDuration -= 1 }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                    }
                                    Text("\(sessionManager.currentDuration, specifier: "%.0f")")
                                        .font(.title2)
                                        .frame(minWidth: 60)
                                        .onTapGesture { showingDurationPicker = true }
                                    Button(action: {
                                        sessionManager.currentDuration += 1
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .padding()
                        Spacer()
                    } else {
                        // UI for Other workout types
                        VStack(alignment: .leading) {
                            Text("记录感受:")
                                .font(.headline)
                                .padding(.horizontal)
                            TextEditor(text: $sessionManager.currentNotes)
                                .frame(height: 150)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .padding(.horizontal)
                        }
                        Spacer()
                    }
                    
                    // Footer: Next Exercise Button
                    Button(action: {
                        Haptics.simpleTap()
                        if sessionManager.currentExerciseIndex < sessionManager.dailyTask.workouts.count - 1 {
                            sessionManager.nextExercise()
                        } else {
                            // This is the last exercise, end the workout
                            let completed = sessionManager.endWorkout()
                            appState.workoutSummary = (show: true, workouts: completed)
                            dismiss()
                        }
                    }) {
                        Text(sessionManager.currentExerciseIndex < sessionManager.dailyTask.workouts.count - 1 ? "下一个动作" : "完成训练")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding()

                }
            }
            .onAppear {
                sessionManager.startWorkout()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { 
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("结束") {
                        showEndWorkoutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .alert("结束训练?", isPresented: $showEndWorkoutAlert) {
                Button("确认结束", role: .destructive) {
                    let completed = sessionManager.endWorkout()
                    appState.workoutSummary = (show: true, workouts: completed)
                    dismiss()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("您确定要结束当前的训练吗？所有进度将被保存。")
            }

        }
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
