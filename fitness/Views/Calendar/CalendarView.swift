
import SwiftUI

struct CalendarView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "calendar").resizable().frame(width: 80, height: 80)
            Text("Calendar").font(.largeTitle).padding(.top, 12)
            Spacer()
        }
    }
}
