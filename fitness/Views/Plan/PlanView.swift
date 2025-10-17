import SwiftUI
import SwiftData

struct PlanView: View {
        @StateObject private var planViewModel: PlanViewModel
        @State private var selectedDate: Date? = Date()
            @State private var showPlanSetup = false
            @State private var showPlanHistory = false
            @State private var showLiveWorkout = false
            @State private var selectedWorkout: Workout? = nil
    @State private var selectedTask: DailyTask? = nil
    @Environment(\.modelContext) private var modelContext
                init(profileViewModel: ProfileViewModel, modelContext: ModelContext) {
            _planViewModel = StateObject(wrappedValue: PlanViewModel(profileViewModel: profileViewModel, modelContext: modelContext))
        }
    
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        CalendarView(selectedDate: $selectedDate)
                            .onChange(of: selectedDate) { oldValue, newValue in
                                planViewModel.selectedDate = newValue ?? Date()
                            }
    
                        workoutPlanSection
                        mealPlanSection
                    }
                    .padding()
                }
//                .navigationTitle("计划")
                .toolbar { 
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            showPlanHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        
                        Button {
                            showPlanSetup = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
//                .navigationTitle("计划")

            .sheet(isPresented: $showPlanSetup) {
                PlanSetupView { config in
                    planViewModel.generatePlan(config: config)
                }
                .presentationDetents([.fraction(0.85), .large])
            }
            .sheet(isPresented: $showPlanHistory) { // Present the sheet
                PlanHistoryView()
            }
            .fullScreenCover(isPresented: $showLiveWorkout) {
                if let task = selectedTask {
                    LiveWorkoutView(dailyTask: task, modelContext: modelContext)
                } else {
                    // Optional: A fallback view or just an empty view if this case should not happen
                    Text("错误：没有选择锻炼任务。")
                }
            }
            }
        }
    private var workoutPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日锻炼").font(.title2).bold()
                Spacer()
                Button("开始今日训练") {
                    self.selectedTask = planViewModel.currentDailyTask
                    self.showLiveWorkout = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(planViewModel.currentDailyTask == nil || planViewModel.workouts.isEmpty)
            }

            if planViewModel.workouts.isEmpty {
                Text("今天没有锻炼计划。")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(planViewModel.workouts) { workout in
                        WorkoutPlanCardView(workout: workout)
                    }
                }
            }
        }
    }

    private var mealPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日饮食").font(.title2).bold()
            VStack(spacing: 12) {
                ForEach(planViewModel.meals) { meal in
                    HStack {
                        Image(systemName: "leaf.circle.fill")
                            .foregroundColor(meal.mealType == .snack ? .orange : .green)
                        VStack(alignment: .leading) {
                            Text(meal.name)
                                .fontWeight(.bold)
                            Text("\(meal.calories) 卡路里 - \(meal.mealType.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(meal.date.shortDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        // Create an in-memory ModelContainer for previews
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Plan.self, configurations: config)
        
        // Add some mock data if needed for the preview
        let profileViewModel = ProfileViewModel()

        return PlanView(profileViewModel: profileViewModel, modelContext: container.mainContext)
            .modelContainer(container) // Provide the container to the environment
            .environmentObject(profileViewModel)
    }
}
