import Foundation

public struct InsightsEngine {
    public struct Context {
        public struct TaskContext {
            public let isSkipped: Bool
            public let totalWorkouts: Int
            public let completedWorkouts: Int
            public let totalMeals: Int
            public let pendingMeals: Int

            public init(
                isSkipped: Bool,
                totalWorkouts: Int,
                completedWorkouts: Int,
                totalMeals: Int,
                pendingMeals: Int
            ) {
                self.isSkipped = isSkipped
                self.totalWorkouts = max(totalWorkouts, 0)
                self.completedWorkouts = max(min(completedWorkouts, totalWorkouts), 0)
                self.totalMeals = max(totalMeals, 0)
                self.pendingMeals = max(min(pendingMeals, totalMeals), 0)
            }

            public var hasWorkouts: Bool { totalWorkouts > 0 }
            public var hasAllMealsPending: Bool { totalMeals > 0 && pendingMeals == totalMeals }
        }

        public let hasActivePlan: Bool
        public let task: TaskContext?
        public let shouldPromptForMissingTask: Bool
        public let weightMetrics: [WeightMetric]
        public let now: Date

        public init(
            hasActivePlan: Bool,
            task: TaskContext?,
            shouldPromptForMissingTask: Bool = false,
            weightMetrics: [WeightMetric],
            now: Date = Date()
        ) {
            self.hasActivePlan = hasActivePlan
            self.task = task
            self.shouldPromptForMissingTask = shouldPromptForMissingTask
            self.weightMetrics = weightMetrics
            self.now = now
        }
    }

    public struct WeightMetric: Codable, Hashable {
        public let date: Date
        public let value: Double
        public init(date: Date, value: Double) {
            self.date = date
            self.value = value
        }
    }

    public static func generate(from context: Context) -> [InsightItem] {
        var items: [InsightItem] = []

        if context.hasActivePlan == false {
            items.append(
                InsightItem(
                    title: "还没有训练计划",
                    message: "立即制定个人目标，系统会生成本周训练与饮食安排。",
                    tone: .informational,
                    intent: .openPlan
                )
            )
        } else {
            if let task = context.task {
                items.append(contentsOf: taskInsights(from: task))
            } else if context.shouldPromptForMissingTask {
                items.append(
                    InsightItem(
                        title: "选择训练日期",
                        message: "在日历中选择一个日期查看训练详情，保持每周的节奏。",
                        tone: .informational,
                        intent: .openPlan
                    )
                )
            }
        }

        if let trend = weightTrendInsight(from: context.weightMetrics) {
            items.append(trend)
        }

        return items
    }

    private static func taskInsights(from task: Context.TaskContext) -> [InsightItem] {
        var items: [InsightItem] = []

        if task.isSkipped {
            items.append(
                InsightItem(
                    title: "今日任务已跳过",
                    message: "如果状态恢复不错，可以重新安排轻量训练或进行伸展恢复。",
                    tone: .warning,
                    intent: .startWorkout
                )
            )
        } else if task.hasWorkouts == false {
            items.append(
                InsightItem(
                    title: "今日是休息日",
                    message: "休息同样重要，保持充足睡眠与营养补给，为下一次训练做好准备。",
                    tone: .positive,
                    intent: .none
                )
            )
        } else if task.completedWorkouts < task.totalWorkouts {
            items.append(
                InsightItem(
                    title: "今日训练待完成",
                    message: "完成今日 \(task.totalWorkouts) 项训练，保持连续性让成果更稳固。",
                    tone: .informational,
                    intent: .startWorkout
                )
            )
        }

        if task.hasAllMealsPending {
            items.append(
                InsightItem(
                    title: "别忘了记录饮食",
                    message: "完成餐食计划有助于维持能量均衡，及时补记今天的饮食安排。",
                    tone: .informational,
                    intent: .reviewMeals
                )
            )
        }

        return items
    }

    private static func weightTrendInsight(from metrics: [WeightMetric]) -> InsightItem? {
        let sorted = metrics.sorted { $0.date < $1.date }
        guard let latest = sorted.last else { return nil }

        let cal = Calendar.current
        let oneWeekAgo = cal.date(byAdding: .day, value: -7, to: latest.date) ?? latest.date
        let baseline = sorted.last(where: { $0.date <= oneWeekAgo }) ?? sorted.dropLast().last

        guard let comparison = baseline else { return nil }
        let delta = latest.value - comparison.value
        if abs(delta) < 0.3 { return nil }

        if delta > 0 {
            return InsightItem(
                title: "体重上升提醒",
                message: "比一周前增加了 \(String(format: "%.1f", delta)) kg，调整饮食结构或增加低强度运动。",
                tone: .warning,
                intent: .openBodyProfileWeight
            )
        } else {
            return InsightItem(
                title: "体重在下降",
                message: "较一周前下降 \(String(format: "%.1f", abs(delta))) kg，保持充足睡眠帮助恢复。",
                tone: .positive,
                intent: .openBodyProfileWeight
            )
        }
    }
}
