import SwiftUI

struct GoalSelectionView: View {
    @Binding var goal: FitnessGoal?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("您的主要目标是？")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            ForEach(FitnessGoal.allCases) { goalCase in
                GoalCard(goal: goalCase, selectedGoal: $goal)
            }
            
            Spacer()
        }
        .padding()
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
                Text(goal.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
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
