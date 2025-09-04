import SwiftUI

struct GoalProgressView: View {
    @EnvironmentObject var weightManager: WeightManager
    @AppStorage("targetWeight") private var targetWeight: Double = 68.0

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("本周变化").font(.headline).foregroundStyle(.secondary)
                Text(weekChangeText)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("目标进度").font(.headline).foregroundStyle(.secondary)
                if let latest = weightManager.latestRecord?.weight {
                    Text(String(format: "%.1f/%.1fkg", latest, targetWeight))
                        .font(.system(size: 22, weight: .bold))
                    ProgressView(value: latest, total: max(targetWeight, latest))
                        .progressViewStyle(.linear)
                        .tint(.orange)
                } else {
                    Text("--/\(String(format: "%.1f", targetWeight))kg")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var weekChangeText: String {
        if let c = weightManager.weightChangeThisWeek() {
            return String(format: "%+.1fkg", c)
        }
        return "-- kg"
    }
}
