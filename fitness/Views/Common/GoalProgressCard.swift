import SwiftUI
import SwiftData

struct GoalProgressCard: View {
    @EnvironmentObject var appState: AppState

    @Binding var showInputSheet: Bool

    // Query to fetch weight metrics directly from SwiftData, sorted by date.
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]
    @Query(filter: #Predicate<Plan> { $0.status == "active" }, sort: \.startDate, order: .reverse)
    private var activePlans: [Plan]

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    private var latestWeightValueDouble: Double {
        weightMetrics.last?.value ?? 0.0
    }

    private var planGoal: PlanGoal? {
        activePlans.first?.planGoal
    }

    private var resolvedStartWeight: Double? {
        guard let goal = planGoal else { return nil }
        return goal.resolvedStartWeight(from: weightMetrics)
    }

    private var progressEvaluation: GoalProgressEvaluation? {
        guard
            let goal = planGoal,
            let baseline = resolvedStartWeight
        else { return nil }
        return GoalProgressEvaluator.evaluate(goal: goal, baselineWeight: baseline, currentWeight: weightMetrics.last?.value)
    }

    private var progressValue: Double {
        progressEvaluation?.progress ?? 0.0
    }

    private var progressColor: Color {
        guard let evaluation = progressEvaluation else {
            return Color.gray.opacity(0.35)
        }

        switch evaluation.status {
        case .onTrack:
            return .green
        case .ahead:
            return .orange
        case .behind:
            return .red
        case .inProgress:
            return .accentColor
        case .notStarted:
            return Color.gray.opacity(0.5)
        }
    }

    private var completionMessage: String {
        guard let evaluation = progressEvaluation else { return "恭喜你目标达成" }
        switch evaluation.direction {
        case .gain:
            return "已达成增重目标"
        case .lose:
            return "已达成减重目标"
        case .maintain:
            return "体重保持稳定"
        }
    }

    private var goalDirection: PlanGoal.WeightGoalDirection? {
        if let evaluation = progressEvaluation {
            return evaluation.direction
        }
        guard let goal = planGoal else { return nil }
        return goal.weightGoalDirection(
            baseline: resolvedStartWeight,
            tolerance: GoalProgressEvaluator.defaultTolerance
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            if planGoal == nil {
                noPlanState
            } else if weightMetrics.isEmpty {
                emptyState
            } else {
                populatedContent
            }
        }
        .padding(.vertical, 16)
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .animation(.easeInOut, value: latestWeightValueDouble)
        .hapticOnChange(of: latestWeightValueDouble)
    }

    private var populatedContent: some View {
        VStack(spacing: 16) {
            headerSection
            progressSection
        }
    }

    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text(latestWeightDisplay.whole)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(Color.primary.opacity(0.8))
                            if let fractional = latestWeightDisplay.fractional {
                                Text(".\(fractional)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.primary.opacity(0.8))
                            }
                        }
                        .contentTransition(.numericText(countsDown: false))
                        Text("kg")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(comparisonChange.change)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(comparisonChange.color)
                    Text(comparisonChange.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                appState.selectedTab = 2
            }
            Spacer()
            Button(action: { showInputSheet = true }) {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue.gradient)
                    .clipShape(Circle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            ZStack {
                SemicircleShape()
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, dash: [0, 12]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .frame(height: 100)

                SemicircleShape(progress: progressValue)
                    .trim(from: 0, to: progressValue)
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, dash: [0, 12]))
                    .foregroundStyle(progressColor)
                    .frame(height: 100)

                progressInnerContent
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                appState.selectedTab = 2
            }

            HStack {
                Text(startWeightLabel)
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .offset(x: 20)
                Spacer()
                Text(latestDateText)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
                Text(targetWeightLabel)
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .offset(x: -20)
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 80)
    }

    private var progressInnerContent: some View {
        Group {
            if let evaluation = progressEvaluation, evaluation.isCompleted {
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(progressColor)
                        .font(.title2)
                        .contentTransition(.numericText(countsDown: false))

                    Text(completionMessage)
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(progressColor)
                }
                .offset(y: 20)
            } else if progressValue > 0 {
                HStack(spacing: 0) {
                    Text("\(Int(progressValue * 100))")
                        .font(.system(size: 48))
                        .fontWeight(.bold)
                        .contentTransition(.numericText(countsDown: false))
                        .foregroundColor(.accentColor)
                    Text("%")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .offset(y: 10)
                }
                .offset(y: 20)
            } else {
                HStack(spacing: 0) {
                    Text("0")
                        .font(.system(size: 48))
                        .fontWeight(.bold)
                        .contentTransition(.numericText(countsDown: false))
                        .foregroundColor(.gray)
                    Text("%")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .offset(y: 10)
                }
                .offset(y: 20)
            }
        }
    }

    private var noPlanState: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("还没有训练目标")
                .font(.headline)
            Text("制定目标后，我们会根据计划追踪进度。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                appState.selectedTab = 1
            } label: {
                Text("去制定计划")
                    .font(.footnote.weight(.bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk.motion")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("还没有体重记录")
                .font(.headline)
            Text("记录首次体重后，我们会帮你追踪目标进度。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showInputSheet = true
            } label: {
                Text("马上记录")
                    .font(.footnote.weight(.bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var latestWeightDisplay: (whole: String, fractional: String?) {
        guard let value = weightMetrics.last?.value else {
            return ("--", nil)
        }
        let formatted = value.formatted(.number.precision(.fractionLength(1)))
        let parts = formatted.split(separator: ".")
        let whole = parts.first.map(String.init) ?? formatted
        let fractional = parts.count > 1 ? String(parts[1]) : nil
        return (whole, fractional)
    }

    private var startWeightLabel: String {
        if let start = resolvedStartWeight {
            return String(format: "%.1f kg", start)
        }
        return "--"
    }

    private var targetWeightLabel: String {
        guard let goal = planGoal else { return "--" }

        let direction = goalDirection ?? goal.weightGoalDirection(
            baseline: resolvedStartWeight,
            tolerance: GoalProgressEvaluator.defaultTolerance
        )

        switch direction {
        case .maintain:
            return String(format: "%.1f kg ±%.1f kg", goal.targetWeight, GoalProgressEvaluator.defaultTolerance)
        case .gain, .lose:
            return String(format: "%.1f kg", goal.targetWeight)
        }
    }

    private var latestDateText: String {
        if let record = weightMetrics.last {
            return "\(record.date.MMddHHmm)"
        }
        return "暂无记录"
    }

    private var comparisonChange: (change: String, color: Color, description: String) {
        guard weightMetrics.count >= 2 else { return ("--", .primary, "无历史数据对比") }

        let latest = weightMetrics.last!
        let previous = weightMetrics[weightMetrics.count - 2]
        let change = latest.value - previous.value
        let formattedChange: String

        let dayDifference = Calendar.current.dateComponents([.day], from: previous.date, to: latest.date).day ?? 0
        let description = dayDifference <= 1 ? "对比上次" : "对比\(dayDifference)天前"

        if abs(change) < 0.01 {
            formattedChange = "0.0 kg"
        } else if change > 0 {
            formattedChange = String(format: "+%.1f kg", change)
        } else {
            formattedChange = String(format: "%.1f kg", change)
        }

        guard let goal = planGoal else {
            return (formattedChange, .primary, description)
        }

        let direction = goalDirection ?? goal.weightGoalDirection(
            baseline: resolvedStartWeight,
            tolerance: GoalProgressEvaluator.defaultTolerance
        )

        let color: Color
        switch direction {
        case .gain:
            if abs(change) < 0.01 {
                color = .primary
            } else {
                color = change > 0 ? .green : .red
            }
        case .lose:
            if abs(change) < 0.01 {
                color = .primary
            } else {
                color = change < 0 ? .green : .red
            }
        case .maintain:
            if abs(change) < 0.01 {
                color = .primary
            } else {
                let latestDistance = abs(latest.value - goal.targetWeight)
                let previousDistance = abs(previous.value - goal.targetWeight)
                if latestDistance < previousDistance {
                    color = .green
                } else if latestDistance > previousDistance {
                    color = .orange
                } else {
                    color = .primary
                }
            }
        }

        return (formattedChange, color, description)
    }
}

struct GoalProgressCard_Previews: PreviewProvider {
    private static let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, Plan.self, configurations: config)

        let context = container.mainContext
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        context.insert(
            HealthMetric(
                date: startDate,
                value: 72.3,
                type: .weight
            )
        )
        context.insert(HealthMetric(date: Date(), value: 70, type: .weight))

        let planGoal = PlanGoal(
            fitnessGoal: .fatLoss,
            startWeight: 72.3,
            targetWeight: 68.0,
            startDate: startDate,
            targetDate: Calendar.current.date(byAdding: .day, value: 30, to: startDate)
        )
        let plan = Plan(name: "减脂计划", planGoal: planGoal, startDate: planGoal.startDate, duration: 30, tasks: [], status: "active")
        context.insert(plan)

        return container
    }()

    static var previews: some View {
        GoalProgressCard(showInputSheet: .constant(false))
            .modelContainer(previewContainer)
            .environmentObject(AppState())
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
