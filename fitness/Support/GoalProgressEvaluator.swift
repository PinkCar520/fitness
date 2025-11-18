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

struct WeeklyGoalProgressEvaluation {
    let direction: PlanGoal.WeightGoalDirection
    let status: GoalProgressEvaluation.Status
    let progress: Double
    let weekIndex: Int
    let totalWeeks: Int
    let weekStartDate: Date
    let weekEndDate: Date
    let plannedStartWeight: Double
    let plannedEndWeight: Double
    let plannedChange: Double
    let targetDeltaMagnitude: Double
    let actualStartWeight: Double
    let latestRecordWeight: Double
    let latestRecordDate: Date
    let hasRecordThisWeek: Bool
    let achievedDeltaMagnitude: Double
    let remainingDeltaMagnitude: Double
    let tolerance: Double

    var weekNumber: Int { weekIndex + 1 }
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

    static func evaluateWeekly(
        goal: PlanGoal,
        baselineWeight: Double?,
        metrics: [HealthMetric],
        referenceDate: Date = Date(),
        tolerance: Double = defaultTolerance
    ) -> WeeklyGoalProgressEvaluation? {
        guard !metrics.isEmpty else { return nil }

        let calendar = Calendar.current
        let baseline = baselineWeight ?? goal.startWeight
        let direction = goal.weightGoalDirection(baseline: baseline, tolerance: tolerance)
        let planStart = calendar.startOfDay(for: goal.startDate)
        let today = calendar.startOfDay(for: referenceDate)
        let targetEnd = resolvedTargetDate(for: goal, calendar: calendar)

        let durationDays = max(1, calendar.dateComponents([.day], from: planStart, to: targetEnd).day ?? 0)
        let totalWeeks = max(1, Int(ceil(Double(durationDays) / 7.0)))

        let elapsedDays = max(0, calendar.dateComponents([.day], from: planStart, to: today).day ?? 0)
        let currentWeekIndex = min(totalWeeks - 1, elapsedDays / 7)

        let weekStart = calendar.date(byAdding: .day, value: currentWeekIndex * 7, to: planStart) ?? planStart
        let rawWeekEnd = calendar.date(byAdding: .day, value: (currentWeekIndex + 1) * 7, to: planStart) ?? targetEnd
        let weekEnd = min(rawWeekEnd, targetEnd)

        let plannedChangePerWeek = (goal.targetWeight - baseline) / Double(totalWeeks)
        let roundingStep: Double = 0.1
        let roundingScale = 1 / roundingStep
        func roundedWeight(_ value: Double) -> Double {
            return (value * roundingScale).rounded() / roundingScale
        }

        var plannedStartWeight = baseline + Double(currentWeekIndex) * plannedChangePerWeek
        var plannedEndWeight = baseline + Double(currentWeekIndex + 1) * plannedChangePerWeek

        if currentWeekIndex == 0 {
            plannedStartWeight = baseline
        }
        if currentWeekIndex == totalWeeks - 1 {
            plannedEndWeight = goal.targetWeight
        }

        if direction == .maintain {
            plannedStartWeight = goal.targetWeight
            plannedEndWeight = goal.targetWeight
        } else {
            plannedStartWeight = roundedWeight(plannedStartWeight)
            plannedEndWeight = roundedWeight(plannedEndWeight)
        }
        if currentWeekIndex == 0 {
            plannedStartWeight = roundedWeight(baseline)
        }
        if currentWeekIndex == totalWeeks - 1 {
            plannedEndWeight = roundedWeight(goal.targetWeight)
        }

        let plannedChange = plannedEndWeight - plannedStartWeight
        let targetDeltaMagnitude = abs(plannedChange)

        let measurementCutoff = min(referenceDate, weekEnd)
        guard let latestMetric = metrics.last(where: { $0.date <= measurementCutoff }) ?? metrics.last else {
            return nil
        }

        let hasRecordThisWeek = latestMetric.date >= weekStart && latestMetric.date <= weekEnd
        let latestRecordWeight = latestMetric.value
        let latestRecordDate = latestMetric.date

        let recordedStartWeight = metrics.last(where: { $0.date <= weekStart })?.value ?? baseline
        let actualStartWeight = roundedWeight(recordedStartWeight)
        let referenceStartWeight = plannedStartWeight

        var achievedDeltaMagnitude: Double = 0
        var progress: Double = 0
        var status: GoalProgressEvaluation.Status = .notStarted
        var remainingDeltaMagnitude: Double = targetDeltaMagnitude

        switch direction {
        case .gain:
            if hasRecordThisWeek {
                let actualChange = latestRecordWeight - referenceStartWeight
                achievedDeltaMagnitude = max(0, actualChange)

                if targetDeltaMagnitude > 0 {
                    progress = min(max(achievedDeltaMagnitude / targetDeltaMagnitude, 0), 1)
                    remainingDeltaMagnitude = max(0, targetDeltaMagnitude - achievedDeltaMagnitude)
                } else {
                    progress = latestRecordWeight >= plannedEndWeight ? 1 : 0
                    remainingDeltaMagnitude = max(0, plannedEndWeight - latestRecordWeight)
                }

                if abs(latestRecordWeight - plannedEndWeight) <= tolerance {
                    status = .onTrack
                } else if latestRecordWeight > plannedEndWeight + tolerance {
                    status = .ahead
                } else if latestRecordWeight <= plannedStartWeight - tolerance {
                    status = .behind
                } else if progress <= 0.05 {
                    status = .notStarted
                } else {
                    status = .inProgress
                }
            } else {
                progress = 0
                achievedDeltaMagnitude = 0
                remainingDeltaMagnitude = targetDeltaMagnitude
                status = .notStarted
            }

        case .lose:
            if hasRecordThisWeek {
                let actualChange = referenceStartWeight - latestRecordWeight
                achievedDeltaMagnitude = max(0, actualChange)

                if targetDeltaMagnitude > 0 {
                    progress = min(max(achievedDeltaMagnitude / targetDeltaMagnitude, 0), 1)
                    remainingDeltaMagnitude = max(0, targetDeltaMagnitude - achievedDeltaMagnitude)
                } else {
                    progress = latestRecordWeight <= plannedEndWeight ? 1 : 0
                    remainingDeltaMagnitude = max(0, latestRecordWeight - plannedEndWeight)
                }

                if abs(latestRecordWeight - plannedEndWeight) <= tolerance {
                    status = .onTrack
                } else if latestRecordWeight < plannedEndWeight - tolerance {
                    status = .ahead
                } else if latestRecordWeight >= plannedStartWeight + tolerance {
                    status = .behind
                } else if progress <= 0.05 {
                    status = .notStarted
                } else {
                    status = .inProgress
                }
            } else {
                progress = 0
                achievedDeltaMagnitude = 0
                remainingDeltaMagnitude = targetDeltaMagnitude
                status = .notStarted
            }

        case .maintain:
            if hasRecordThisWeek {
                let distance = abs(latestRecordWeight - plannedEndWeight)
                progress = max(0, 1 - min(distance / tolerance, 1))
                achievedDeltaMagnitude = max(0, tolerance - distance)
                remainingDeltaMagnitude = max(0, distance - tolerance)

                if distance <= tolerance {
                    status = .onTrack
                } else if latestRecordWeight < plannedEndWeight - tolerance {
                    status = .ahead
                } else {
                    status = .behind
                }
            } else {
                progress = 0
                achievedDeltaMagnitude = 0
                remainingDeltaMagnitude = 0
                status = .notStarted
            }
        }

        return WeeklyGoalProgressEvaluation(
            direction: direction,
            status: status,
            progress: progress,
            weekIndex: currentWeekIndex,
            totalWeeks: totalWeeks,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            plannedStartWeight: plannedStartWeight,
            plannedEndWeight: plannedEndWeight,
            plannedChange: plannedChange,
            targetDeltaMagnitude: targetDeltaMagnitude,
            actualStartWeight: actualStartWeight,
            latestRecordWeight: latestRecordWeight,
            latestRecordDate: latestRecordDate,
            hasRecordThisWeek: hasRecordThisWeek,
            achievedDeltaMagnitude: achievedDeltaMagnitude,
            remainingDeltaMagnitude: remainingDeltaMagnitude,
            tolerance: tolerance
        )
    }

    private static func resolvedTargetDate(for goal: PlanGoal, calendar: Calendar) -> Date {
        if let targetDate = goal.targetDate {
            return calendar.startOfDay(for: targetDate)
        }
        let fallback = calendar.date(byAdding: .day, value: 28, to: goal.startDate) ?? goal.startDate
        return calendar.startOfDay(for: fallback)
    }
}
