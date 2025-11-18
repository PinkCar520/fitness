import Foundation

struct WeeklySummarySnapshotInput {
    let allTasks: [DailyTask]
    let referenceDate: Date
    init(allTasks: [DailyTask], referenceDate: Date = Date()) {
        self.allTasks = allTasks
        self.referenceDate = referenceDate
    }
}

struct WeeklySummaryResult: Equatable {
    let completionRate: Double
    let completedDays: Int
    let pendingDays: Int
    let skippedDays: Int
    let streakDays: Int
    let totalDays: Int
}

enum WeeklySummaryCalculator {
    static func calculate(_ input: WeeklySummarySnapshotInput) -> WeeklySummaryResult? {
        let calendar = Calendar.current
        let date = input.referenceDate
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? date

        let tasksThisWeek = input.allTasks.filter { t in
            t.date >= startOfWeek && t.date < endOfWeek
        }
        guard !tasksThisWeek.isEmpty else { return nil }

        let completed = tasksThisWeek.filter { $0.isCompleted }.count
        let skipped = tasksThisWeek.filter { $0.isSkipped }.count
        let pending = tasksThisWeek.count - completed - skipped
        let completionRate = Double(completed) / Double(tasksThisWeek.count)
        let streak = calculateStreak(allTasks: input.allTasks, upTo: date)

        return WeeklySummaryResult(
            completionRate: completionRate,
            completedDays: completed,
            pendingDays: max(pending, 0),
            skippedDays: skipped,
            streakDays: streak,
            totalDays: tasksThisWeek.count
        )
    }

    private static func calculateStreak(allTasks: [DailyTask], upTo date: Date) -> Int {
        let calendar = Calendar.current
        let tasksByDay = Dictionary(grouping: allTasks) { calendar.startOfDay(for: $0.date) }
        var streak = 0
        var day = calendar.startOfDay(for: date)
        while let tasks = tasksByDay[day], tasks.contains(where: { $0.isCompleted }) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }
}
