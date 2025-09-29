import SwiftUI

struct StepBarChart: View {
    let data: [DailyStepData] // 每日步数数据
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 5) {
                // 找到最大步数，用于归一化
                let maxSteps = data.map { $0.steps }.max() ?? 1.0
                
                ForEach(data) { dayData in
                    VStack {
                        // 柱子
                        RoundedRectangle(cornerRadius: 4)
                            .fill(dayData.steps > 0 ? Color.green.opacity(0.7) : Color.gray.opacity(0.3))
                            .frame(height: dayData.steps > 0 ? (dayData.steps / maxSteps) * geometry.size.height : 5)
                    }
                }
            }
        }
//        .frame(height: 100) // 固定图表高度
    }
}

// 假设 Date 扩展，用于获取短周几名称
extension Date {
    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE" // 例如 "Mon", "Tue"
        return formatter.string(from: self)
    }
}
