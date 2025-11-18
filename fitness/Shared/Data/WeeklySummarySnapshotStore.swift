import Foundation
// No SwiftUI needed here

public struct WeeklySummarySnapshot: Codable, Equatable {
    let completionRate: Double
    let completedDays: Int
    let pendingDays: Int
    let skippedDays: Int
    let streakDays: Int
    let totalDays: Int
    let updatedAt: Date
}

public final class WeeklySummarySnapshotStore {
    private let suiteName: String
    private let key = "weekly_summary_snapshot_v1"

    public init(appGroup: String) {
        self.suiteName = appGroup
    }

    public func save(_ snapshot: WeeklySummarySnapshot) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
        }
    }

    public func load() -> WeeklySummarySnapshot? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WeeklySummarySnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }
}
