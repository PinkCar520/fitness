import SwiftUI

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var showingProfilePopup = false

    var body: some View {
        NavigationStack {
            List {
                // Section for basic profile info
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(uiImage: profileViewModel.displayAvatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            
                            Text(profileViewModel.userProfile.name)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    Button("编辑基础信息") { 
                        showingProfilePopup = true
                    }
                }

                // Section for the new Progressive Onboarding modules
                Section(header: Text("健身档案")) {
                    NavigationLink(destination: FitnessProfileDetailView()) {
                        HStack {
                            Image(systemName: "figure.run.circle.fill")
                                .foregroundColor(.green)
                            Text("训练偏好与设备")
                        }
                    }
                    // Future modules can be added here
                }
                
                // Section for App Settings
                Section(header: Text("设置")) {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(.purple)
                            Text("外观设置")
                        }
                    }
                    // Other settings can be added here
                }
            }
            .navigationTitle("个人中心")
            .sheet(isPresented: $showingProfilePopup) {
                // Pass the view model to the popup
                ProfilePopupView()
                    .environmentObject(profileViewModel)
            }
        }
    }
}

