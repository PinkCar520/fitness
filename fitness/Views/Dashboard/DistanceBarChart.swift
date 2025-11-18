import SwiftUI

struct DistanceBarChart: View {
    let data: [DailyDistanceData] // 每日距离数据（单位米）

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 5) {
                let maxDistance = data.map { $0.distance }.max() ?? 1.0
                ForEach(data) { dayData in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(dayData.distance > 0 ? Color.cyan.opacity(0.7) : Color.gray.opacity(0.3))
                        .frame(height: dayData.distance > 0 ? (dayData.distance / maxDistance) * geometry.size.height : 5)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9)), removal: .opacity))
                }
            }
        }
        // 为数据变化添加平滑动画（高度/颜色/插入移除）
        .animation(.easeInOut(duration: 0.28), value: data)
    }
}
