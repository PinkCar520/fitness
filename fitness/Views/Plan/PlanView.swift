import SwiftUI
import SwiftData
import Foundation

// A wrapper to pass both the task and an optional resumable state to the sheet
struct WorkoutLaunchContext: Identifiable {
    var id: UUID { task.id }
    let task: DailyTask
    let resumableState: WorkoutSessionState?
}

struct PlanView: View {
    @StateObject private var planViewModel: PlanViewModel
    @State private var selectedDate: Date? = Calendar.current.startOfDay(for: Date())
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
    @EnvironmentObject private var appState: AppState

    @Query(filter: #Predicate<Plan> { $0.status == "active" }) private var activePlans: [Plan]
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]

    init(profileViewModel: ProfileViewModel, modelContext: ModelContext) {
        _planViewModel = StateObject(wrappedValue: PlanViewModel(profileViewModel: profileViewModel, modelContext: modelContext)) // Pass recommendationManager
    }

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    private var weeklySummary: PlanWeeklySummary? {
        planViewModel.weeklySummary()
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
    private var planGoalSummarySection: some View {
        if let plan = activePlans.first {
            let goal = plan.planGoal
            let startWeight = goal.resolvedStartWeight(from: weightMetrics)
            let currentWeight = latestRecordedWeight ?? startWeight
            let progress = goalProgress(for: plan, baseline: startWeight)

            goalSummaryCard(
                plan: plan,
                goal: goal,
                startWeight: startWeight,
                currentWeight: currentWeight,
                progress: progress
            )
        }
    }

    @ViewBuilder
    private var weeklySummarySection: some View {
        if let summary = weeklySummary {
            DashboardSurface {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.accentColor)
                        Text("本周摘要")
                            .font(.headline.weight(.bold))
                        Spacer()
                        Text("\(Int(summary.completionRate * 100))%")
                            .font(.title3.weight(.heavy))
                            .foregroundColor(.accentColor)
                    }

                    ProgressView(value: summary.completionRate)
                        .progressViewStyle(.linear)

                    HStack(spacing: 12) {
                        InfoChip(icon: "checkmark.circle.fill", text: "已完成 \(summary.completedDays)", tint: .accentColor, backgroundColor: Color.accentColor.opacity(0.15))
                        if summary.pendingDays > 0 {
                            InfoChip(icon: "hourglass", text: "待完成 \(summary.pendingDays)", tint: .orange, backgroundColor: Color.orange.opacity(0.15))
                        }
                        if summary.skippedDays > 0 {
                            InfoChip(icon: "arrow.uturn.left", text: "跳过 \(summary.skippedDays)", tint: .pink, backgroundColor: Color.pink.opacity(0.15))
                        }
                    }

                    Text("连续完成 \(summary.streakDays) 天 · 本周共 \(summary.totalDays) 日安排")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var planInsightsSection: some View {
        if !planViewModel.insights.isEmpty {
            VStack(spacing: 12) {
                ForEach(planViewModel.insights) { item in
                    InsightCard(
                        title: item.title,
                        description: item.message,
                        tone: item.tone,
                        action: planInsightAction(for: item.intent)
                    )
                }
            }
        }
    }

    private var latestRecordedWeight: Double? {
        weightMetrics.last?.value
    }

    private func goalProgress(for plan: Plan, baseline: Double? = nil) -> Double {
        guard let current = latestRecordedWeight else { return 0.0 }
        let goal = plan.planGoal
        let startWeight = baseline ?? goal.resolvedStartWeight(from: weightMetrics)
        let delta = goal.targetWeight - startWeight
        guard delta != 0 else { return current == goal.targetWeight ? 1.0 : 0.0 }
        let progress = (current - startWeight) / delta
        return max(0, min(1, progress))
    }

    private func planInsightAction(for intent: PlanInsightItem.Intent) -> InsightCard.Action? {
        switch intent {
        case .startWorkout:
            return InsightCard.Action(title: "开始训练", icon: "play.fill") {
                if let task = planViewModel.currentDailyTask {
                    workoutContext = WorkoutLaunchContext(task: task, resumableState: nil)
                } else {
                    appState.selectedTab = 1
                }
            }
        case .logWeight:
            return InsightCard.Action(title: "记录体重", icon: "scalemass.fill") {
                appState.selectedTab = 0
                NotificationCenter.default.post(name: .showInputSheet, object: nil)
            }
        case .reviewMeals:
            return InsightCard.Action(title: "查看饮食", icon: "fork.knife") {
                appState.selectedTab = 2
            }
        case .none:
            return nil
        }
    }

    private func goalSummaryCard(plan: Plan, goal: PlanGoal, startWeight: Double, currentWeight: Double, progress: Double) -> some View {
        let clampedProgress = max(0, min(1, progress))
        let isGoalComplete = clampedProgress >= 0.999
        let progressText = "\(Int(clampedProgress * 100))%"
        let headline = "\(goal.fitnessGoal.rawValue) · \(String(format: "%.1fkg", startWeight)) → \(String(format: "%.1fkg", goal.targetWeight))"
        let gradient = LinearGradient(colors: [
            Color.accentColor.opacity(0.95),
            Color.accentColor.opacity(0.6)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)

        let todaysTask = planViewModel.currentDailyTask
        let todaysWorkouts = todaysTask?.workouts.count ?? 0
        let hasWorkoutsToday = !(todaysTask?.workouts.isEmpty ?? true)
        let todaysMeals = planViewModel.meals.count

        let trainingText: String
        let trainingIcon: String
        if let _ = todaysTask {
            if hasWorkoutsToday {
                trainingText = "今日锻炼 \(todaysWorkouts) 项"
                trainingIcon = "figure.strengthtraining.traditional"
            } else {
                trainingText = "今日休息日"
                trainingIcon = "moon.zzz.fill"
            }
        } else {
            trainingText = "选择日期查看计划"
            trainingIcon = "calendar.badge.clock"
        }

        let mealText: String
        let mealIcon: String
        if todaysMeals == 0 {
            mealText = "饮食待安排"
            mealIcon = "takeoutbag.and.cup.and.straw"
        } else {
            mealText = "今日饮食 \(todaysMeals) 份"
            mealIcon = "fork.knife"
        }

        let statusText = isGoalComplete ? "目标已完成" : "稳步推进"
        let statusIcon = isGoalComplete ? "trophy.fill" : "bolt.heart.fill"

        let startText = String(format: "%.1f kg", startWeight)
        let currentText = String(format: "%.1f kg", currentWeight)
        let targetText = String(format: "%.1f kg", goal.targetWeight)

        let remainingDaysText: String? = {
            guard let targetDate = goal.targetDate else { return nil }
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let startOfTarget = calendar.startOfDay(for: targetDate)
            let diff = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget).day ?? 0
            if diff > 0 {
                return "剩余 \(diff) 天"
            } else if diff < 0 {
                return "超出 \(abs(diff)) 天"
            } else {
                return "今日截止"
            }
        }()

        return ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.accentColor.opacity(0.25), radius: 16, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(plan.name)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                        Text(headline)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                        if let targetDate = goal.targetDate {
                            Text("目标截止 \(targetDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 12) {
                        Button {
                            showPlanSetup = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.16), in: Circle())
                        }
                        statusBadge(icon: statusIcon, text: statusText)
                        VStack(spacing: 2) {
                            Text(progressText)
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("完成度")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    ProgressView(value: clampedProgress)
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.12), in: Capsule())

                    if let remainingDaysText {
                        Text(remainingDaysText)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))
                    }

                    HStack(spacing: 16) {
                        metricBadge(icon: "figure.walk", title: "起点", value: startText)
                        metricBadge(icon: "scalemass.fill", title: "当前", value: currentText)
                        metricBadge(icon: "flag.checkered", title: "目标", value: targetText)
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)

                HStack(spacing: 12) {
                    infoChip(icon: trainingIcon, text: trainingText)
                    infoChip(icon: mealIcon, text: mealText)
                }
            }
            .padding(24)
        }
    }

    private func metricBadge(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white.opacity(0.75))
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusBadge(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.18), in: Capsule())
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.14), in: Capsule())
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
    
@MainActor
var body: some View {
    mainContent
}

@ViewBuilder
private var mainContent: some View {
    NavigationStack {
        mainNavigationContent
    }
}

@ViewBuilder
private var mainNavigationContent: some View {
    content
        .navigationTitle("训练计划")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showPlanSetup) { planSetupSheet }
        .sheet(isPresented: $showPlanHistory) { PlanHistoryView() }
        .modifier(WorkoutLaunchModifier(context: $workoutContext, modelContext: modelContext))
        .modifier(PlanLifecycleModifier(
            planViewModel: planViewModel,
            allMetrics: allMetrics,
            activePlans: activePlans,
            showResumeAlert: $showResumeAlert,
            resumableTask: $resumableTask,
            resumableState: $resumableState
        ))
}

private struct WorkoutLaunchModifier: ViewModifier {
    @Binding var context: WorkoutLaunchContext?
    var modelContext: ModelContext

    func body(content: Content) -> some View {
        content.fullScreenCover(item: $context) { ctx in
            LiveWorkoutView(dailyTask: ctx.task, modelContext: modelContext, resumableState: ctx.resumableState)
        }
    }
}

private struct PlanLifecycleModifier: ViewModifier {
    @ObservedObject var planViewModel: PlanViewModel
    var allMetrics: [HealthMetric]
    var activePlans: [Plan]
    @Binding var showResumeAlert: Bool
    @Binding var resumableTask: DailyTask?
    @Binding var resumableState: WorkoutSessionState?

    func body(content: Content) -> some View {
        content
            .onAppear(perform: checkForResumableWorkout)
            .onChange(of: planViewModel.selectedDate) { _ in refreshPlanInsights() }
            .onChange(of: planViewModel.currentDailyTask?.isCompleted ?? false) { _ in refreshPlanInsights() }
            .onChange(of: planViewModel.currentDailyTask?.isSkipped ?? false) { _ in refreshPlanInsights() }
            .onChange(of: planViewModel.workouts.map { $0.isCompleted }) { _ in refreshPlanInsights() }
            .onChange(of: allMetrics.map(\.date)) { _ in refreshPlanInsights() }
            .onChange(of: activePlans.map(\.id)) { _ in refreshPlanInsights() }
            .alert("继续上次的训练?", isPresented: $showResumeAlert) {
                Button("继续") { continueResumableWorkout() }
                Button("丢弃", role: .destructive) { WorkoutSessionManager.clearSavedState() }
            } message: {
                Text("您有一个未完成的训练。要从上次中断的地方继续吗？")
            }
    }

    private func checkForResumableWorkout() {
        if let state = WorkoutSessionManager.loadSavedState() {
            if let task = planViewModel.findDailyTask(by: state.dailyTaskID) {
                self.resumableState = state
                self.resumableTask = task
                self.showResumeAlert = true
            } else {
                WorkoutSessionManager.clearSavedState()
            }
        }
    }

    private func refreshPlanInsights() {
        planViewModel.refreshInsights(weightMetrics: allMetrics.filter { $0.type == .weight })
    }

    private func continueResumableWorkout() {
        if let task = resumableTask, let state = resumableState {
            // The parent view will handle this, but for safety include the code.
            // No-op here, as the parent handles the actual launch.
        }
    }
}

private var content: some View {
    Group {
        if activePlans.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    planGoalSummarySection
                    weeklySummarySection
                    planInsightsSection
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
}

private var toolbarContent: some ToolbarContent {
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

private var planSetupSheet: some View {
    PlanSetupView { config in
        planViewModel.generatePlan(config: config, recommendationManager: recommendationManager)
    }
    .presentationDetents([.fraction(0.85), .large])
}

private func onAppear() {
    checkForResumableWorkout()
    refreshPlanInsights()
}

private func continueResumableWorkout() {
    if let task = resumableTask, let state = resumableState {
        self.workoutContext = WorkoutLaunchContext(task: task, resumableState: state)
    }
}
                
                private var workoutPlanSection: some View {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(
                            title: "今日锻炼",
                            subtitle: workoutSectionSubtitle(for: planViewModel.currentDailyTask),
                            icon: "figure.strengthtraining.traditional"
                        )

                        if let currentDailyTask = planViewModel.currentDailyTask {
                            VStack(spacing: 16) {
                                taskActionRow(for: currentDailyTask)

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
                                                .onTapGesture {
                                                    planViewModel.toggleWorkoutCompletion(workout)
                                                    refreshPlanInsights()
                                                }
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
                            mealActionRow()
                            mealSummaryCard(meals: planViewModel.meals)

                            LazyVStack(spacing: 14) {
                                ForEach(planViewModel.meals) { meal in
                                    MealPlanCardView(meal: meal)
                                }
                            }
                        }
                    }
                }

                private func refreshPlanInsights() {
                    planViewModel.refreshInsights(weightMetrics: weightMetrics)
                }

                private func taskActionRow(for task: DailyTask) -> some View {
                    HStack(spacing: 12) {
                        if !task.workouts.isEmpty {
                            Button {
                                workoutContext = WorkoutLaunchContext(task: task, resumableState: nil)
                            } label: {
                                Label("开始训练", systemImage: "play.fill")
                                    .font(.footnote.weight(.bold))
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Button {
                            let newValue = !task.isCompleted
                            planViewModel.markTask(task, completed: newValue)
                            refreshPlanInsights()
                        } label: {
                            Label(task.isCompleted ? "撤销完成" : "标记完成", systemImage: task.isCompleted ? "arrow.uturn.left" : "checkmark.circle.fill")
                                .font(.footnote.weight(.bold))
                        }
                        .buttonStyle(.bordered)

                        Button {
                            planViewModel.toggleSkip(for: task)
                            refreshPlanInsights()
                        } label: {
                            Label(task.isSkipped ? "取消跳过" : "跳过今天", systemImage: "moon.zzz.fill")
                                .font(.footnote.weight(.bold))
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                }

                private func mealActionRow() -> some View {
                    HStack(spacing: 12) {
                        Button {
                            appState.selectedTab = 0
                            NotificationCenter.default.post(name: .showInputSheet, object: nil)
                        } label: {
                            Label("补记饮食", systemImage: "fork.knife")
                                .font(.footnote.weight(.bold))
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            appState.selectedTab = 2
                        } label: {
                            Label("查看营养建议", systemImage: "leaf.fill")
                                .font(.footnote.weight(.bold))
                        }
                        .buttonStyle(.bordered)
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

                private func workoutSectionSubtitle(for task: DailyTask?) -> String {
                    return "安排你的训练节奏"
                }

                private func workoutSummaryCard(for task: DailyTask) -> some View {
                    let workouts = task.workouts
                    let completedCount = workouts.filter { $0.isCompleted }.count
                    let totalCount = workouts.count
                    let remainingCount = max(totalCount - completedCount, 0)
                    let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
                    let nextWorkout = workouts.first { !$0.isCompleted } ?? workouts.first
                    let isTaskCompleted = task.isCompleted || remainingCount == 0

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
                            infoPill(
                                text: remainingCount == 0 ? "全部完成" : "待训练 \(remainingCount) 项",
                                systemImage: "bolt.fill",
                                foreground: .white,
                                background: .white
                            )
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

                                    if isTaskCompleted {
                                        summaryButton(for: task)
                                    } else {
                                        playButton(for: task)
                                    }
                                }
                            }
                        }
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

                private func playButton(for task: DailyTask) -> some View {
                    Button {
                        workoutContext = WorkoutLaunchContext(task: task, resumableState: nil)
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                            .padding(10)
                            .background(Color.white, in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                private func summaryButton(for task: DailyTask) -> some View {
                    Button {
                        appState.workoutSummary = (show: true, workouts: task.workouts)
                    } label: {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .padding(10)
                            .background(Color.white, in: Circle())
                            .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
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
                    let container = try! ModelContainer(for: Plan.self, HealthMetric.self, configurations: config)
                    
                    // Add some mock data if needed for the preview
                    let profileViewModel = ProfileViewModel()
                    let recommendationManager = RecommendationManager(profileViewModel: profileViewModel) // New
                    let context = container.mainContext

                    let goal = PlanGoal(
                        fitnessGoal: .fatLoss,
                        startWeight: 72.0,
                        targetWeight: 65.0,
                        startDate: Date().addingTimeInterval(-86400 * 7),
                        targetDate: Date().addingTimeInterval(86400 * 30)
                    )
                    let plan = Plan(name: "30天减脂计划", planGoal: goal, startDate: goal.startDate, duration: 30, tasks: [], status: "active")
                    context.insert(plan)
                    context.insert(HealthMetric(date: goal.startDate, value: goal.startWeight, type: .weight))
                    context.insert(HealthMetric(date: Date(), value: 69.5, type: .weight))
            
                    return PlanView(profileViewModel: profileViewModel, modelContext: container.mainContext)
                        .modelContainer(container) // Provide the container to the environment
                        .environmentObject(profileViewModel)
                        .environmentObject(recommendationManager) // New
                }
            }
