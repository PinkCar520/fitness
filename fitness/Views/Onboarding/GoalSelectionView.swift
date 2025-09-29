import SwiftUI

struct GoalSelectionView: View {
    @Binding var goal: FitnessGoal?
    
    var body: some View {
        OnboardingStepView(
            title: "您的主要目标是？",
            subtitle: "选择一个目标，我们将为您量身定制计划。"
        ) {
            VStack(spacing: 15) {
                ForEach(FitnessGoal.allCases) { goalCase in
                    GoalCard(goal: goalCase, selectedGoal: $goal)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct GoalCard: View {
    let goal: FitnessGoal
    @Binding var selectedGoal: FitnessGoal?
    
    private var isSelected: Bool {
        goal == selectedGoal
    }
    
    var body: some View {
        Button(action: {
            withAnimation {
                selectedGoal = goal
            }
        }) {
            HStack {
                Image(systemName: icon(for: goal))
                    .font(.title)
                    .frame(width: 40)
                    .foregroundColor(
                        goal == .healthImprovement ? Color(red: 1.0, green: 0.23, blue: 0.35) : // Health Improvement is always pink
                        (goal == .fatLoss ? Color(red: 1.0, green: 0.55, blue: 0.0) : // Fat Loss is always orange
                        (goal == .muscleGain ? Color(red: 0.0, green: 0.47, blue: 1.0) : // Muscle Gain is always deep blue
                        (isSelected ? .accentColor : .primary)))
                    )
                Text(goal.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func icon(for goal: FitnessGoal) -> String {
        switch goal {
        case .fatLoss: return "flame.fill"
        case .muscleGain: return "figure.strengthtraining.traditional"
        case .healthImprovement: return "heart.fill"
        }
    }
}

struct GoalSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        GoalSelectionView(goal: .constant(.fatLoss))
    }
}