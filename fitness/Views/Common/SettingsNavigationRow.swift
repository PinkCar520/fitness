import SwiftUI

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
