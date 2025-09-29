import SwiftUI

struct MonthlyChallengeCard: View {
    let monthlyChallengeCompletion: [Int: Bool] // New property

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }

    private var numberOfDaysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
    }

    private var completedDays: Int {
        monthlyChallengeCompletion.filter { $0.value }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(monthName) 挑战")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "rosette")
                    .foregroundStyle(.yellow)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...numberOfDaysInMonth, id: \.self) { day in
                    // Check if the day is in the completion status dictionary
                    if let isCompleted = monthlyChallengeCompletion[day] {
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .frame(width: 16, height: 16)
                        } else {
                            // Day has passed but was not completed
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 16, height: 16)
                        }
                    } else {
                        // Day is in the future or data is not yet loaded
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 16, height: 16)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text("\(completedDays)")
                        .contentTransition(.numericText(countsDown: false))
                    Text("/\(numberOfDaysInMonth)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                ProgressView(value: Double(completedDays), total: Double(numberOfDaysInMonth))
                    .progressViewStyle(.linear)
                    .tint(.green)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .animation(.easeInOut, value: completedDays)
    }
}

struct MonthlyChallengeCard_Previews: PreviewProvider {
    static var previews: some View {
        let mockCompletion: [Int: Bool] = [
            1: true, 2: true, 3: false, 4: true, 5: false, 6: true, 7: true,
            8: true, 9: false, 10: true, 11: true, 12: false, 13: true, 14: true,
            15: false, 16: true, 17: true, 18: false, 19: true, 20: true, 21: false,
            22: true, 23: true, 24: false, 25: true, 26: true, 27: false, 28: true,
            29: false, 30: true
        ]
        MonthlyChallengeCard(monthlyChallengeCompletion: mockCompletion)
    }
}
