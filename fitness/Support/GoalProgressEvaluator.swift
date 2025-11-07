import Foundation

struct GoalProgressEvaluation {
    enum Status {
        case notStarted
        case inProgress
        case onTrack
        case ahead
        case behind
    }

    let direction: PlanGoal.WeightGoalDirection
    let status: Status
    let progress: Double
    let baseline: Double
    let current: Double
    let target: Double
    let tolerance: Double

    var deltaToTarget: Double {
        current - target
    }

    var deltaFromBaseline: Double {
        current - baseline
    }

    var isCompleted: Bool {
        switch direction {
        case .maintain:
            return status == .onTrack
        case .gain, .lose:
            return status == .onTrack || status == .ahead
        }
    }
}

enum GoalProgressEvaluator {
    static let defaultTolerance: Double = 0.5

    static func evaluate(goal: PlanGoal, baselineWeight: Double?, currentWeight: Double?, tolerance: Double = defaultTolerance) -> GoalProgressEvaluation? {
        guard let currentWeight else { return nil }

        let baseline = baselineWeight ?? goal.startWeight
        let direction = goal.weightGoalDirection(baseline: baseline, tolerance: tolerance)
        let target = goal.targetWeight

        let rawProgress: Double
        let status: GoalProgressEvaluation.Status

        switch direction {
        case .gain:
            let totalChange = target - baseline

            if totalChange <= 0.0001 {
                rawProgress = currentWeight >= target ? 1.0 : 0.0
                if abs(currentWeight - target) <= tolerance {
                    status = .onTrack
                } else if currentWeight > target + tolerance {
                    status = .ahead
                } else if currentWeight <= baseline - tolerance {
                    status = .behind
                } else {
                    status = .inProgress
                }
            } else {
                rawProgress = (currentWeight - baseline) / totalChange

                if currentWeight >= target - tolerance && currentWeight <= target + tolerance {
                    status = .onTrack
                } else if currentWeight > target + tolerance {
                    status = .ahead
                } else if currentWeight <= baseline - tolerance {
                    status = .behind
                } else if rawProgress <= 0.01 {
                    status = .notStarted
                } else {
                    status = .inProgress
                }
            }

        case .lose:
            let totalChange = baseline - target

            if totalChange <= 0.0001 {
                rawProgress = currentWeight <= target ? 1.0 : 0.0
                if abs(currentWeight - target) <= tolerance {
                    status = .onTrack
                } else if currentWeight < target - tolerance {
                    status = .ahead
                } else if currentWeight >= baseline + tolerance {
                    status = .behind
                } else {
                    status = .inProgress
                }
            } else {
                rawProgress = (baseline - currentWeight) / totalChange

                if currentWeight <= target + tolerance && currentWeight >= target - tolerance {
                    status = .onTrack
                } else if currentWeight < target - tolerance {
                    status = .ahead
                } else if currentWeight >= baseline + tolerance {
                    status = .behind
                } else if rawProgress <= 0.01 {
                    status = .notStarted
                } else {
                    status = .inProgress
                }
            }

        case .maintain:
            let distance = abs(currentWeight - target)
            rawProgress = 1 - min(distance / tolerance, 1)

            if distance <= tolerance {
                status = .onTrack
            } else if currentWeight < target - tolerance {
                status = .ahead
            } else {
                status = .behind
            }
        }

        let clampedProgress = max(0, min(1, rawProgress))

        return GoalProgressEvaluation(
            direction: direction,
            status: status,
            progress: clampedProgress,
            baseline: baseline,
            current: currentWeight,
            target: target,
            tolerance: tolerance
        )
    }
}
