import SwiftUI
import SwiftData

enum ChartableMetric: String, CaseIterable, Identifiable {
    case weight = "体重"
    case bodyFat = "体脂率"

    var id: String { self.rawValue }
}

struct BodyProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Query(sort: \HealthMetric.date, order: .reverse) private var metrics: [HealthMetric]
    
    @State private var showInputSheet = false
    @State private var selectedChartMetric: ChartableMetric = .weight

    // Computed properties to get latest values
    private var latestWeight: Double {
        metrics.first(where: { $0.type == .weight })?.value ?? 0
    }
    private var latestBodyFat: Double {
        metrics.first(where: { $0.type == .bodyFatPercentage })?.value ?? 0
    }
    private var bmi: Double {
        let height = profileViewModel.userProfile.height / 100 // in meters
        guard height > 0, latestWeight > 0 else { return 0 }
        return latestWeight / (height * height)
    }

    // Computed property to prepare data for the chart based on selection
    private var chartData: [DateValuePoint] {
        let selectedType: MetricType = (selectedChartMetric == .weight) ? .weight : .bodyFatPercentage
        return metrics
            .filter { $0.type == selectedType }
            .map { DateValuePoint(date: $0.date, value: $0.value) }
            .sorted(by: { $0.date < $1.date })
    }
    
    private var chartTitle: String {
        "\(selectedChartMetric.rawValue)趋势"
    }
    
    private var chartColor: Color {
        selectedChartMetric == .weight ? .blue : .orange
    }
    
    private var chartUnit: String {
        selectedChartMetric == .weight ? "kg" : "%"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Dashboard Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("当前指标")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            MetricCard(title: "体重", value: String(format: "%.1f", latestWeight), unit: "公斤", icon: "scalemass.fill", color: .blue)
                            MetricCard(title: "BMI", value: String(format: "%.1f", bmi), unit: "", icon: "figure.walk", color: .green)
                            MetricCard(title: "体脂率", value: String(format: "%.1f", latestBodyFat), unit: "%", icon: "flame.fill", color: .orange)
                        }
                        .padding(.horizontal)
                    }

                    // Chart Section
                    VStack {
                        Picker("Select Metric", selection: $selectedChartMetric) {
                            ForEach(ChartableMetric.allCases) { metric in
                                Text(metric.rawValue).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        GenericLineChartView(
                            title: chartTitle,
                            data: chartData,
                            color: chartColor,
                            unit: chartUnit
                        )
                    }

                    // Visual Records Placeholder Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("视觉记录")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        VStack(alignment: .center) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 5)
                            Text("记录你的蜕变，见证每一次进步")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("点击添加照片 (即将推出)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 80) // Spacer to ensure content is above the FAB
                }
                .padding(.vertical)
            }

            // Floating Action Button
            Button(action: { showInputSheet = true }) {
                Image(systemName: "plus")
                    .font(.title.weight(.semibold))
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(radius: 10)
            }
            .padding()
        }
        .sheet(isPresented: $showInputSheet) {
            InputSheetView()
        }
    }
}

struct BodyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)
        
        // Add sample data for preview
        let sampleData = [
            HealthMetric(date: Date().addingTimeInterval(-86400*6), value: 70.5, type: .weight),
            HealthMetric(date: Date().addingTimeInterval(-86400*3), value: 70.1, type: .weight),
            HealthMetric(date: Date(), value: 69.5, type: .weight),
            HealthMetric(date: Date(), value: 22.5, type: .bodyFatPercentage)
        ]
        sampleData.forEach { container.mainContext.insert($0) }

        return BodyProfileView()
            .modelContainer(container)
            .environmentObject(ProfileViewModel())
    }
}
