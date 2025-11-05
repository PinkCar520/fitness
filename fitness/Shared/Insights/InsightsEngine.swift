import Foundation

public struct InsightsEngine {
    public struct Context {
        public let hasActivePlan: Bool
        public let todaysHasWorkouts: Bool?
        public let todaysCompletedWorkoutsCount: Int?
        public let weightMetrics: [WeightMetric]
        public let now: Date

        public init(
            hasActivePlan: Bool,
            todaysHasWorkouts: Bool?,
            todaysCompletedWorkoutsCount: Int?,
            weightMetrics: [WeightMetric],
            now: Date = Date()
        ) {
            self.hasActivePlan = hasActivePlan
            self.todaysHasWorkouts = todaysHasWorkouts
            self.todaysCompletedWorkoutsCount = todaysCompletedWorkoutsCount
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
                    title: "制定专属计划",
                    message: "系统可以根据体重与目标生成个性化训练安排，马上体验。",
                    tone: .informational,
                    intent: .openPlan
                )
            )
        } else {
            if let hasWorkouts = context.todaysHasWorkouts {
                if hasWorkouts == false {
                    items.append(
                        InsightItem(
                            title: "休息日提示",
                            message: "善用休息日调整状态，保持足够的睡眠与营养摄入。",
                            tone: .positive,
                            intent: .none
                        )
                    )
                } else {
                    let completed = context.todaysCompletedWorkoutsCount ?? 0
                    if completed == 0 {
                        items.append(
                            InsightItem(
                                title: "今日训练待完成",
                                message: "保持专注，完成今日计划可以巩固训练习惯。",
                                tone: .warning,
                                intent: .startWorkout
                            )
                        )
                    }
                }
            } else {
                items.append(
                    InsightItem(
                        title: "选择一个训练日",
                        message: "在计划页选择日期，可查看当天的训练与饮食安排。",
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
                title: "体重略有上升",
                message: "与一周前相比上升了 \(String(format: "%.1f", delta)) kg，保持饮食节奏并适度增加活动量。",
                tone: .warning,
                intent: .openBodyProfileWeight
            )
        } else {
            return InsightItem(
                title: "体重在下降",
                message: "较一周前下降 \(String(format: "%.1f", abs(delta))) kg，记得补充优质蛋白与充足睡眠。",
                tone: .positive,
                intent: .openBodyProfileWeight
            )
        }
    }
}

