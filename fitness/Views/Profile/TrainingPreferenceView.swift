import SwiftUI

struct TrainingPreferenceView: View {
    @Binding var profile: UserProfile

    var body: some View {
        Form {
            Section(header: Text("你对哪些活动感兴趣？"), footer: Text("选择你喜欢的，我们会优先安排这些活动。")) {
                // Use a direct binding to the profile's interests, ensuring it's not nil
                ForEach(Interest.allCases) { interest in
                    InterestToggleRow(interest: interest, selectedInterests: Binding(
                        get: { profile.interests ?? [] },
                        set: { profile.interests = $0 }
                    ))
                }
            }

            Section(header: Text("计划每周锻炼几天？")) {
                Picker("频率", selection: Binding(
                    get: { profile.workoutFrequency ?? .threeToFour },
                    set: { profile.workoutFrequency = $0 }
                )) {
                    ForEach(WorkoutFrequency.allCases) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle("训练偏好")
    }
}

struct InterestToggleRow: View {
    let interest: Interest
    @Binding var selectedInterests: [Interest]

    private var isSelected: Bool {
        selectedInterests.contains(interest)
    }

    var body: some View {
        Button(action: {
            withAnimation {
                if isSelected {
                    selectedInterests.removeAll { $0 == interest }
                } else {
                    selectedInterests.append(interest)
                }
            }
        }) {
            HStack {
                Text(interest.rawValue)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

struct TrainingPreferenceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TrainingPreferenceView(profile: .constant(UserProfile()))
        }
    }
}
