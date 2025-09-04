
import SwiftUI

struct StatsView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "chart.bar.fill").resizable().frame(width: 80, height: 80)
            Text("Statistics").font(.largeTitle).padding(.top, 12)
            Spacer()
        }
    }
}
