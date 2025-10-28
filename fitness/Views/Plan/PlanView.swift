import SwiftUI
import SwiftData

// A wrapper to pass both the task and an optional resumable state to the sheet
struct WorkoutLaunchContext: Identifiable {
    var id: UUID { task.id }
    let task: DailyTask
    let resumableState: WorkoutSessionState?
}

struct PlanView: View {
    @StateObject private var planViewModel: PlanViewModel
    @State private var selectedDate: Date? = Date()
    @State private var showPlanSetup = false // Restored
    @State private var showPlanHistory = false
    
    // State for launching the workout view
    @State private var workoutContext: WorkoutLaunchContext?
    
    // State for handling the resume alert
    @State private var resumableState: WorkoutSessionState?
    @State private var resumableTask: DailyTask?
    @State private var showResumeAlert = false
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var recommendationManager: RecommendationManager // New

    @Query(filter: #Predicate<Plan> { $0.status == "active" }) private var activePlans: [Plan]

    init(profileViewModel: ProfileViewModel, modelContext: ModelContext) {
        _planViewModel = StateObject(wrappedValue: PlanViewModel(profileViewModel: profileViewModel, modelContext: modelContext)) // Pass recommendationManager
    }

    private var completedDates: Set<Date> {
        guard let plan = activePlans.first else { return [] }
        
        let completedTasks = plan.dailyTasks.filter { $0.isCompleted }
        
        let dates = completedTasks.map { task -> Date in
            return Calendar.current.startOfDay(for: task.date)
        }
        
        return Set(dates)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.7))
            Text("暂无训练计划")
                .font(.title)
                .fontWeight(.bold)
            Text("开始创建一个性化的训练计划来达成你的目标吧。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("创建新计划") {
                showPlanSetup = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top)
            Spacer()
        }
        .padding()
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if activePlans.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            CalendarView(selectedDate: $selectedDate, completedDates: completedDates)
                                .onChange(of: selectedDate) { oldValue, newValue in
                                    planViewModel.selectedDate = newValue ?? Date()
                                }
                            
                            workoutPlanSection
                            mealPlanSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("训练计划")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showPlanHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    
                    // Restored PlanSetup button
                    Button {
                        showPlanSetup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
                        // Restored PlanSetupView sheet
                        .sheet(isPresented: $showPlanSetup) { // Present the sheet
                            PlanSetupView { config in
                                // This will need to be updated to use RecommendationManager
                                // For now, keeping original call to avoid further errors
                                planViewModel.generatePlan(config: config, recommendationManager: recommendationManager) // Pass recommendationManager
                            }
                            .presentationDetents([.fraction(0.85), .large])
                        }
                        .sheet(isPresented: $showPlanHistory) { // Present the sheet
                            PlanHistoryView()
                        }
                        .fullScreenCover(item: $workoutContext) { context in
                            LiveWorkoutView(dailyTask: context.task, modelContext: modelContext, resumableState: context.resumableState)
                        }
                        .onAppear(perform: checkForResumableWorkout)
                        .alert("继续上次的训练?", isPresented: $showResumeAlert) {
                            Button("继续") {
                                if let task = resumableTask, let state = resumableState {
                                    self.workoutContext = WorkoutLaunchContext(task: task, resumableState: state)
                                }
                            }
                            Button("丢弃", role: .destructive) {
                                // Clear the saved state
                                WorkoutSessionManager.clearSavedState()
                            }
                        } message: {
                            Text("您有一个未完成的训练。要从上次中断的地方继续吗？")
                        }
                    }
                }
                
                private var workoutPlanSection: some View {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(title: "今日锻炼", subtitle: formattedSummaryDate(for: planViewModel.currentDailyTask?.date), icon: "figure.strengthtraining.traditional")

                        if let currentDailyTask = planViewModel.currentDailyTask {
                            VStack(spacing: 16) {
                                if currentDailyTask.workouts.isEmpty {
                                    restStateCard(
                                        title: "休息日也很重要",
                                        message: "调整状态、补充营养，为下一次训练打好基础。",
                                        icon: "powerplug.fill"
                                    )
                                } else {
                                    workoutSummaryCard(for: currentDailyTask)

                                    LazyVStack(spacing: 14) {
                                        ForEach(currentDailyTask.workouts) { workout in
                                            WorkoutPlanCardView(workout: workout)
                                        }
                                    }
                                }
                            }
                        } else {
                            restStateCard(
                                title: "今日暂无计划",
                                message: "在计划页中选择一个日期或创建新的训练计划。",
                                icon: "calendar.badge.plus"
                            )
                        }
                    }
                }
            
                private var mealPlanSection: some View {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(title: "今日饮食", subtitle: mealSectionSubtitle(for: planViewModel.meals), icon: "fork.knife")

                        if planViewModel.meals.isEmpty {
                            restStateCard(
                                title: "还没有饮食安排",
                                message: "规划好每一餐，摄入更有节奏。",
                                icon: "takeoutbag.and.cup.and.straw.fill"
                            )
                        } else {
                            mealSummaryCard(meals: planViewModel.meals)

                            LazyVStack(spacing: 14) {
                                ForEach(planViewModel.meals) { meal in
                                    MealPlanCardView(meal: meal)
                                }
                            }
                        }
                    }
                }
                
                @ViewBuilder
                private func sectionHeader(title: String, subtitle: String, icon: String) -> some View {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                }

                private func workoutSummaryCard(for task: DailyTask) -> some View {
                    let workouts = task.workouts
                    let completedCount = workouts.filter { $0.isCompleted }.count
                    let totalCount = workouts.count
                    let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
                    let nextWorkout = workouts.first { !$0.isCompleted } ?? workouts.first

                    return VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("今日进度")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.75))
                                Text("\(completedCount)/\(workouts.count) 已完成")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            infoPill(text: formattedSummaryDate(for: task.date), systemImage: "calendar", foreground: .white, background: .white)
                        }

                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(.white)

                        if let nextWorkout {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("下一项训练")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.75))

                                HStack(alignment: .center, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.15))
                                            .frame(width: 46, height: 46)
                                        Image(systemName: nextWorkout.type.symbolName)
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(nextWorkout.name)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text(nextWorkout.type.displayName)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.75))
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.95),
                                Color.accentColor.opacity(0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

                private func mealSummaryCard(meals: [Meal]) -> some View {
                    let totalCalories = meals.reduce(0) { $0 + $1.calories }
                    let mealCount = meals.count
                    let rangeText = mealTimeRange(for: meals)

                    return VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("今日摄入")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.75))
                                Text("\(totalCalories) 千卡")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            infoPill(text: "\(mealCount) 餐", systemImage: "fork.knife", foreground: .white, background: .white)
                        }

                        if let rangeText {
                            Text(rangeText)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        Text("补充蛋白质与碳水，帮助训练后恢复。")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.95),
                                Color.pink.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

                private func mealSectionSubtitle(for meals: [Meal]) -> String {
                    guard !meals.isEmpty else {
                        return "安排你的营养补给"
                    }
                    let totalCalories = meals.reduce(0) { $0 + $1.calories }
                    return "共 \(meals.count) 餐 · ≈\(totalCalories) 千卡"
                }

                private func mealTimeRange(for meals: [Meal]) -> String? {
                    guard let earliest = meals.min(by: { $0.date < $1.date }),
                          let latest = meals.max(by: { $0.date < $1.date }) else {
                        return nil
                    }

                    let startText = timeString(for: earliest.date)
                    let endText = timeString(for: latest.date)

                    if startText == endText {
                        return "建议用餐时间：\(startText)"
                    }
                    return "建议用餐时间：\(startText) - \(endText)"
                }

                private func timeString(for date: Date) -> String {
                    date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
                }

                private func restStateCard(title: String, message: String, icon: String) -> some View {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                            Text(title)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
                }

                private func infoPill(text: String, systemImage: String, foreground: Color, background: Color) -> some View {
                    HStack(spacing: 6) {
                        Image(systemName: systemImage)
                            .font(.caption)
                        Text(text)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(background.opacity(0.18))
                    )
                    .foregroundStyle(foreground)
                }

                private func formattedSummaryDate(for date: Date?) -> String {
                    guard let date else {
                        return Date().formatted(.dateTime.weekday(.wide))
                    }
                    let weekday = date.formatted(.dateTime.weekday(.wide))
                    let day = date.formatted(.dateTime.month().day())
                    return "\(weekday) · \(day)"
                }

                private func checkForResumableWorkout() {
                    if let state = WorkoutSessionManager.loadSavedState() {
                        // Immediately find the corresponding task
                        if let task = planViewModel.findDailyTask(by: state.dailyTaskID) {
                            self.resumableState = state
                            self.resumableTask = task
                            self.showResumeAlert = true
                        } else {
                            // The saved state is stale/invalid because the task no longer exists.
                            // Clean it up.
                            WorkoutSessionManager.clearSavedState()
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
                    let recommendationManager = RecommendationManager(profileViewModel: profileViewModel) // New
            
                    return PlanView(profileViewModel: profileViewModel, modelContext: container.mainContext)
                        .modelContainer(container) // Provide the container to the environment
                        .environmentObject(profileViewModel)
                        .environmentObject(recommendationManager) // New
                }
            }
