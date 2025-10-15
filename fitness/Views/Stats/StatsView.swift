import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    // Time Frame Selection
    enum TimeFrame: String, CaseIterable, Identifiable {
        case sevenDays = "周"
        case thirtyDays = "月"
        case ninetyDays = "季"
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            }
        }
    }
    @State private var selectedTimeFrame: TimeFrame = .thirtyDays

    // Environment & Data Sources
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    // State for fetched data
    @State private var totalCalories: Double = 0
    @State private var workoutDays: Int = 0

    // Computed property for workout frequency chart
    private var workoutFrequencyData: [WeeklyWorkoutActivity] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -selectedTimeFrame.days, to: endDate) else {
            return []
        }

        let relevantWorkouts = workouts.filter { $0.date >= startDate && $0.date <= endDate }
        
        // Group by week start date
        let groupedByWeek = Dictionary(grouping: relevantWorkouts) { workout -> Date in
            calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.date))!
        }

        return groupedByWeek.map { (weekStartDate, workoutsInWeek) -> WeeklyWorkoutActivity in
            return WeeklyWorkoutActivity(weekOf: weekStartDate, count: workoutsInWeek.count)
        }.sorted(by: { $0.weekOf < $1.weekOf })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Time Frame Picker
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases) { timeFrame in
                            Text(timeFrame.rawValue).tag(timeFrame)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Core Metrics Grid
                    VStack(alignment: .leading) {
                        Text("核心指标")
                            .font(.title3).bold()
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            MetricCard(title: "运动天数", value: "\(workoutDays)", unit: "天", icon: "figure.walk", color: .orange)
                            MetricCard(title: "总消耗", value: String(format: "%.0f", totalCalories), unit: "千卡", icon: "flame.fill", color: .red)
                        }
                    }

                    // Workout Frequency Chart
                    WorkoutFrequencyChartView(data: workoutFrequencyData)

                }
                .padding()
            }
            .navigationTitle("统计")
            .onAppear(perform: fetchData)
            .onChange(of: selectedTimeFrame) { 
                fetchData()
            }
        }
    }

    private func fetchData() {
        healthKitManager.fetchTotalActiveEnergy(for: selectedTimeFrame.days) { calories in
            self.totalCalories = calories
        }
        healthKitManager.fetchWorkoutDays(for: selectedTimeFrame.days) { days in
            self.workoutDays = days
        }
    }
}


// Bar chart view for workout frequency
struct WorkoutFrequencyChartView: View {
    let data: [WeeklyWorkoutActivity]

    var body: some View {
        VStack(alignment: .leading) {
            Text("每周锻炼频率")
                .font(.title3).bold()
            
            Chart(data) { item in
                BarMark(
                    x: .value("Week", item.weekOf, unit: .weekOfYear),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Color.green.gradient)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.week(.defaultDigits))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Workout.self, configurations: config)
        
        // Add sample workout data
        for i in 0..<90 {
            if i % 3 == 0 { // Add a workout every 3 days
                let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                let workout = Workout(name: "Sample Workout", durationInMinutes: 30, caloriesBurned: 200, date: date)
                container.mainContext.insert(workout)
            }
        }

        return StatsView()
            .modelContainer(container)
            .environmentObject(HealthKitManager())
    }
}