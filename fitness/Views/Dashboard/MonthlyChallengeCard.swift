
import SwiftUI

struct MonthlyChallengeCard: View {
    private let daysInMonth = 30
    private let completedDays = 12
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("每月挑战")
                    .font(.headline)
                Spacer()
                Image(systemName: "rosette")
                    .foregroundStyle(.yellow)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<daysInMonth, id: \.self) { day in
                    Circle()
                        .fill(day < completedDays ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(completedDays)/\(daysInMonth)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(completedDays), total: Double(daysInMonth))
                    .progressViewStyle(.linear)
                    .tint(.green)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct MonthlyChallengeCard_Previews: PreviewProvider {
    static var previews: some View {
        MonthlyChallengeCard()
    }
}
