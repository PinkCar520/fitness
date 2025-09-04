
import SwiftUI

struct ProfilePopupView: View {
    var body: some View {
        VStack(spacing: 22) {
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable().frame(width: 60, height: 60)
                VStack(alignment: .leading) {
                    Text("User Name").font(.title2).bold()
                    Text("user@email.com").foregroundStyle(.secondary)
                }
                Spacer()
            }
            Divider()
            HStack(spacing: 24) {
                Label("Favorites", systemImage: "star.fill")
                Label("Settings", systemImage: "gearshape.fill")
                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }
}
