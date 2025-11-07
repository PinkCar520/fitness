import SwiftUI
import SwiftData

struct GoalProgressView: View {
    @Query(sort: \HealthMetric.date) private var allMetrics: [HealthMetric] // Sort ascending to easily get first record
    @Query(filter: #Predicate<Plan> { $0.status == "active" }, sort: \.startDate, order: .reverse)
    private var activePlans: [Plan]

    private var planGoal: PlanGoal? {
        activePlans.first?.planGoal
    }

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    private var startWeight: Double? {
        guard let goal = planGoal else { return nil }
        return goal.resolvedStartWeight(from: weightMetrics)
    }

    private var currentWeightValue: Double? {
        weightMetrics.last?.value
    }

    private var currentWeightDisplay: String {
        guard let value = currentWeightValue else { return "--" }
        return String(format: "%.1f", value)
    }

    private var progressEvaluation: GoalProgressEvaluation? {
        guard
            let goal = planGoal,
            let baseline = startWeight
        else { return nil }
        return GoalProgressEvaluator.evaluate(goal: goal, baselineWeight: baseline, currentWeight: currentWeightValue)
    }

    private var progress: Double {
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

    private var targetLabelText: String {
        guard let goal = planGoal else { return "-- KG" }

        let direction = progressEvaluation?.direction ?? goal.weightGoalDirection(
            baseline: startWeight,
            tolerance: GoalProgressEvaluator.defaultTolerance
        )

        switch direction {
        case .maintain:
            return String(format: "%.1f KG ±%.1f KG", goal.targetWeight, GoalProgressEvaluator.defaultTolerance)
        case .gain, .lose:
            return String(format: "%.1f KG", goal.targetWeight)
        }
    }

    var body: some View {
        Group {
            if let goal = planGoal {
                let baseline = startWeight ?? goal.startWeight
                let startLabel = String(format: "%.1f KG", baseline)
                let targetLabel = targetLabelText

                VStack(alignment: .leading) {
                    Text("目标进度")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 5)

                    ZStack {
                        SemicircleShape()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                            .frame(height: 150)

                        SemicircleShape(progress: progress)
                            .trim(from: 0, to: progress)
                            .stroke(progressColor, lineWidth: 10)
                            .frame(height: 150)

                        VStack {
                            Text(currentWeightDisplay)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("KG")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .offset(y: -30)

                        Text(startLabel)
                            .font(.caption)
                            .offset(x: -70, y: 60)

                        Text(targetLabel)
                            .font(.caption)
                            .offset(x: 70, y: 60)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            } else {
                ContentUnavailableView("暂无计划", systemImage: "target")
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            }
        }
    }
}

struct SemicircleShape: Shape {
    var progress: Double = 1.0 // 0.0 to 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2
        let startAngle = Angle(degrees: 180)
        let endAngle = Angle(degrees: 0)

        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
}

struct GoalProgressView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, Plan.self, configurations: config)

        let context = container.mainContext
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        context.insert(HealthMetric(date: startDate, value: 72.0, type: .weight))
        context.insert(HealthMetric(date: Date(), value: 70.4, type: .weight))

        let goal = PlanGoal(
            fitnessGoal: .fatLoss,
            startWeight: 72.0,
            targetWeight: 68.0,
            startDate: startDate,
            targetDate: Calendar.current.date(byAdding: .day, value: 30, to: startDate)
        )
        let plan = Plan(name: "减脂计划", planGoal: goal, startDate: goal.startDate, duration: 30, tasks: [], status: "active")
        context.insert(plan)

        return GoalProgressView()
            .modelContainer(container)
            .frame(width: 350)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
