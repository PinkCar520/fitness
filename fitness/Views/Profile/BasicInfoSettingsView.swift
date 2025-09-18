import SwiftUI

struct BasicInfoSettingsView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var editingProfile: UserProfile

    // Custom initializer to prevent crash on first load
    init() {
        // This will be immediately replaced by onAppear, but ensures initialization is safe.
        _editingProfile = State(initialValue: UserProfile())
    }

    var body: some View {
        Form {
            // Section for Avatar
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(uiImage: profileViewModel.displayAvatar)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
                            .shadow(radius: 5)
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)

            // Section for Basic Info
            Section {
                HStack {
                    Text("昵称")
                    Spacer()
                    TextField("您的昵称", text: $editingProfile.name)
                        .multilineTextAlignment(.trailing)
                }
                
                Picker("性别", selection: $editingProfile.gender) {
                    ForEach(Gender.allCases) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                
                DatePicker("出生日期", selection: $editingProfile.dateOfBirth, displayedComponents: .date)
            }
        }
        .navigationTitle("基本信息")
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

struct BasicInfoSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BasicInfoSettingsView()
                .environmentObject(ProfileViewModel())
        }
    }
}
