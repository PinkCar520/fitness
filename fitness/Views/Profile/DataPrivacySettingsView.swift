import SwiftUI

struct DataPrivacySettingsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        Form {
            Section("HealthKit 授权") {
                Button(action: {
                    openUrl(urlString: "x-apple-health://")
                }) {
                    HStack {
                        Text("前往健康 App 管理权限")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.accentColor)
                }
                Text("您可以在 iOS 健康 App 中管理本应用对健康数据的读写权限。点击上方按钮可快速跳转。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)

                ForEach(HealthKitDataTypeOption.allCases) { dataType in
                    HStack {
                        Text(dataType.title)
                        Spacer()
                        if healthKitManager.getPublishedAuthorizationStatus(for: dataType) == .sharingAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if healthKitManager.getPublishedAuthorizationStatus(for: dataType) == .sharingDenied {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        } else { // .notDetermined
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .onAppear {
            healthKitManager.updateAuthorizationStatuses()
        }
        .navigationTitle("数据与隐私")
        .navigationBarTitleDisplayMode(.inline)
    }

    func openUrl(urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    struct DataPrivacySettingsView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationStack {
                DataPrivacySettingsView()
                    .environmentObject(HealthKitManager())
            }
        }
    }
}
