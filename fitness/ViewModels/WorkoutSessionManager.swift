import Foundation
import SwiftData

// MARK: - Codable State Management Structs

struct ExerciseProgress: Codable {
    var sets: [WorkoutSet]?
    var distance: Double?
    var duration: Double?
    var notes: String?
}

struct WorkoutSessionState: Codable {
    let dailyTaskID: UUID
    let currentExerciseIndex: Int
    let elapsedTime: TimeInterval
    let sessionProgress: [Int: ExerciseProgress]
    
    // In-flight progress for the current exercise
    let currentActualSets: [WorkoutSet]
    let currentDistance: Double
    let currentDuration: Double
    let currentNotes: String
}


@MainActor
class WorkoutSessionManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published var dailyTask: DailyTask
    @Published var currentExerciseIndex: Int = 0
    
    var currentWorkout: Workout? {
        guard dailyTask.workouts.indices.contains(currentExerciseIndex) else {
            return nil
        }
        return dailyTask.workouts[currentExerciseIndex]
    }
    
    // Timer related properties
    @Published var timer: Timer?
    @Published var elapsedTime: TimeInterval = 0
    @Published var restTimeRemaining: TimeInterval = 0
    private var restTimer: Timer?
    
    // Workout progress
    @Published var currentSetIndex: Int = 0
    @Published var actualSets: [WorkoutSet] = []
    @Published var currentDistance: Double = 0.0
    @Published var currentDuration: Double = 0.0
    @Published var currentNotes: String = "" // ADDED: Missing property
    private var sessionProgress: [Int: ExerciseProgress] = [:]
    private var modelContext: ModelContext
    
    // MARK: - State Persistence
    
    private static let resumableWorkoutKey = "resumableWorkoutSession"

    // MARK: - Lifecycle
    
    init(dailyTask: DailyTask, modelContext: ModelContext) {
        self.dailyTask = dailyTask
        self.modelContext = modelContext
    }
    
    func startWorkout() {
        // Initialize workout state
        currentSetIndex = 0
        currentExerciseIndex = 0
        elapsedTime = 0
        
        loadSetsForCurrentExercise()
        
        // Start the main timer
        startMasterTimer()
    }
    
    private func startMasterTimer() {
        timer?.invalidate() // Ensure no duplicate timers
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedTime += 1
            }
        }
    }
    
    // MARK: - Core Workout Flow
    
    private func loadSetsForCurrentExercise() {
        guard let workout = currentWorkout else { return }
        
        // Load planned sets or create default ones
        if let plannedSets = workout.sets, !plannedSets.isEmpty {
            self.actualSets = plannedSets
        } else if workout.type == .strength {
            // If no sets are planned for a strength workout, create a default template
            self.actualSets = [
                WorkoutSet(reps: 10, weight: 0, isCompleted: false),
                WorkoutSet(reps: 10, weight: 0, isCompleted: false),
                WorkoutSet(reps: 10, weight: 0, isCompleted: false)
            ]
        } else {
            self.actualSets = []
        }
        self.currentNotes = "" // Reset notes for the new exercise
        self.currentDistance = 0.0
        self.currentDuration = 0.0
    }
    
    func endWorkout() -> [Workout] {
        // Invalidate the timer
        timer?.invalidate()
        timer = nil
        
        var completedWorkouts: [Workout] = []
        
        // Save the final state of the current exercise
        let finalProgress = ExerciseProgress(sets: actualSets, distance: currentDistance, duration: currentDuration, notes: currentNotes)
        sessionProgress[currentExerciseIndex] = finalProgress
        
        // 1. Update the original plan's workouts with actual data
        for (index, progress) in sessionProgress {
            guard dailyTask.workouts.indices.contains(index) else { continue }
            
            // Get the workout from the plan
            let workoutToUpdate = dailyTask.workouts[index]
            
            // Update its properties with the actual performance
            workoutToUpdate.isCompleted = true
            workoutToUpdate.sets = progress.sets
            workoutToUpdate.distance = progress.distance
            workoutToUpdate.duration = progress.duration
            workoutToUpdate.notes = progress.notes
            // The date and calories burned remain as planned
            
            completedWorkouts.append(workoutToUpdate)
        }

        // 2. Check if the entire daily task is now complete
        if dailyTask.workouts.allSatisfy({ $0.isCompleted }) {
            dailyTask.isCompleted = true
        }
        
        // Clear any saved state upon successful completion
        Self.clearSavedState()
        
        // Try to save the context
        do {
            try modelContext.save()
            return completedWorkouts
        } catch {
            print("Failed to save workout session: \(error.localizedDescription)")
            return []
        }
    }
    
    func nextExercise() {
        // Save the progress of the current exercise before moving to the next one
        let progress = ExerciseProgress(sets: actualSets, distance: currentDistance, duration: currentDuration, notes: currentNotes)
        sessionProgress[currentExerciseIndex] = progress
        
        if currentExerciseIndex < dailyTask.workouts.count - 1 {
            currentExerciseIndex += 1
            loadSetsForCurrentExercise()
        } else {
            // This was the last exercise, so we can end the workout.
            // Note: endWorkout() is now called from the View layer to show summary
        }
    }
    
    func completeSet(at index: Int) {
        guard actualSets.indices.contains(index) else { return }
        
        // Toggle the completion state
        let isCompleted = actualSets[index].isCompleted ?? false
        actualSets[index].isCompleted = !isCompleted
        
        // Invalidate any existing rest timer
        restTimer?.invalidate()
        
        if !isCompleted {
            // If the set is now complete, start the rest timer
            restTimeRemaining = 60 // 60 seconds rest
            restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    if self.restTimeRemaining > 0 {
                        self.restTimeRemaining -= 1
                    } else {
                        self.restTimer?.invalidate()
                        self.restTimer = nil
                    }
                }
            }
        } else {
            // If the set is marked as incomplete, reset the timer
            restTimeRemaining = 0
        }
    }
    
    // MARK: - State Restoration Logic
    
    func saveState() {
        let currentState = WorkoutSessionState(
            dailyTaskID: self.dailyTask.id,
            currentExerciseIndex: self.currentExerciseIndex,
            elapsedTime: self.elapsedTime,
            sessionProgress: self.sessionProgress,
            currentActualSets: self.actualSets,
            currentDistance: self.currentDistance,
            currentDuration: self.currentDuration,
            currentNotes: self.currentNotes
        )
        
        if let encodedData = try? JSONEncoder().encode(currentState) {
            UserDefaults.standard.set(encodedData, forKey: Self.resumableWorkoutKey)
            print("Workout state saved.")
        }
    }
    
    func restore(from state: WorkoutSessionState) {
        self.currentExerciseIndex = state.currentExerciseIndex
        self.elapsedTime = state.elapsedTime
        self.sessionProgress = state.sessionProgress
        self.actualSets = state.currentActualSets
        self.currentDistance = state.currentDistance
        self.currentDuration = state.currentDuration
        self.currentNotes = state.currentNotes
        
        // Restart the master timer
        startMasterTimer()
        print("Workout state restored.")
    }
    
    static func loadSavedState() -> WorkoutSessionState? {
        guard let savedData = UserDefaults.standard.data(forKey: resumableWorkoutKey),
              let decodedState = try? JSONDecoder().decode(WorkoutSessionState.self, from: savedData) else {
            return nil
        }
        return decodedState
    }
    
    static func clearSavedState() {
        UserDefaults.standard.removeObject(forKey: resumableWorkoutKey)
        print("Saved workout state cleared.")
    }
}