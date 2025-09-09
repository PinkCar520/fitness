import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel // Inject ViewModel
    @State private var showingProfilePopup = false

    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "person.crop.circle")
                .resizable().frame(width: 80, height: 80)
            Text("Profile").font(.largeTitle).padding(.top, 12)
            
            Button("编辑个人资料") { // Button to open the popup
                showingProfilePopup = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .sheet(isPresented: $showingProfilePopup) {
            ProfilePopupView()
                .environmentObject(profileViewModel) // Pass the ViewModel to the sheet
        }
    }
}