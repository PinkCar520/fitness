import SwiftUI

// Note: Widget 目标仅使用 Model 构造器。
// 为避免 Widget 解析到 App 专有类型，下面的 init(summary:) 用条件编译仅在非 WidgetKit 环境提供。
struct WeeklySummaryCard: View {
    struct Model: Equatable {
        let completionRate: Double
        let completedDays: Int
        let pendingDays: Int
        let skippedDays: Int
        let streakDays: Int
        let totalDays: Int
    }

    let model: Model
    var background: Bool = true

    // Intentionally no init(summary:) to avoid cross-target type exposure.

    init(model: Model) {
        self.model = model
    }

    var body: some View {
        container {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.accentColor)
                    Text("本周摘要")
                        .font(.headline.weight(.bold))
//                    Spacer()
                    Text("\(Int(model.completionRate * 100))%")
                        .font(.title3.weight(.heavy))
                        .foregroundColor(.accentColor)
                }

                ProgressView(value: model.completionRate)
                    .progressViewStyle(.linear)

                HStack(spacing: 12) {
                    InfoChip(icon: "checkmark.circle.fill", text: "已完成 \(model.completedDays)", tint: .accentColor, backgroundColor: Color.accentColor.opacity(0.15))
                    if model.pendingDays > 0 {
                        InfoChip(icon: "hourglass", text: "待完成 \(model.pendingDays)", tint: .orange, backgroundColor: Color.orange.opacity(0.15))
                    }
                    if model.skippedDays > 0 {
                        InfoChip(icon: "arrow.uturn.left", text: "跳过 \(model.skippedDays)", tint: .pink, backgroundColor: Color.pink.opacity(0.15))
                    }
                }

                Text("连续完成 \(model.streakDays) 天 · 本周共 \(model.totalDays) 日安排")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func container<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if background {
            DashboardSurface { content() }
        } else {
            // Widget 渲染：不加任何卡片背景，由系统容器负责
            content()
        }
    }
}

extension WeeklySummaryCard {
    // Widget专用：只渲染内容，不包含任何背景容器或外层壳
    static func widgetBody(model: Model) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "calendar")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.accentColor)
                Text("本周摘要")
                    .font(.headline.weight(.bold))
                Text("\(Int(model.completionRate * 100))%")
                    .font(.title3.weight(.heavy))
                    .foregroundColor(.accentColor)
            }

            ProgressView(value: model.completionRate)
                .progressViewStyle(.linear)

            HStack(spacing: 12) {
                InfoChip(icon: "checkmark.circle.fill", text: "已完成 \(model.completedDays)", tint: .accentColor, backgroundColor: Color.accentColor.opacity(0.15))
                if model.pendingDays > 0 {
                    InfoChip(icon: "hourglass", text: "待完成 \(model.pendingDays)", tint: .orange, backgroundColor: Color.orange.opacity(0.15))
                }
                if model.skippedDays > 0 {
                    InfoChip(icon: "arrow.uturn.left", text: "跳过 \(model.skippedDays)", tint: .pink, backgroundColor: Color.pink.opacity(0.15))
                }
            }

            Text("连续完成 \(model.streakDays) 天 · 本周共 \(model.totalDays) 日安排")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
