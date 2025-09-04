import SwiftUI

struct InputSheetView: View {
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss

    @State private var weightText: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight").font(.headline)
                    HStack(spacing: 8) {
                        TextField("67.2", text: $weightText)
                            .keyboardType(.decimalPad)
                            .focused($focused)
                            .font(.system(size: 32, weight: .medium))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                        Text("kg").font(.title2).foregroundStyle(.secondary)
                    }
                    if let w = weightValue, !isValid(w) {
//                        Text("体重 \(String(format: \"%.1f\", w))kg 不在有效范围 30~200kg")
//                            .foregroundColor(.red).font(.footnote)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Date").font(.headline)
                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Note (Optional)").font(.headline)
                    TextField("Add a note...", text: $note)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                }

                Spacer()

                Button(action: save) {
                    Text("Save").frame(maxWidth: .infinity).padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!(weightValue.flatMap(isValid) ?? false))
            }
            .padding(20)
            .navigationTitle("Add Entry")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
        }
        .onAppear { focused = true }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var weightValue: Double? {
        Double(weightText.replacingOccurrences(of: ",", with: "."))
    }
    private func isValid(_ w: Double) -> Bool { (30...200).contains(w) }

    private func save() {
        guard let value = weightValue, isValid(value) else { return }
        weightManager.add(weight: value, date: date, note: note)
        healthKitManager.saveWeight(value, date: date)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}
