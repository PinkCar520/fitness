import Foundation

public struct InsightItem: Identifiable, Codable, Hashable {
    public enum Tone: String, Codable, Hashable {
        case informational
        case positive
        case warning
    }

    public enum Intent: String, Codable, Hashable {
        case startWorkout
        case logWeight
        case openPlan
        case openBodyProfileWeight
        case openStats
        case none
    }

    public let id: UUID
    public let title: String
    public let message: String
    public let tone: Tone
    public let intent: Intent

    public init(id: UUID = UUID(), title: String, message: String, tone: Tone, intent: Intent) {
        self.id = id
        self.title = title
        self.message = message
        self.tone = tone
        self.intent = intent
    }
}

