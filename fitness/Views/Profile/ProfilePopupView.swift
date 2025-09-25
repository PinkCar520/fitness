import SwiftUI
import PhotosUI

// A reusable view for each navigation row in the settings page
struct SettingsNavigationRow<Destination: View>: View {
    let title: String
    let systemImageName: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: systemImageName)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 30)
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
        }
    }
}

struct ProfilePopupView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?

    // Placeholder for navigation destinations
    private struct PlaceholderView: View {
        let title: String
        var body: some View { Text("\(title) Page").navigationTitle(title) }
    }
    
    // 1. Centered Profile Header View, designed to live inside a List
    private var profileHeader: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: profileViewModel.displayAvatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                    Image(systemName: "camera.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 28))
                        .foregroundColor(.accentColor)
                }
            }
            
            Text(profileViewModel.userProfile.name)
                .font(.title.bold())
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical)
        .onChange(of: selectedItem) { oldValue, newItem in
            profileViewModel.setAvatar(from: newItem)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Section 0: Visually independent header
                Section {
                    profileHeader
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Section 1: Profile & Health
                Section {
                    SettingsNavigationRow(title: "基本信息", systemImageName: "person.text.rectangle.fill", destination: BasicInfoSettingsView().environmentObject(profileViewModel))
                    SettingsNavigationRow(title: "健康与目标", systemImageName: "target", destination: HealthGoalsSettingsView().environmentObject(profileViewModel))
                    SettingsNavigationRow(title: "健身档案", systemImageName: "figure.run.circle.fill", destination: FitnessProfileDetailView().environmentObject(profileViewModel))
                }
                .listRowSeparator(.hidden)

                // Section 2: Core Settings
                Section {
                    SettingsNavigationRow(title: "外观", systemImageName: "paintbrush.fill", destination: AppearanceSettingsView())
                    SettingsNavigationRow(title: "通知", systemImageName: "bell.badge.fill", destination: NotificationSettingsView().environmentObject(profileViewModel))
                    SettingsNavigationRow(title: "数据与隐私", systemImageName: "hand.raised.fill", destination: DataPrivacySettingsView())
                }
                .listRowSeparator(.hidden)

                // Section 3: Support
                Section {
                    SettingsNavigationRow(title: "帮助与支持", systemImageName: "questionmark.circle.fill", destination: PlaceholderView(title: "帮助与支持"))
                    Link(destination: URL(string: "https://www.example.com/privacy")!) {
                        HStack(spacing: 16) {
                            Image(systemName: "lock.shield.fill").font(.title3).foregroundColor(.secondary).frame(width: 30)
                            Text("隐私政策").font(.body).foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square").foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    SettingsNavigationRow(title: "发送反馈", systemImageName: "paperplane.fill", destination: PlaceholderView(title: "发送反馈"))
                }
                .listRowSeparator(.hidden)
                
                // Section 4: Version Footer
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Text("Fitness Tracker")
                                .font(.subheadline)
                            Text("Version 2.1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("个人资料与设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成", action: { dismiss() })
                }
            }
        }
    }
}


