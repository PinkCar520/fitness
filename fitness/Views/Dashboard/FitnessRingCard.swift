
import SwiftUI
import HealthKit

struct FitnessRingCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("健身圆环")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 24) {
                ZStack {
                    if let summary = healthKitManager.activitySummary {
                        let moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
                        let moveProgress = moveGoal > 0 ? summary.activeEnergyBurned.doubleValue(for: .kilocalorie()) / moveGoal : 0

                        let exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())
                        let exerciseProgress = exerciseGoal > 0 ? summary.appleExerciseTime.doubleValue(for: .minute()) / exerciseGoal : 0

                        let standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())
                        let standProgress = standGoal > 0 ? summary.appleStandHours.doubleValue(for: .count()) / standGoal : 0

                        ActivityRingView(progress: moveProgress, color: .red, ringSize: 120)
                        ActivityRingView(progress: exerciseProgress, color: .green, ringSize: 90)
                        ActivityRingView(progress: standProgress, color: .blue, ringSize: 60)
                    } else {
                        Text("No Data")
                    }
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    if let summary = healthKitManager.activitySummary {
                        HStack {
                            Circle().fill(.red).frame(width: 10, height: 10)
                            Text("\(Int(summary.activeEnergyBurned.doubleValue(for: .kilocalorie()))) / \(Int(summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()))) Kcal")
                        }
                        HStack {
                            Circle().fill(.green).frame(width: 10, height: 10)
                            Text("\(Int(summary.appleExerciseTime.doubleValue(for: .minute()))) / \(Int(summary.appleExerciseTimeGoal.doubleValue(for: .minute()))) Min")
                        }
                        HStack {
                            Circle().fill(.blue).frame(width: 10, height: 10)
                            Text("\(Int(summary.appleStandHours.doubleValue(for: .count()))) / \(Int(summary.appleStandHoursGoal.doubleValue(for: .count()))) Hour")
                        }
                    } else {
                        Text("No Data")
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct FitnessRingCard_Previews: PreviewProvider {
    static var previews: some View {
        FitnessRingCard()
            .environmentObject(HealthKitManager())
    }
}
