import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var editingProfile: UserProfile

    init() {
        _editingProfile = State(initialValue: ProfileViewModel().userProfile)
    }

    var body: some View {
        Form {
            Toggle("训练提醒", isOn: $editingProfile.trainingReminder)
            Toggle("记录提醒", isOn: $editingProfile.recordingReminder)
            Toggle("休息日提醒", isOn: $editingProfile.restDayReminder)
        }
        .navigationTitle("通知设置")
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

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotificationSettingsView()
                .environmentObject(ProfileViewModel())
        }
    }
}
