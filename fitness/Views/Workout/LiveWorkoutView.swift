import SwiftUI
import SwiftData

struct LiveWorkoutView: View {
    @StateObject private var sessionManager: WorkoutSessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showSummary: Bool = false
    @State private var completedWorkouts: [Workout] = []
    
    init(dailyTask: DailyTask, modelContext: ModelContext) {
        _sessionManager = StateObject(wrappedValue: WorkoutSessionManager(dailyTask: dailyTask, modelContext: modelContext))
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
                                    sessionManager.completeSet(at: index)
                                }
                            }
                        }
                    } else if workout.type == .cardio {
                        VStack(spacing: 20) {
                            HStack {
                                Text("距离 (km):").frame(width: 100)
                                TextField("0.0", value: $sessionManager.currentDistance, formatter: NumberFormatter())
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            HStack {
                                Text("时长 (min):").frame(width: 100)
                                TextField("0.0", value: $sessionManager.currentDuration, formatter: NumberFormatter())
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                        }
                        .padding()
                        Spacer()
                    } else {
                        // UI for Other workout types
                        VStack(alignment: .leading) {
                            Text("锻炼笔记:")
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
                        sessionManager.nextExercise()
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
                        completedWorkouts = sessionManager.endWorkout()
                        showSummary = true
                    }
                    .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showSummary) {
                WorkoutSummaryView(completedWorkouts: completedWorkouts)
                    .onDisappear {
                        dismiss() // Dismiss LiveWorkoutView after summary is dismissed
                    }
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
