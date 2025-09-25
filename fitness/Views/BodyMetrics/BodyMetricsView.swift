import SwiftUI
import SwiftData

struct BodyMetricsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @Query(sort: \HealthMetric.date, order: .reverse) private var records: [HealthMetric]

    // MARK: - Computed Properties
    private var currentWeight: Double {
        records.first(where: { $0.type == .weight })?.value ?? 0
    }

    private var bmi: Double {
        let userHeight: Double = profileViewModel.userProfile.height
        guard userHeight > 0, currentWeight > 0 else {
            return 0
        }
        let heightInMeters: Double = userHeight / 100.0
        let heightSquared: Double = heightInMeters * heightInMeters
        if heightSquared == 0 {
            return 0
        }
        let result: Double = currentWeight / heightSquared
        return result
    }
    
    private var currentBodyFat: Double {
        records.first(where: { $0.type == .bodyFatPercentage })?.value ?? 0
    }
    
    private var currentWaistCircumference: Double {
        records.first(where: { $0.type == .waistCircumference })?.value ?? 0
    }
    
    // Placeholder data for demonstration
    let muscleMass: Double = 45.1

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Metrics Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("当前指标")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        MetricCard(title: "体重", value: String(format: "%.1f", currentWeight), unit: "公斤", icon: "scalemass.fill", color: .blue)
                        MetricCard(title: "BMI", value: String(format: "%.1f", bmi), unit: "", icon: "figure.walk", color: .green)
                    }

                    // Other Metrics Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("其他指标")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        MetricCard(title: "体脂率", value: String(format: "%.1f", currentBodyFat), unit: "%", icon: "percentage", color: .orange)
                        MetricCard(title: "腰围", value: String(format: "%.1f", currentWaistCircumference), unit: "cm", icon: "figure.and.child.holdinghands", color: .red) // Using a temporary icon
                        MetricCard(title: "肌肉量", value: String(format: "%.1f", muscleMass), unit: "公斤", icon: "figure.strengthtraining.traditional", color: .purple)
                    }

                    // Body Composition Chart Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("体型分析")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        BodyCompositionChart(bmi: bmi, bodyFat: currentBodyFat)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("身体指标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .presentationCornerRadius(32)
    }
}


// MARK: - Helper Views

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                HStack(alignment: .lastTextBaseline) {
                    Text(value)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text(unit)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
}



enum BodyCompositionZone: String, CaseIterable, Identifiable {
    case underweight = "体重过轻"
    case healthyLowFat = "健康低脂"
    case healthyNormalFat = "健康中脂"
    case healthyHighFat = "健康高脂"
    case overweight = "超重"
    case obese = "肥胖"

    var id: String { self.rawValue }

    var color: Color {
        switch self {
        case .underweight: return .orange.opacity(0.6)
        case .healthyLowFat: return .green.opacity(0.6)
        case .healthyNormalFat: return .green.opacity(0.8)
        case .healthyHighFat: return .yellow.opacity(0.6)
        case .overweight: return .orange.opacity(0.8)
        case .obese: return .red.opacity(0.8)
        }
    }
}

struct BodyCompositionChart: View {
    let bmi: Double
    let bodyFat: Double

    // Define chart ranges and divisions
    let bmiMin: Double = 15.0
    let bmiMax: Double = 40.0
    let bodyFatMin: Double = 5.0
    let bodyFatMax: Double = 35.0

    var body: some View {
        GeometryReader {
            geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            // Calculate normalized positions for BMI and Body Fat
            let normalizedBmi = (bmi - bmiMin) / (bmiMax - bmiMin)
            let normalizedBodyFat = (bodyFat - bodyFatMin) / (bodyFatMax - bodyFatMin)

            // Map normalized positions to view coordinates
            let xPos = normalizedBmi * width
            let yPos = (1.0 - normalizedBodyFat) * height // Y-axis is inverted in SwiftUI

            ZStack {
                // Draw Grid Lines
                Path {
                    path in
                    // Vertical lines (BMI)
                    for i in 1..<Int(bmiMax - bmiMin) / 5 {
                        let x = CGFloat(i) * (width / (bmiMax - bmiMin)) * 5
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    // Horizontal lines (Body Fat)
                    for i in 1..<Int(bodyFatMax - bodyFatMin) / 5 {
                        let y = CGFloat(i) * (height / (bodyFatMax - bodyFatMin)) * 5
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)

                // Draw Zones and Labels
                ForEach(BodyCompositionZone.allCases) { zone in
                    let rect = rectForZone(zone: zone, width: width, height: height)
                    Path {
                        path in
                        path.addRect(rect)
                    }
                    .fill(zone.color)

                    Text(zone.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .position(x: rect.midX, y: rect.midY)
                }

                // Draw User's Point
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 15, height: 15)
                    .position(x: xPos, y: yPos)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 15, height: 15)
                            .position(x: xPos, y: yPos)
                    )

                // Display BMI and Body Fat values near the point
                VStack(spacing: 2) {
                    Text("BMI: \(bmi, specifier: "%.1f")")
                    Text("体脂: \(bodyFat, specifier: "%.1f")%")
                }
                .font(.caption2)
                .padding(4)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(5)
                .position(x: xPos + 40, y: yPos - 20) // Offset from the point

                // BMI Axis Label
                Text("BMI")
                    .font(.caption2)
                    .position(x: 20, y: height + 10) // Near origin

                // BMI Axis Numerical Labels
                ForEach(Array(stride(from: Int(bmiMin), through: Int(bmiMax), by: 5)), id: \.self) {
                    value in
                    let normalizedValue = (Double(value) - bmiMin) / (bmiMax - bmiMin)
                    let x = normalizedValue * width
                    Text("\(value)")
                        .font(.caption2)
                        .position(x: x, y: height + 20)
                }

                // Body Fat Axis Label
                Text("体脂率")
                    .font(.caption2)
                    .rotationEffect(.degrees(-90))
                    .position(x: -10, y: 20) // Near origin

                // Body Fat Axis Numerical Labels
                ForEach(Array(stride(from: Int(bodyFatMin), through: Int(bodyFatMax), by: 5)), id: \.self) {
                    value in
                    let normalizedValue = (Double(value) - bodyFatMin) / (bodyFatMax - bodyFatMin)
                    let y = (1.0 - normalizedValue) * height
                    Text("\(value)%")
                        .font(.caption2)
                        .position(x: -25, y: y)
                }

                // Draw Axis Lines
                Path {
                    path in
                    // X-axis
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: width, y: height))
                    // Y-axis
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: height))
                }
                .stroke(Color.primary, lineWidth: 1)
            }
        }
        .frame(height: 200) // Fixed height for the chart
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
        .padding()
    }

    // Helper function to get rectangle for each zone
    func rectForZone(zone: BodyCompositionZone, width: CGFloat, height: CGFloat) -> CGRect {
        var xMinNormalized: CGFloat = 0
        var xMaxNormalized: CGFloat = 1
        var yMinNormalized: CGFloat = 0 // Corresponds to lowest body fat (bottom of chart)
        var yMaxNormalized: CGFloat = 1 // Corresponds to highest body fat (top of chart)

        // Define BMI ranges
        let bmiUnderweightThreshold = 18.5
        let bmiNormalThreshold = 25.0
        let bmiOverweightThreshold = 30.0

        // Define Body Fat ranges (simplified for example)
        let bfLow = 15.0 // Example for lean
        let bfNormal = 25.0 // Example for normal
        let bfHigh = 35.0 // Example for high

        switch zone {
        case .underweight:
            xMaxNormalized = (bmiUnderweightThreshold - bmiMin) / (bmiMax - bmiMin)
            // yMinNormalized and yMaxNormalized remain 0 and 1 to cover full height
        case .healthyLowFat:
            xMinNormalized = (bmiUnderweightThreshold - bmiMin) / (bmiMax - bmiMin)
            xMaxNormalized = (bmiNormalThreshold - bmiMin) / (bmiMax - bmiMin)
            yMaxNormalized = (bfLow - bodyFatMin) / (bodyFatMax - bodyFatMin) // Top of this zone
        case .healthyNormalFat:
            xMinNormalized = (bmiUnderweightThreshold - bmiMin) / (bmiMax - bmiMin)
            xMaxNormalized = (bmiNormalThreshold - bmiMin) / (bmiMax - bmiMin)
            yMinNormalized = (bfLow - bodyFatMin) / (bodyFatMax - bodyFatMin) // Bottom of this zone
            yMaxNormalized = (bfNormal - bodyFatMin) / (bodyFatMax - bodyFatMin) // Top of this zone
        case .healthyHighFat:
            xMinNormalized = (bmiUnderweightThreshold - bmiMin) / (bmiMax - bmiMin)
            xMaxNormalized = (bmiNormalThreshold - bmiMin) / (bmiMax - bmiMin)
            yMinNormalized = (bfNormal - bodyFatMin) / (bodyFatMax - bodyFatMin) // Bottom of this zone
            yMaxNormalized = (bfHigh - bodyFatMin) / (bodyFatMax - bodyFatMin) // Top of this zone
        case .overweight:
            xMinNormalized = (bmiNormalThreshold - bmiMin) / (bmiMax - bmiMin)
            xMaxNormalized = (bmiOverweightThreshold - bmiMin) / (bmiMax - bmiMin)
            // yMinNormalized and yMaxNormalized remain 0 and 1 to cover full height
        case .obese:
            xMinNormalized = (bmiOverweightThreshold - bmiMin) / (bmiMax - bmiMin)
            // yMinNormalized and yMaxNormalized remain 0 and 1 to cover full height
        }

        // Convert normalized coordinates to SwiftUI screen coordinates
        let x = xMinNormalized * width
        let y = (1.0 - yMaxNormalized) * height // Top of the rectangle in SwiftUI coords
        let rectWidth = (xMaxNormalized - xMinNormalized) * width
        let rectHeight = (yMaxNormalized - yMinNormalized) * height

        return CGRect(x: x, y: y, width: rectWidth, height: rectHeight)
    }
}

struct BodyMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)
        
        BodyMetricsView()
            .modelContainer(container)
            .environmentObject(ProfileViewModel())
    }
}