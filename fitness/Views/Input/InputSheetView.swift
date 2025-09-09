import SwiftUI

struct InputSheetView: View {
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentWeight: Double?
    @State private var date: Date = Date()
    @FocusState private var focused: Bool

    var baseWeight: Double {
        if let sample = healthKitManager.lastWeightSample {
            return sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        }
        return weightManager.latestRecord?.weight ?? 70.0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("体重").font(.headline)
                        WeightSlider(weight: $currentWeight, initialWeight: baseWeight)
                        if !isValid(currentWeight) {
                            Text("体重必须在30到200公斤之间。")
                                .foregroundColor(.red).font(.footnote)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("日期").font(.headline)
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: save) {
                        Text("保存").frame(maxWidth: .infinity).padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid(currentWeight))
                    .padding(.top)
                }
                .padding(.horizontal)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear { // 添加 onAppear
            healthKitManager.readMostRecentWeight() // 从 HealthKit 读取最新体重
            // 优先使用 HealthKit 的数据，其次是本地数据，最后是默认值
            currentWeight = baseWeight
        }
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }

    private func isValid(_ w: Double?) -> Bool { // 修改 isValid 接受 Optional<Double>
        guard let weightValue = w else { return false } // 如果是 nil，则认为无效（或者根据需求处理“关”状态）
        return (30...200).contains(weightValue)
    }

    private func save() {
        // 只有当 currentWeight 有值且有效时才保存
        guard let weightToSave = currentWeight, isValid(weightToSave) else {
            // 如果 currentWeight 为 nil (关) 或者无效，则不保存，直接 dismiss
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
            return
        }
        weightManager.add(weight: weightToSave, date: date)
        healthKitManager.saveWeight(weightToSave, date: date)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}
