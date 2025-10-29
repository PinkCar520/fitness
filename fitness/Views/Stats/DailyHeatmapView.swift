import SwiftUI

struct DailyStatus: Identifiable {
    enum State { case completed, skipped, none }
    let id = UUID()
    let date: Date
    let state: State
}

struct DailyHeatmapView: View {
    let days: [DailyStatus]

    private var weeks: [[DailyStatus]] {
        // Group into weeks ending today, from oldest to newest
        let calendar = Calendar.current
        let sorted = days.sorted { $0.date < $1.date }
        var grouped: [[DailyStatus]] = []
        var currentWeek: [DailyStatus] = []
        var currentWeekOfYear: Int?
        for item in sorted {
            let comp = calendar.component(.weekOfYear, from: item.date)
            if currentWeekOfYear == nil || currentWeekOfYear == comp {
                currentWeek.append(item)
                currentWeekOfYear = comp
            } else {
                grouped.append(currentWeek)
                currentWeek = [item]
                currentWeekOfYear = comp
            }
        }
        if !currentWeek.isEmpty { grouped.append(currentWeek) }
        return grouped
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("执行热力图").font(.title3).bold()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 6) {
                    ForEach(weeks.indices, id: \.self) { idx in
                        let week = weeks[idx]
                        VStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { i in
                                let dayStatus = day(at: i, in: week)
                                Circle()
                                    .fill(color(for: dayStatus?.state))
                                    .frame(width: 14, height: 14)
                                    .accessibilityLabel(dayStatus?.date.formatted(date: .abbreviated, time: .omitted) ?? "")
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            HStack(spacing: 12) {
                legendDot(.green); Text("完成").font(.caption)
                legendDot(.orange); Text("跳过").font(.caption)
                legendDot(.gray.opacity(0.3)); Text("无记录").font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func day(at index: Int, in week: [DailyStatus]) -> DailyStatus? {
        // week contains chronological days; align by weekday for nicer grid
        let calendar = Calendar.current
        return week.first { calendar.component(.weekday, from: $0.date) == ((index + 1) % 7) + 1 }
    }

    private func color(for state: DailyStatus.State?) -> Color {
        switch state {
        case .completed?: return .green
        case .skipped?: return .orange
        default: return .gray.opacity(0.3)
        }
    }

    @ViewBuilder private func legendDot(_ color: Color) -> some View {
        Circle().fill(color).frame(width: 8, height: 8)
    }
}

