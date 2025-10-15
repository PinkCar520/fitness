import SwiftUI
import SwiftData

struct PlanView: View {
        @StateObject private var planViewModel: PlanViewModel
        @State private var selectedDate: Date? = Date()
        @State private var showPlanSetup = false
        @State private var showPlanHistory = false
    
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
            }
        }
    private var workoutPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日锻炼").font(.title2).bold()
            VStack(spacing: 12) {
                ForEach(planViewModel.workouts) { workout in
                    HStack {
                        Image(systemName: "figure.run.circle.fill")
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text(workout.name)
                                .fontWeight(.bold)
                            Text("\(workout.durationInMinutes) 分钟 - \(workout.caloriesBurned) 卡路里")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(workout.date.shortDate)
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
