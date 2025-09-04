
import SwiftUI

struct FitnessRingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("健身圆环")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    Circle()
                        .trim(from: 0, to: 0.64)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack {
                        Text("64%")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("已完成")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    Text("活动")
                        .font(.headline)
                    Text("320 / 500")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("千卡")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct FitnessRingCard_Previews: PreviewProvider {
    static var previews: some View {
        FitnessRingCard()
    }
}
