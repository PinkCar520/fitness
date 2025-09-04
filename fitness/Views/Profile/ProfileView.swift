import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "person.crop.circle")
                .resizable().frame(width: 80, height: 80)
            Text("Profile").font(.largeTitle).padding(.top, 12)
            Spacer()
        }
    }
}
