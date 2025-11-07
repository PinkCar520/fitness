import SwiftUI

struct StepBarChart: View {
    let data: [DailyStepData] // 每日步数数据

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 5) {
                let maxSteps = data.map { $0.steps }.max() ?? 1.0
                ForEach(data) { dayData in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(dayData.steps > 0 ? Color.green.opacity(0.7) : Color.gray.opacity(0.3))
                        .frame(height: dayData.steps > 0 ? (dayData.steps / maxSteps) * geometry.size.height : 5)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9)), removal: .opacity))
                }
            }
        }
        // 为数据变化添加平滑动画（高度/颜色/插入移除）
        .animation(.easeInOut(duration: 0.28), value: data)
    }
}

// 假设 Date 扩展，用于获取短周几名称
// 保持组件纯柱状图，日期标签由调用方自行绘制（如弹窗）
