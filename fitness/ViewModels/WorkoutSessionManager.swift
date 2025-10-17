import Foundation
import SwiftData

// A struct to hold the progress of a single exercise within a session
struct ExerciseProgress {
    var sets: [WorkoutSet]?
    var distance: Double?
    var duration: Double?
    var notes: String?
}

@MainActor
class WorkoutSessionManager: ObservableObject {
    
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
    @Published var currentNotes: String = ""
    
    private var sessionProgress: [Int: ExerciseProgress] = [:]    
    private var modelContext: ModelContext
    
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
        
        // Start the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }
    
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
    }
    
    func endWorkout() -> [Workout] {
        // Invalidate the timer
        timer?.invalidate()
        timer = nil
        
        var completedWorkouts: [Workout] = []
        
        // Save the final state of the current exercise
        let finalProgress = ExerciseProgress(sets: actualSets, distance: currentDistance, duration: currentDuration, notes: currentNotes)
        sessionProgress[currentExerciseIndex] = finalProgress
        
        // Iterate over all the progress and save each workout
        for (index, progress) in sessionProgress {
            guard dailyTask.workouts.indices.contains(index) else { continue }
            let originalWorkout = dailyTask.workouts[index]
            
            let newWorkout = Workout(
                name: originalWorkout.name,
                durationInMinutes: Int(progress.duration ?? elapsedTime / 60), // Refine duration logic
                caloriesBurned: originalWorkout.caloriesBurned, // Placeholder
                date: Date(),
                type: originalWorkout.type,
                distance: progress.distance,
                duration: progress.duration,
                sets: progress.sets,
                notes: progress.notes
            )
            modelContext.insert(newWorkout)
            completedWorkouts.append(newWorkout)
        }
        
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
            endWorkout()
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
                guard let self = self else { return }
                if self.restTimeRemaining > 0 {
                    self.restTimeRemaining -= 1
                } else {
                    self.restTimer?.invalidate()
                    self.restTimer = nil
                }
            }
        } else {
            // If the set is marked as incomplete, reset the timer
            restTimeRemaining = 0
        }
    }
    
    // Add more methods to manage the workout session
}
