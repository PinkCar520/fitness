import SwiftUI

struct RecentActivityCard: View {
    @StateObject private var viewModel = RecentActivityViewModel()

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

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 80)
            } else if viewModel.workoutFound {
                // Content for when a workout is found
                Text(viewModel.activityName)
                    .font(.title)
                    .fontWeight(.bold)

                HStack {
                    VStack(alignment: .leading) {
                        Text("距离")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.distance)
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("时长")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.duration)
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("日期")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.date)
                            .font(.headline)
                    }
                }
            } else {
                // Content for when no workout is found
                HStack {
                    Spacer()
                    Text("无最近活动记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 80)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct RecentActivityCard_Previews: PreviewProvider {
    static var previews: some View {
        RecentActivityCard()
    }
}