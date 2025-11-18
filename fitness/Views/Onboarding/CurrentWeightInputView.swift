import SwiftUI

struct CurrentWeightInputView: View {
    @Binding var weight: Double?

    @State private var textValue: String
    @FocusState private var isFieldFocused: Bool

    private let minWeight: Double = 30
    private let maxWeight: Double = 200

    init(weight: Binding<Double?>) {
        self._weight = weight
        if let existing = weight.wrappedValue {
            _textValue = State(initialValue: CurrentWeightInputView.format(value: existing))
        } else {
            _textValue = State(initialValue: "")
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("记录当前体重")
                    .font(.title2.bold())
                Text("这是我们生成计划与追踪进度的基准数据，可随时在记录页更新。")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            inputCard

            Text("建议范围 \(Int(minWeight)) - \(Int(maxWeight)) kg，若有医生建议可优先遵循。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    isFieldFocused = false
                }
            }
        }
        .onChange(of: textValue) { _, newValue in
            onTextChanged(newValue)
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("请输入数字，精确到 0.1 kg")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                TextField("例如 60.0", text: $textValue)
                    .keyboardType(.decimalPad)
                    .focused($isFieldFocused)
                    .font(.system(size: 54, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .submitLabel(.done)
                    .contentTransition(.numericText())
                Text("kg")
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
            }

            Divider()
                .overlay(Color.white.opacity(0.3))

            Text("准确的起始体重有助于推荐更贴合的周目标。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
        )
//        .glassEffect()
    }

    private func onTextChanged(_ newValue: String) {
        let sanitized = sanitize(input: newValue)
        if sanitized != newValue {
            textValue = sanitized
            return
        }

        guard let value = Double(sanitized) else {
            if sanitized.isEmpty {
                weight = nil
            }
            return
        }
        let clamped = clamp(value)
        if abs(clamped - (weight ?? -999)) > 0.0001 {
            weight = clamped
        }
    }

    private func sanitize(input: String) -> String {
        var result = ""
        var hasDecimal = false
        for character in input {
            if character.isNumber {
                result.append(character)
            } else if character == "." && !hasDecimal {
                result.append(character)
                hasDecimal = true
            }
        }
        return result
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, minWeight), maxWeight)
    }

    private static func format(value: Double, decimals: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimals)f", value)
    }
}

struct CurrentWeightInputView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentWeightInputView(weight: .constant(62.5))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
