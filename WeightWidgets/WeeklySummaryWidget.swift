import WidgetKit
import SwiftUI

struct WeeklySummaryEntry: TimelineEntry {
    let date: Date
    let snapshot: WeeklySummarySnapshot
}

struct WeeklySummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklySummaryEntry {
        WeeklySummaryEntry(date: Date(), snapshot: .init(
            completionRate: 0.6,
            completedDays: 3,
            pendingDays: 3,
            skippedDays: 1,
            streakDays: 2,
            totalDays: 7,
            updatedAt: Date()
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklySummaryEntry) -> Void) {
        let store = WeeklySummarySnapshotStore(appGroup: "group.com.pineapple.fitness")
        let snap = store.load() ?? placeholder(in: context).snapshot
        completion(WeeklySummaryEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklySummaryEntry>) -> Void) {
        let store = WeeklySummarySnapshotStore(appGroup: "group.com.pineapple.fitness")
        let snap = store.load() ?? placeholder(in: context).snapshot
        let entry = WeeklySummaryEntry(date: Date(), snapshot: snap)
        // Refresh periodically (e.g., hourly)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct WeeklySummaryWidgetView: View {
    var entry: WeeklySummaryProvider.Entry

    var body: some View {
        let model = WeeklySummaryCard.Model(
            completionRate: entry.snapshot.completionRate,
            completedDays: entry.snapshot.completedDays,
            pendingDays: entry.snapshot.pendingDays,
            skippedDays: entry.snapshot.skippedDays,
            streakDays: entry.snapshot.streakDays,
            totalDays: entry.snapshot.totalDays
        )
        ZStack {

            WeeklySummaryCard.widgetBody(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
        }
        .widgetURL(URL(string: "fitness://plan"))
    }
}

struct WeeklySummaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeeklySummaryWidget", provider: WeeklySummaryProvider()) { entry in
            WeeklySummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("本周摘要")
        .description("查看训练计划的本周完成情况")
        .supportedFamilies([.systemMedium])
    }
}
