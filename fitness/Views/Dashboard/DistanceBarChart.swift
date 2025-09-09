import SwiftUI

struct DistanceBarChart: View {
    let data: [DailyDistanceData] // 每日距离数据
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 5) {
                // 找到最大距离，用于归一化
                let maxDistance = data.map { $0.distance }.max() ?? 1.0
                
                ForEach(data) { dayData in
                    VStack {
                        // 柱子
                        RoundedRectangle(cornerRadius: 4)
                            .fill(dayData.distance > 0 ? Color.cyan.opacity(0.7) : Color.gray.opacity(0.3))
                            .frame(height: dayData.distance > 0 ? (dayData.distance / maxDistance) * geometry.size.height : 5)
                    }
                }
            }
        }
//        .frame(height: 100) // 固定图表高度
    }
}
