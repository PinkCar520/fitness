import SwiftUI

struct ExperienceLevelView: View {
    @Binding var experienceLevel: ExperienceLevel?

    var body: some View {
        OnboardingStepView(
            title: "您的健身经验？",
            subtitle: "这将帮助我们调整计划的难度。"
        ) {
            VStack(spacing: 15) {
                ForEach(ExperienceLevel.allCases) { level in
                    ExperienceCard(level: level, selectedLevel: $experienceLevel)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ExperienceCard: View {
    let level: ExperienceLevel
    @Binding var selectedLevel: ExperienceLevel?

    private var isSelected: Bool {
        level == selectedLevel
    }

    var body: some View {
        Button(action: {
            withAnimation {
                selectedLevel = level
            }
        }) {
            HStack {
                Text(level.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExperienceLevelView_Previews: PreviewProvider {
    static var previews: some View {
        ExperienceLevelView(experienceLevel: .constant(.beginner))
    }
}