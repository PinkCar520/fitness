
import SwiftUI

struct WorkoutLocationView: View {
    @Binding var workoutLocation: WorkoutLocation?

    var body: some View {
        OnboardingStepView(
            title: "您主要在哪里锻炼？",
            subtitle: "我们会推荐适合您选择的地点的锻炼。"
        ) {
            VStack(spacing: 15) {
                ForEach(WorkoutLocation.allCases) { location in
                    LocationCard(location: location, selectedLocation: $workoutLocation)
                }
            }
            .padding(.horizontal)
        }
    }
}


struct LocationCard: View {
    let location: WorkoutLocation
    @Binding var selectedLocation: WorkoutLocation?

    private var isSelected: Bool {
        location == selectedLocation
    }

    var body: some View {
        Button(action: {
            withAnimation {
                selectedLocation = location
            }
        }) {
            VStack {
                Image(imageName(for: location))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipped()
                
                Text(location.rawValue)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding()
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func imageName(for location: WorkoutLocation) -> String {
        switch location {
        case .home: return "onboarding_home"
        case .gym: return "onboarding_gym"
        }
    }
}

struct WorkoutLocationView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutLocationView(workoutLocation: .constant(.home))
    }
}
