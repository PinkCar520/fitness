import SwiftUI

struct SafetyCheckView: View {
    @Binding var healthConditions: [HealthCondition]?

    // Initialize with a non-nil array to work with bindings
    init(healthConditions: Binding<[HealthCondition]?>) {
        _healthConditions = Binding(get: { healthConditions.wrappedValue ?? [] }, set: { healthConditions.wrappedValue = $0 })
    }

    var body: some View {
        OnboardingStepView(
            title: "有无特殊身体状况？",
            subtitle: "为了您的安全，我们将根据您的选择，智能调整训练计划。"
        ) {
            VStack(spacing: 15) {
                // Condition options
                ForEach(HealthCondition.allCases) { condition in
                    ConditionRow(condition: condition, selectedConditions: Binding(
                        get: { healthConditions ?? [] },
                        set: { healthConditions = $0 }
                    ))
                }
                
                Divider().padding(.vertical)
                
                // "None" option
                NoneOptionRow(selectedConditions: Binding(
                    get: { healthConditions ?? [] },
                    set: { healthConditions = $0 }
                ))
            }
            .padding(.horizontal)
        }
    }
}

struct ConditionRow: View {
    let condition: HealthCondition
    @Binding var selectedConditions: [HealthCondition]

    private var isSelected: Bool {
        selectedConditions.contains(condition)
    }

    var body: some View {
        Button(action: {
            withAnimation {
                if isSelected {
                    selectedConditions.removeAll { $0 == condition }
                } else {
                    selectedConditions.append(condition)
                }
            }
        }) {
            HStack {
                Text(condition.rawValue)
                    .font(.headline)
                Spacer()
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title2)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NoneOptionRow: View {
    @Binding var selectedConditions: [HealthCondition]

    private var isNoneSelected: Bool {
        selectedConditions.isEmpty
    }

    var body: some View {
        Button(action: {
            withAnimation {
                selectedConditions.removeAll()
            }
        }) {
            HStack {
                Text("无，一切正常")
                    .font(.headline)
                    .fontWeight(isNoneSelected ? .bold : .regular)
                Spacer()
                Image(systemName: isNoneSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isNoneSelected ? .accentColor : .secondary)
                    .font(.title2)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SafetyCheckView_Previews: PreviewProvider {
    static var previews: some View {
        SafetyCheckView(healthConditions: .constant([.kneeDiscomfort]))
    }
}
