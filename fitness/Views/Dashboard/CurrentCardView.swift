
import SwiftUI

struct CurrentCardView: View {
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Binding var showInputSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("最新体重")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: { showInputSheet = true }) {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue.gradient)
                        .clipShape(Circle())
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(latestWeightValue)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("公斤")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            }

            Text(latestDateText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var latestWeightValue: String {
        if let hw = healthKitManager.lastReadWeight {
            return String(format: "%.1f", hw)
        } else if let w = weightManager.latestRecord?.weight {
            return String(format: "%.1f", w)
        } else {
            return "--"
        }
    }

    private var latestWeightText: String {
        if let hw = healthKitManager.lastReadWeight {
            return String(format: "%.1fkg", hw)
        } else if let w = weightManager.latestRecord?.weight {
            return String(format: "%.1fkg", w)
        } else {
            return "-- kg"
        }
    }

    private var latestDateText: String {
        (weightManager.latestRecord?.date ?? Date()).yyyyMMddHHmm
    }
}
