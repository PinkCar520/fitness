import SwiftUI

struct MonthlyChallengeCard: View {
    @StateObject private var viewModel = MonthlyChallengeViewModel()

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(viewModel.monthName) 挑战")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "rosette")
                    .foregroundStyle(.yellow)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...viewModel.numberOfDaysInMonth, id: \.self) { day in
                    // Check if the day is in the completion status dictionary
                    if let isCompleted = viewModel.completionStatus[day] {
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
                Text("\(viewModel.completedDays)/\(viewModel.numberOfDaysInMonth)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(viewModel.completedDays), total: Double(viewModel.numberOfDaysInMonth))
                    .progressViewStyle(.linear)
                    .tint(.green)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct MonthlyChallengeCard_Previews: PreviewProvider {
    static var previews: some View {
        MonthlyChallengeCard()
    }
}
