import SwiftUI

struct HealthGoalsSettingsView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var editingProfile: UserProfile

    init() {
        _editingProfile = State(initialValue: ProfileViewModel().userProfile)
    }

    var body: some View {
        Form {
            HStack {
                Text("身高")
                Spacer()
                TextField("身高", value: $editingProfile.height, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Picker("单位", selection: $editingProfile.heightUnit) {
                    ForEach(HeightUnit.allCases) { unit in Text(unit.rawValue).tag(unit) }
                }.pickerStyle(.segmented).frame(width: 100)
            }
            
            HStack {
                Text("目标体重")
                Spacer()
                TextField("目标体重", value: $editingProfile.targetWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Picker("单位", selection: $editingProfile.weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in Text(unit.rawValue).tag(unit) }
                }.pickerStyle(.segmented).frame(width: 100)
            }

            Picker("训练频率", selection: $editingProfile.workoutFrequency) {
                ForEach(WorkoutFrequency.allCases) { level in Text(level.rawValue).tag(level as WorkoutFrequency?) }
            }
        }
        .navigationTitle("健康与目标")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            self.editingProfile = profileViewModel.userProfile
        }
        .onDisappear {
            profileViewModel.userProfile = editingProfile
            profileViewModel.saveProfile()
        }
    }
}

struct HealthGoalsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HealthGoalsSettingsView()
                .environmentObject(ProfileViewModel())
        }
    }
}
