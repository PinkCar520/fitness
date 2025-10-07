import SwiftUI

struct WeeklyPlanView: View {
    // This will receive the selected date from the parent view
    let selectedDate: Date

    // Helper to get the start and end of the week for the selected date
    private var weekDateInterval: DateInterval? {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return nil
        }
        return weekInterval
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let interval = weekDateInterval {
                Text("本周计划 (\(formattedDate(interval.start)) - \(formattedDate(interval.end)))")
                    .font(.headline)
                    .padding(.horizontal)
            }

            // Placeholder for the actual plan content
            VStack(alignment: .leading, spacing: 12) {
                Text("周一：胸部 & 三头肌")
                Divider()
                Text("周二：背部 & 二头肌")
                Divider()
                Text("周三：休息 & 饮食调整")
                Divider()
                Text("周四：腿部 & 肩部")
                Divider()
                Text("周五：核心 & 有氧")
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

        }
        .padding(.vertical)
    }
}

struct WeeklyPlanView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyPlanView(selectedDate: Date())
            .padding()
    }
}
