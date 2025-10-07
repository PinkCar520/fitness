import SwiftUI

struct DayDetailCardView: View {
    let date: Date
    var motivationalTip: String? // New parameter

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("详情卡片")
                .font(.headline)
            Text("选择日期: \(date.formatted(date: .long, time: .omitted))")
                .font(.subheadline)
            Text("这里将显示该日期的详细活动、计划和提示。")
                .font(.caption)
                .foregroundColor(.gray)

            if let tip = motivationalTip {
                Text(tip)
                    .font(.caption)
                    .foregroundColor(.orange) // Use a distinct color for tips
                    .padding(.top, 5)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct DayDetailCardView_Previews: PreviewProvider {
    static var previews: some View {
        DayDetailCardView(date: Date(), motivationalTip: "今天也要加油哦！")
            .previewLayout(.sizeThatFits)
    }
}