import SwiftUI
import SwiftData

struct GoalProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthMetric.date) private var records: [HealthMetric] // Sort ascending to easily get first record
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private var targetWeight: Double {
        profileViewModel.userProfile.targetWeight
    }

    private var currentWeight: Double {
        records.last?.value ?? 0.0
    }

    private var startingWeight: Double {
        records.first?.value ?? 0.0
    }

    private var progress: Double {
        guard startingWeight != targetWeight else { return 0.0 }
        let totalRange = startingWeight - targetWeight
        let currentProgress = startingWeight - currentWeight
        return currentProgress / totalRange
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("目标进度")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 5)

            ZStack {
                // Background semicircle
                SemicircleShape()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    .frame(height: 150)

                // Progress semicircle
                SemicircleShape(progress: progress)
                    .stroke(currentWeight > targetWeight ? Color.orange : Color.green, lineWidth: 10)
                    .frame(height: 150)

                // Current Weight in the middle
                VStack {
                    Text(String(format: "%.1f", currentWeight))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("KG")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .offset(y: -30) // Adjust position to be central in the semicircle

                // Starting Weight (bottom-left)
                Text(String(format: "%.1f KG", startingWeight))
                    .font(.caption)
                    .offset(x: -70, y: 60) // Adjust position

                // Target Weight (bottom-right)
                Text(String(format: "%.1f KG", targetWeight))
                    .font(.caption)
                    .offset(x: 70, y: 60) // Adjust position
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct SemicircleShape: Shape {
    var progress: Double = 1.0 // 0.0 to 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2
        let startAngle = Angle(degrees: 180)
        let endAngle = Angle(degrees: 0)

        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
}

struct GoalProgressView_Previews: PreviewProvider {
    static var previews: some View {
        GoalProgressView()
            .modelContainer(for: HealthMetric.self, inMemory: true)
            .environmentObject(ProfileViewModel())
            .frame(width: 350)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
