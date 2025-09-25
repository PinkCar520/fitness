import SwiftUI

struct DataPrivacySettingsView: View {
    var body: some View {
        Form {


            Link(destination: URL(string: "https://www.example.com/privacy")!) {
                HStack {
                    Text("隐私政策")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("数据与隐私")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataPrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DataPrivacySettingsView()
        }
    }
}
