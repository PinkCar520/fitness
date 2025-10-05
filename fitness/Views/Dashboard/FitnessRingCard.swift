import SwiftUI
import HealthKit

struct RingValueRow: View {
    var color: Color
    var currentValue: Int
    var goalValue: Int
    var unit: String

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            HStack(spacing: 0) {
                Text("\(currentValue)")
                    .contentTransition(.numericText(countsDown: false))
                Text(" / \(goalValue) \(unit)")
            }
        }
    }
}

struct FitnessRingCard: View {
    let activitySummary: HKActivitySummary?

    private var moveGoal: Double {
        activitySummary?.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()) ?? 0
    }
    private var moveValue: Double {
        activitySummary?.activeEnergyBurned.doubleValue(for: .kilocalorie()) ?? 0
    }
    private var moveProgress: Double {
        (activitySummary != nil && moveGoal > 0) ? moveValue / moveGoal : 0
    }

    private var exerciseGoal: Double {
        activitySummary?.appleExerciseTimeGoal.doubleValue(for: .minute()) ?? 0
    }
    private var exerciseValue: Double {
        activitySummary?.appleExerciseTime.doubleValue(for: .minute()) ?? 0
    }
    private var exerciseProgress: Double {
        (activitySummary != nil && exerciseGoal > 0) ? exerciseValue / exerciseGoal : 0
    }

    private var standGoal: Double {
        activitySummary?.appleStandHoursGoal.doubleValue(for: .count()) ?? 0
    }
    private var standValue: Double {
        activitySummary?.appleStandHours.doubleValue(for: .count()) ?? 0
    }
    private var standProgress: Double {
        (activitySummary != nil && standGoal > 0) ? standValue / standGoal : 0
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                ZStack {
                    ActivityRingView(progress: moveProgress, color: .red, ringSize: 120)
                    ActivityRingView(progress: exerciseProgress, color: .green, ringSize: 90)
                    ActivityRingView(progress: standProgress, color: .blue, ringSize: 60)
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    RingValueRow(color: .red, currentValue: Int(moveValue), goalValue: Int(moveGoal), unit: "Kcal")
                    RingValueRow(color: .green, currentValue: Int(exerciseValue), goalValue: Int(exerciseGoal), unit: "Min")
                    RingValueRow(color: .blue, currentValue: Int(standValue), goalValue: Int(standGoal), unit: "Hour")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20).padding(.horizontal)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .animation(.easeInOut, value: moveValue)
        .animation(.easeInOut, value: exerciseValue)
        .animation(.easeInOut, value: standValue)
        .hapticOnChange(of: moveValue)
        .hapticOnChange(of: exerciseValue)
        .hapticOnChange(of: standValue)
    }
}

struct FitnessRingCard_Previews: PreviewProvider {
    static var previews: some View {
        FitnessRingCard(activitySummary: nil)
    }
}
