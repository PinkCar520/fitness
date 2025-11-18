import SwiftUI
import SwiftData
import Foundation

// A wrapper to pass both the task and an optional resumable state to the sheet
struct WorkoutLaunchContext: Identifiable {
    var id: UUID { task.id }
    let task: DailyTask
    let resumableState: WorkoutSessionState?
}

private enum PlanTab {
    case workout, meal
}

struct PlanView: View {
    @StateObject private var planViewModel: PlanViewModel
    @State private var selectedDate: Date? = Calendar.current.startOfDay(for: Date())
    @State private var selectedPlanTab: PlanTab = .workout
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

    // Removed: weekly summary is now widget-only

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

    // Removed: weekly summary & insights sections (migrated to widget)

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


    private func goalSummaryCard(plan: Plan, goal: PlanGoal, startWeight: Double, currentWeight: Double, progress: Double) -> some View {
        let clampedProgress = max(0, min(1, progress))
        let isGoalComplete = clampedProgress >= 0.999
        let progressText = "\(Int(clampedProgress * 100))%"
        let headline = "\(goal.fitnessGoal.rawValue) · \(String(format: "%.1fkg", startWeight)) → \(String(format: "%.1fkg", goal.targetWeight))"
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

        let cardBackground = Color.white
        let accentColor = Color(red: 0.35, green: 0.58, blue: 0.92)
        let primaryText = Color(red: 0.12, green: 0.18, blue: 0.28)
        let secondaryText = primaryText.opacity(0.65)

        return VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(primaryText)
                    Text(headline)
                        .font(.footnote)
                        .foregroundStyle(secondaryText)
                    if let targetDate = goal.targetDate {
                        Text("目标截止 \(targetDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                }
                Spacer()
                ProgressRing(progress: clampedProgress, accentColor: accentColor, label: progressText)
            }

            HStack(spacing: 10) {
                statusBadge(
                    icon: statusIcon,
                    text: statusText,
                    foreground: accentColor,
                    background: accentColor.opacity(0.12)
                )
                if goal.isProfessionalMode {
                    professionalModeBadge()
                }
                Spacer()
                if let remainingDaysText {
                    Text(remainingDaysText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accentColor.opacity(0.12), in: Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                ProgressView(value: clampedProgress)
                    .progressViewStyle(.linear)
                    .tint(accentColor)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.08), in: Capsule())

                HStack(spacing: 16) {
                    metricBadge(icon: "figure.walk", title: "起点", value: startText, textColor: primaryText, accentColor: secondaryText)
                    metricBadge(icon: "scalemass.fill", title: "当前", value: currentText, textColor: primaryText, accentColor: secondaryText)
                    metricBadge(icon: "flag.checkered", title: "目标", value: targetText, textColor: primaryText, accentColor: secondaryText)
                }
            }

            HStack(spacing: 12) {
                infoChip(icon: trainingIcon, text: trainingText, textColor: primaryText, background: Color.white.opacity(0.08))
                infoChip(icon: mealIcon, text: mealText, textColor: primaryText, background: Color.white.opacity(0.08))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func metricBadge(icon: String, title: String, value: String, textColor: Color = .primary, accentColor: Color = .secondary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(accentColor)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusBadge(icon: String, text: String, foreground: Color = .white, background: Color = Color.white.opacity(0.18)) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(background, in: Capsule())
    }

    private func professionalModeBadge() -> some View {
        HStack(spacing: 6) {
            Image(systemName: "cross.case.fill")
                .font(.caption)
            Text("专业模式")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(Color.red)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.12), in: Capsule())
    }

    private func infoChip(icon: String, text: String, textColor: Color = .white, background: Color = Color.white.opacity(0.14)) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(background, in: Capsule())
    }

    private struct ProgressRing: View {
        let progress: Double
        let accentColor: Color
        let label: String

        private var clamped: Double {
            max(0, min(1, progress))
        }

        var body: some View {
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.06), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: clamped)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
            .frame(width: 68, height: 68)
            .padding(6)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            )
        }
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
            .background(Color(UIColor.systemGroupedBackground))
    }
}

@ViewBuilder
private var mainNavigationContent: some View {
    content
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showPlanHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Color.black)
                }

                Button {
                    showPlanSetup = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.black)
                }
            }
        }
        .toolbar(removing: .title)
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
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPlanDate)) { notif in
            if let date = notif.userInfo?["date"] as? Date {
                self.selectedDate = date
                self.planViewModel.selectedDate = date
            }
        }
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
        let refreshed = content
            .onAppear(perform: checkForResumableWorkout)

        return refreshed
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

    private func continueResumableWorkout() {
        if resumableTask != nil, resumableState != nil {
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
                    CalendarView(selectedDate: $selectedDate, completedDates: completedDates)
                        .onChange(of: selectedDate) { oldValue, newValue in
                            planViewModel.selectedDate = newValue ?? Date()
                        }

                    planGoalSummarySection

                    Picker("", selection: $selectedPlanTab) {
                        Text("今日锻炼").tag(PlanTab.workout)
                        Text("今日饮食").tag(PlanTab.meal)
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)
                    .glassEffect()

                    if selectedPlanTab == .workout {
                        workoutPlanSection
                    } else {
                        mealPlanSection
                    }
                }
                .padding()
            }
        }
    }
}

private var planSetupSheet: some View {
    PlanSetupView { config in
        await planViewModel.generatePlanAsync(config: config, recommendationManager: recommendationManager)
    }
    .presentationDetents([.fraction(0.9)])
    .presentationDragIndicator(.visible)
}

private func continueResumableWorkout() {
    if let task = resumableTask, let state = resumableState {
        self.workoutContext = WorkoutLaunchContext(task: task, resumableState: state)
    }
}
                
    private var workoutPlanSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let currentDailyTask = planViewModel.currentDailyTask {
                if currentDailyTask.isCompleted {
                    completedTrainingCard(for: currentDailyTask)
                    recoveryTipsSection
                } else {
                    taskActionRow(for: currentDailyTask)

                    if currentDailyTask.workouts.isEmpty {
                        restStateCard(
                            title: "休息日也很重要",
                            message: "调整状态、补充营养，为下一次训练打好基础。",
                            icon: "powerplug.fill"
                        )
                    } else {
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
                            planViewModel.toggleSkip(for: task)
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
                
                

                private func workoutSectionSubtitle(for task: DailyTask?) -> String {
                    return "安排你的训练节奏"
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
                    .background(Color(red: 0.99, green: 0.98, blue: 0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

                private func completedTrainingCard(for task: DailyTask) -> some View {
                    let metrics = completionMetrics(for: task)
                    return VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("今日训练完成 🎉")
                                    .font(.headline)
                                Text("用时 \(metrics.duration) 分 · 消耗 \(metrics.calories) 千卡")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "medal.fill")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                        }

                        Button {
                            appState.workoutSummary = (show: true, workouts: task.workouts)
                        } label: {
                            HStack {
                                Text("回顾训练记录")
                                Spacer()
                                Image(systemName: "arrow.forward.circle.fill")
                                    .font(.headline)
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                    )
                }

                private var recoveryTipsSection: some View {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("恢复提醒")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        VStack(spacing: 12) {
                            tipCard(
                                icon: "fork.knife",
                                title: "补充营养",
                                message: "训练后 30 分钟补充优质蛋白质和碳水，帮助修复与补水。",
                                buttonTitle: "记录饮食"
                            ) {
                                appState.selectedTab = 0
                                NotificationCenter.default.post(name: .showInputSheet, object: nil)
                            }
                            tipCard(
                                icon: "figure.cooldown",
                                title: "拉伸放松",
                                message: "花 5 分钟进行拉伸或泡沫轴放松，缓解肌肉酸痛。"
                            )
                        }
                    }
                }

                private func tipCard(icon: String, title: String, message: String, buttonTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.subheadline.weight(.semibold))
                                Text(message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let title = buttonTitle, let action {
                            Button(action: action) {
                                Text(title)
                                    .font(.caption.weight(.bold))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                }

                private func completionMetrics(for task: DailyTask) -> (duration: Int, calories: Int) {
                    let duration = task.workouts.reduce(0) { partial, workout in
                        if let minutes = workout.durationInMinutes {
                            return partial + minutes
                        } else if let seconds = workout.duration {
                            return partial + Int(seconds / 60)
                        }
                        return partial
                    }
                    let calories = task.workouts.reduce(0) { $0 + $1.caloriesBurned }
                    return (duration, calories)
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
