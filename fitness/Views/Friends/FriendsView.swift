import SwiftUI

struct FriendsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("好友成就系统")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                Text("这里将展示好友的最新动态和成就。")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .navigationTitle("好友动态")
        }
    }
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}
