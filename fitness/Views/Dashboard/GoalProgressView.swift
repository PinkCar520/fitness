import SwiftUI
import SwiftData

struct GoalProgressView: View {
    @Query(sort: \HealthMetric.date) private var allMetrics: [HealthMetric] // Sort ascending to easily get first record
    @Query(filter: #Predicate<Plan> { $0.status == "active" }, sort: \.startDate, order: .reverse)
    private var activePlans: [Plan]

    private var planGoal: PlanGoal? {
        activePlans.first?.planGoal
    }

    private var targetWeight: Double? {
        planGoal?.targetWeight
    }

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    private var startWeight: Double? {
        guard let goal = planGoal else { return nil }
        return goal.resolvedStartWeight(from: weightMetrics)
    }

    private var currentWeight: Double {
        weightMetrics.last?.value ?? 0.0
    }

    private var startingWeight: Double {
        startWeight ?? weightMetrics.first?.value ?? 0.0
    }

    private var progress: Double {
        guard
            let goal = planGoal,
            let target = targetWeight,
            let baseline = startWeight
        else { return 0.0 }
        let delta = target - baseline
        guard delta != 0 else { return currentWeight == target ? 1.0 : 0.0 }
        let progress = (currentWeight - baseline) / delta
        return max(0, min(1, progress))
    }

    var body: some View {
        Group {
            if let goal = planGoal, let target = targetWeight {
                let baseline = startWeight ?? goal.startWeight
                let startLabel = String(format: "%.1f KG", baseline)
                let targetLabel = String(format: "%.1f KG", target)
                let progressColor: Color = currentWeight > target ? .orange : .green

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
                            .stroke(progressColor, lineWidth: 10)
                            .frame(height: 150)

                        VStack {
                            Text(String(format: "%.1f", currentWeight))
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
