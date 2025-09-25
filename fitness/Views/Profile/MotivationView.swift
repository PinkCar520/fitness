import SwiftUI

struct MotivationView: View {
    @Binding var profile: UserProfile

    var body: some View {
        Form {
            Section(header: Text("什么最能激励你？"), footer: Text("了解你的内在驱动力，可以帮助我们更好地鼓励你。")) {
                ForEach(Motivator.allCases) { motivator in
                    MultiSelectRow(item: motivator, selectedItems: Binding(
                        get: { profile.motivators ?? [] },
                        set: { profile.motivators = $0 }
                    ))
                }
            }

            Section(header: Text("坚持锻炼最大的挑战是？"), footer: Text("告诉我们你遇到的困难，我们一起克服它。")) {
                ForEach(Challenge.allCases) { challenge in
                    MultiSelectRow(item: challenge, selectedItems: Binding(
                        get: { profile.challenges ?? [] },
                        set: { profile.challenges = $0 }
                    ))
                }
            }
        }
        .navigationTitle("动机与挑战")
    }
}

struct MotivationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MotivationView(profile: .constant(UserProfile()))
        }
    }
}
