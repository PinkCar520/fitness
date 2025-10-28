import SwiftUI

extension WorkoutType {
    var displayName: String {
        switch self {
        case .strength:
            return "力量"
        case .cardio:
            return "有氧"
        case .flexibility:
            return "柔韧"
        case .other:
            return "其他"
        }
    }

    var symbolName: String {
        switch self {
        case .strength:
            return "dumbbell.fill"
        case .cardio:
            return "waveform.path.ecg"
        case .flexibility:
            return "figure.mind.and.body"
        case .other:
            return "sparkles"
        }
    }

    var tintColor: Color {
        switch self {
        case .strength:
            return .orange
        case .cardio:
            return .red
        case .flexibility:
            return .teal
        case .other:
            return .purple
        }
    }
}
