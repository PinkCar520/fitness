import WidgetKit
import SwiftUI
// Import shared insights types
import Foundation

struct InsightsProvider: TimelineProvider {
    func placeholder(in context: Context) -> InsightsEntry {
        InsightsEntry(date: Date(), items: sampleItems)
    }

    func getSnapshot(in context: Context, completion: @escaping (InsightsEntry) -> ()) {
        let entry = InsightsEntry(date: Date(), items: sampleItems)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InsightsEntry>) -> ()) {
        let insightsStore = InsightsSnapshotStore(appGroup: AppGroup.suiteName)
        var items: [InsightItem] = insightsStore.read()?.items ?? sampleItems

        // Merge Weekly Summary insight from snapshot if available
        let weeklyStore = WeeklySummarySnapshotStore(appGroup: AppGroup.suiteName)
        if let weekly = weeklyStore.load() {
            if let weeklyInsight = mapWeeklySummaryToInsight(weekly) {
                // Insert at top to highlight weekly status
                items.insert(weeklyInsight, at: 0)
            }
        }
        let entry = InsightsEntry(date: Date(), items: items)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60*60)))
        completion(timeline)
    }

    private var sampleItems: [InsightItem] {
        [
            InsightItem(title: "制定专属计划", message: "系统可生成个性化安排", tone: .informational, intent: .openPlan),
            InsightItem(title: "今日训练待完成", message: "完成今日计划巩固习惯", tone: .warning, intent: .startWorkout)
        ]
    }
}

// MARK: - Weekly Summary -> Insight mapping
private func mapWeeklySummaryToInsight(_ s: WeeklySummarySnapshot) -> InsightItem? {
    // Simple rules aligned to previous PlanViewModel logic
    if s.completionRate >= 0.8 {
        return InsightItem(
            title: "优秀的完成率",
            message: "本周完成率达到 \(Int(s.completionRate * 100))%，继续保持势头！",
            tone: .positive,
            intent: .none
        )
    } else if s.pendingDays > 0 {
        return InsightItem(
            title: "还有待完成的任务",
            message: "本周还有 \(s.pendingDays) 天训练未完成，挑一项开始动起来吧。",
            tone: .warning,
            intent: .startWorkout
        )
    }
    return nil
}

struct InsightsEntry: TimelineEntry {
    let date: Date
    let items: [InsightItem]
}

struct InsightsWidgetEntryView: View {
    var entry: InsightsProvider.Entry

    var body: some View {
        // Single-card, full-bleed background to avoid any outer shell
        let item: InsightItem = entry.items.first ?? InsightItem(
            title: "制定专属计划",
            message: "系统可生成个性化安排",
            tone: .informational,
            intent: .openPlan
        )

        ZStack {
            // iOS 17+: remove system shell, make container background our gradient with rounded corners
            Color.clear
                .containerBackground(for: .widget) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(gradient(for: item.tone))
                }
            Link(destination: URL(string: deepLink(for: item.intent))!) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: icon(for: item.intent, tone: item.tone, preferToneIcon: true))
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                        Text(item.title)
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Text(item.message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        Image(systemName: actionIcon(for: item.intent))
                            .font(.caption.weight(.bold))
                        Text(actionTitle(for: item.intent))
                            .font(.caption.weight(.bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundColor(.white)
                    .background(Color.white.opacity(0.2), in: Capsule())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
            }
        }
    }

    // MARK: - Card UI (matching in-app InsightCard)
    @ViewBuilder
    private func insightCard(_ item: InsightItem) -> some View {
        let gradient = gradient(for: item.tone)
        Link(destination: URL(string: deepLink(for: item.intent))!) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: icon(for: item.intent, tone: item.tone, preferToneIcon: true))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    Text(item.title)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                Text(item.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)

                // Action pill is visual only in Widget; entire card is tappable via Link
                HStack(spacing: 8) {
                    Image(systemName: actionIcon(for: item.intent))
                        .font(.caption.weight(.bold))
                    Text(actionTitle(for: item.intent))
                        .font(.caption.weight(.bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(.white)
                .background(Color.white.opacity(0.2), in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(gradient)
            )
        }
        // Avoid double tap target shell: per-card Link only
    }

    private func gradient(for tone: InsightItem.Tone) -> LinearGradient {
        switch tone {
        case .informational:
            return LinearGradient(
                colors: [Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .positive:
            return LinearGradient(
                colors: [Color.green.opacity(0.9), Color.green.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .warning:
            return LinearGradient(
                colors: [Color.orange.opacity(0.9), Color.orange.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func deepLink(for intent: InsightItem.Intent) -> String {
        switch intent {
        case .startWorkout: return "fitness://start-workout"
        case .logWeight: return "fitness://add-weight"
        case .reviewMeals: return "fitness://plan"
        case .openPlan: return "fitness://plan"
        case .openBodyProfileWeight: return "fitness://body-profile/weight"
        case .openStats: return "fitness://stats"
        case .none: return "fitness://home"
        }
    }

    private func icon(for intent: InsightItem.Intent, tone: InsightItem.Tone, preferToneIcon: Bool = false) -> String {
        if preferToneIcon {
            switch tone {
            case .informational: return "sparkles"
            case .positive: return "trophy.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
        switch intent {
        case .startWorkout: return "play.fill"
        case .logWeight: return "scalemass.fill"
        case .reviewMeals: return "fork.knife"
        case .openPlan: return "calendar.badge.clock"
        case .openBodyProfileWeight: return "chart.xyaxis.line"
        case .openStats: return "chart.pie"
        case .none:
            switch tone { case .warning: return "exclamationmark.triangle.fill"; case .positive: return "checkmark.circle.fill"; case .informational: return "info.circle.fill" }
        }
    }

    private func actionIcon(for intent: InsightItem.Intent) -> String {
        switch intent {
        case .startWorkout: return "play.fill"
        case .logWeight: return "scalemass.fill"
        case .reviewMeals: return "fork.knife"
        case .openPlan: return "calendar.badge.clock"
        case .openBodyProfileWeight: return "chart.xyaxis.line"
        case .openStats: return "chart.pie"
        case .none: return "chevron.right"
        }
    }

    private func actionTitle(for intent: InsightItem.Intent) -> String {
        switch intent {
        case .startWorkout: return "开始训练"
        case .logWeight: return "记录体重"
        case .reviewMeals: return "记录饮食"
        case .openPlan: return "查看计划"
        case .openBodyProfileWeight: return "查看体重"
        case .openStats: return "查看统计"
        case .none: return "查看详情"
        }
    }
}

struct InsightsWidget: Widget {
    let kind = "InsightsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InsightsProvider()) { entry in
            InsightsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("洞察小组件")
        .description("显示训练与体重洞察")
        .supportedFamilies([.systemMedium])
    }
}
