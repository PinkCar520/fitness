
import SwiftUI

struct RecentActivityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("最近活动")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "figure.run")
                    .foregroundStyle(.orange)
            }

            Text("跑步")
                .font(.title)
                .fontWeight(.bold)

            HStack {
                VStack(alignment: .leading) {
                    Text("距离")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("5.2 km")
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("时长")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("30 min")
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("日期")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("今天")
                        .font(.headline)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct RecentActivityCard_Previews: PreviewProvider {
    static var previews: some View {
        RecentActivityCard()
    }
}
