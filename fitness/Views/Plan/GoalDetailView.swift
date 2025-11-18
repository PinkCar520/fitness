import SwiftUI
import SwiftData
import Charts

struct GoalDetailView: View {
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]
    @Query(sort: \Plan.startDate, order: .reverse) private var allPlans: [Plan]

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    private var activePlans: [Plan] {
        allPlans.filter { $0.status == "active" }
    }

    private var planGoal: PlanGoal? {
        activePlans.first?.planGoal
    }

    var body: some View {
        Group {
            if let goal = planGoal {
                goalDetailContent(for: goal)
            } else {
                ContentUnavailableView("暂无目标", systemImage: "target")
                    .padding()
            }
        }
        .navigationTitle("目标详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func goalDetailContent(for goal: PlanGoal) -> some View {
        let baseline = goal.resolvedStartWeight(from: weightMetrics)
        let currentWeight = weightMetrics.last?.value ?? baseline
        let delta = goal.targetWeight - baseline
        let rawProgress = delta == 0
            ? (currentWeight == goal.targetWeight ? 1.0 : 0.0)
            : (currentWeight - baseline) / delta
        let progress = max(0, min(1, rawProgress))
        let chartData = Array(weightMetrics.suffix(30))

        let targetText = String(format: "%.1f kg", goal.targetWeight)
        let startText = String(format: "%.1f kg", baseline)
        let progressText = "\(Int(progress * 100))%"

        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("目标详情")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                if goal.isProfessionalMode {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("专业模式已启用")
                                .font(.subheadline.weight(.bold))
                            Text("当前目标在医生/教练指导下放宽限制，若状态已改变，可返回计划设置关闭专业模式。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "target")
                            .font(.title)
                            .foregroundColor(.accentColor)
                        Text("\(goal.fitnessGoal.rawValue)：目标 \(targetText)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Text("从 \(startText) 开始，已完成 \(progressText)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)

                if !chartData.isEmpty {
                    VStack(alignment: .leading) {
                        Text("体重趋势")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        Chart(chartData) { record in
                            LineMark(
                                x: .value("日期", record.date),
                                y: .value("体重", record.value)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 200)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }

                VStack(alignment: .leading) {
                    Text("行动计划")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("每周锻炼5次，每次至少30分钟", systemImage: "figure.run")
                        Label("每日饮水2升", systemImage: "drop.fill")
                        Label("保持均衡饮食，减少高热量食物摄入", systemImage: "leaf.fill")
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.vertical)
        }
    }
}

struct GoalDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, Plan.self, configurations: config)
        
        let sampleData = [
            HealthMetric(date: Date().addingTimeInterval(-86400*6), value: 70.5, type: .weight),
            HealthMetric(date: Date().addingTimeInterval(-86400*1), value: 69.9, type: .weight),
            HealthMetric(date: Date(), value: 69.5, type: .weight),
        ]
        sampleData.forEach { container.mainContext.insert($0) }

        let planGoal = PlanGoal(
            fitnessGoal: .fatLoss,
            startWeight: 72.0,
            targetWeight: 65.0,
            startDate: Date().addingTimeInterval(-86400*7),
            targetDate: Date().addingTimeInterval(86400*30)
        )
        let plan = Plan(name: "30天减脂计划", planGoal: planGoal, startDate: planGoal.startDate, duration: 30, tasks: [], status: "active")
        container.mainContext.insert(plan)

        return NavigationView {
            GoalDetailView()
                .modelContainer(container)
        }
    }
}
