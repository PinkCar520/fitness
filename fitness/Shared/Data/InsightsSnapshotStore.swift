import Foundation

public struct InsightsSnapshot: Codable, Hashable {
    public let generatedAt: Date
    public let items: [InsightItem]

    public init(generatedAt: Date = Date(), items: [InsightItem]) {
        self.generatedAt = generatedAt
        self.items = items
    }
}

public final class InsightsSnapshotStore {
    private let suiteName: String
    private let key = "insights_snapshot_v1"

    public init(appGroup: String) {
        self.suiteName = appGroup
    }

    public func write(_ snapshot: InsightsSnapshot) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
        }
    }

    public func read() -> InsightsSnapshot? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(InsightsSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }
}

